import base64
import os
from datetime import datetime, timezone
from hashlib import md5
from uuid import uuid4

from flask import Flask, jsonify, request

try:
    from google import genai
    from google.genai import types as genai_types
except ImportError:
    genai = None
    genai_types = None

try:
    from .breed_baselines import BREED_BASELINES, BREED_BASELINE_BY_ID
    from .db import create_data_store
except ImportError:
    from breed_baselines import BREED_BASELINES, BREED_BASELINE_BY_ID
    from db import create_data_store

app = Flask(__name__)


SERVICE_NAME = "petfashion-backend"
DEFAULT_OWNER_ID = "demo_user"
VERTEX_IMAGE_MODEL = os.environ.get("VERTEX_IMAGE_MODEL", "gemini-2.5-flash-image")
VERTEX_IMAGE_LOCATION = os.environ.get("VERTEX_IMAGE_LOCATION", "global")
VERTEX_PROJECT_ID = (
    os.environ.get("GOOGLE_CLOUD_PROJECT")
    or os.environ.get("GCLOUD_PROJECT")
    or os.environ.get("GCP_PROJECT")
    or "gdgoc-hack"
)
app.config.setdefault("DATA_STORE", create_data_store())


def _utc_now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _find_by_id(items, field_name, item_id):
    return next((item for item in items if item[field_name] == item_id), None)


def _get_store():
    return app.config["DATA_STORE"]


def _json_error(status_code, message, field=None):
    payload = {"ok": False, "error": message}
    if field is not None:
        payload["field"] = field
    return jsonify(payload), status_code


def _not_found(message):
    return _json_error(404, message)


def _parse_float(payload, *keys):
    for key in keys:
        value = payload.get(key)
        if value in (None, ""):
            continue
        try:
            return float(value)
        except (TypeError, ValueError):
            raise ValueError(key)
    return None


def _normalize_text(value, default=""):
    if value is None:
        return default
    text = str(value).strip()
    return text or default


def _normalize_text_list(value):
    if value is None:
        return []
    if isinstance(value, str):
        candidates = value.split(",")
    elif isinstance(value, list):
        candidates = value
    else:
        return []
    items = []
    for candidate in candidates:
        text = str(candidate).strip()
        if text and text not in items:
            items.append(text)
    return items


def _normalize_breed_lookup(breed_name):
    return _normalize_text(breed_name).casefold()


def _match_breed_by_name(breed_name):
    lookup = _normalize_breed_lookup(breed_name)
    if not lookup:
        return None
    return next(
        (
            item
            for item in BREED_BASELINES
            if item["displayName"].casefold() == lookup or item["id"].casefold() == lookup
        ),
        None,
    )


def _infer_body_size(weight, baseline):
    reference_weight = weight
    if reference_weight is None and baseline is not None:
        reference_weight = baseline["weightKg"]
    if reference_weight is None:
        return "medium"
    if reference_weight < 5:
        return "toy"
    if reference_weight < 10:
        return "small"
    if reference_weight < 25:
        return "medium"
    if reference_weight < 40:
        return "large"
    return "x-large"


def _infer_style_tags(body_size, fur_color):
    tags = ["casual"]
    if body_size in {"toy", "small"}:
        tags.append("cute")
    elif body_size in {"large", "x-large"}:
        tags.append("outdoor")
    else:
        tags.append("daywear")

    fur_text = _normalize_text(fur_color).casefold()
    if any(keyword in fur_text for keyword in ("white", "cream", "gold")):
        tags.append("pastel-match")
    elif any(keyword in fur_text for keyword in ("black", "gray", "charcoal")):
        tags.append("monotone")
    else:
        tags.append("color-pop")
    return tags


def _serialize_pet(item):
    return {
        **item,
        "neckGirth": item.get("neckGirthCm"),
        "chestGirth": item.get("chestGirthCm"),
        "backLength": item.get("backLengthCm"),
    }


def _serialize_closet_item(item):
    return {
        **item,
        "itemId": item["clothingId"],
    }


def _serialize_saved_look(item, store):
    closet_items = []
    for clothing_id in item.get("clothingIds", []):
        closet_item = store.get_closet_item(clothing_id)
        if closet_item is not None:
            closet_items.append(_serialize_closet_item(closet_item))
    return {
        **item,
        "items": closet_items,
        "itemCount": len(item.get("clothingIds", [])),
    }


def _extract_pet_payload(payload):
    try:
        weight = _parse_float(payload, "weight", "weightKg")
        neck_girth = _parse_float(payload, "neckGirthCm", "neckGirth")
        chest_girth = _parse_float(payload, "chestGirthCm", "chestGirth")
        back_length = _parse_float(payload, "backLengthCm", "backLength")
    except ValueError as error:
        raise ValueError(f"Invalid numeric field: {error.args[0]}") from error

    breed = _normalize_text(payload.get("breed"))
    image_url = _normalize_text(payload.get("imageUrl") or payload.get("photoPath"))

    return {
        "name": _normalize_text(payload.get("name") or payload.get("petName"), "Dog"),
        "type": _normalize_text(payload.get("type") or payload.get("petType"), "dog"),
        "breed": breed,
        "age": payload.get("age"),
        "weight": weight,
        "gender": payload.get("gender"),
        "furColor": _normalize_text(payload.get("furColor")),
        "imageUrl": image_url or None,
        "sizeNote": _normalize_text(payload.get("sizeNote")),
        "neckGirthCm": neck_girth,
        "chestGirthCm": chest_girth,
        "backLengthCm": back_length,
    }


def _build_tryon_result_image_url(clothing_id):
    return f"https://example.com/tryon-results/{clothing_id or 'preview'}.png"


def _build_virtual_clothing_item(payload, clothing_id):
    name = _normalize_text(payload.get("name") or payload.get("outfitName"))
    if not name:
        return None
    return {
        "clothingId": clothing_id or f"virtual_{uuid4().hex[:8]}",
        "ownerId": DEFAULT_OWNER_ID,
        "name": name,
        "category": _normalize_text(payload.get("category"), "Top"),
        "color": _normalize_text(payload.get("color"), "teal"),
        "size": _normalize_text(payload.get("size"), "M"),
        "brand": _normalize_text(payload.get("brand"), "PetFit"),
        "pattern": _normalize_text(payload.get("pattern"), "solid"),
        "seasonTags": _normalize_text_list(payload.get("seasonTags")) or ["casual"],
        "imageUrl": _normalize_text(payload.get("imageUrl")) or None,
        "sourceUrl": _normalize_text(payload.get("sourceUrl")) or None,
    }


def _color_to_hex(color_name):
    palette = {
        "blue": "#60A5FA",
        "navy": "#1E3A8A",
        "teal": "#14B8A6",
        "cream": "#FDECC8",
        "gray": "#9CA3AF",
        "grey": "#9CA3AF",
        "black": "#1F2937",
        "white": "#F8FAFC",
        "red": "#EF4444",
        "pink": "#F472B6",
        "olive": "#84CC16",
        "yellow": "#FACC15",
        "beige": "#D6C5A4",
        "camel": "#C19A6B",
        "emerald": "#10B981",
        "burgundy": "#7F1D1D",
        "brown": "#8B5E3C",
    }
    normalized = _normalize_text(color_name).casefold()
    return palette.get(normalized, "#14B8A6")


def _accent_hex(primary_hex):
    mapping = {
        "#60A5FA": "#1D4ED8",
        "#1E3A8A": "#93C5FD",
        "#14B8A6": "#0F766E",
        "#FDECC8": "#D97706",
        "#9CA3AF": "#475569",
        "#1F2937": "#E5E7EB",
        "#F8FAFC": "#CBD5E1",
        "#EF4444": "#7F1D1D",
        "#F472B6": "#9D174D",
        "#84CC16": "#3F6212",
        "#FACC15": "#92400E",
        "#D6C5A4": "#8B5E3C",
        "#C19A6B": "#7C2D12",
        "#10B981": "#064E3B",
        "#7F1D1D": "#FCA5A5",
        "#8B5E3C": "#FDE68A",
    }
    return mapping.get(primary_hex, "#0F766E")


def _detect_pattern_style(clothing_item):
    pattern = _normalize_text(clothing_item.get("pattern"), "solid").casefold()
    if pattern in {"solid", "stripe", "check", "dots"}:
        return pattern

    name = _normalize_text(clothing_item.get("name")).casefold()
    category = _normalize_text(clothing_item.get("category")).casefold()
    haystack = f"{name} {category}"
    if "check" in haystack or "plaid" in haystack:
        return "check"
    if "dot" in haystack or "polka" in haystack:
        return "dots"
    if "stripe" in haystack or "striped" in haystack:
        return "stripe"
    return "solid"


def _build_tryon_vertex_prompt(clothing_item, pet):
    color = _normalize_text(clothing_item.get("color"), "green")
    category = _normalize_text(clothing_item.get("category"), "outfit")
    pattern = _detect_pattern_style(clothing_item)
    pet_type = _normalize_text((pet or {}).get("breed"), "dog")

    pattern_phrase = {
        "solid": "solid fabric",
        "stripe": "subtle horizontal stripes",
        "check": "a soft plaid check pattern",
        "dots": "small dotted details",
    }.get(pattern, "solid fabric")

    return (
        "Edit this dog photo. Keep the exact same dog, face, muzzle, ears, eyes, "
        "pose, body proportions, lighting, and background. "
        f"This is a {pet_type}. Replace any visible harness or chest straps with a "
        f"realistic {color.lower()} {category.lower()} made for a dog, using {pattern_phrase}. "
        "Make the garment fit naturally around the neck, chest, and torso as if the dog is really wearing it. "
        "Do not change the dog's expression or add extra accessories. "
        "The final result must be photorealistic and believable."
    )


def _extract_tryon_image(payload):
    image_base64 = _normalize_text(payload.get("imageBase64"))
    if not image_base64:
        return None, None

    image_mime_type = _normalize_text(payload.get("imageMimeType"), "image/png")
    if image_base64.startswith("data:") and "," in image_base64:
        header, image_base64 = image_base64.split(",", 1)
        if ";base64" in header:
            image_mime_type = header[5:].split(";")[0]

    try:
        return base64.b64decode(image_base64), image_mime_type
    except (ValueError, TypeError):
        raise ValueError("imageBase64")


def _generate_vertex_tryon_image(image_bytes, image_mime_type, clothing_item, pet):
    if genai is None or genai_types is None:
        raise RuntimeError("google-genai is not installed")

    client = genai.Client(
        vertexai=True,
        project=VERTEX_PROJECT_ID,
        location=VERTEX_IMAGE_LOCATION,
    )
    prompt = _build_tryon_vertex_prompt(clothing_item, pet)
    response = client.models.generate_content(
        model=VERTEX_IMAGE_MODEL,
        contents=[
            genai_types.Part.from_bytes(data=image_bytes, mime_type=image_mime_type),
            prompt,
        ],
        config=genai_types.GenerateContentConfig(
            response_modalities=[genai_types.Modality.TEXT, genai_types.Modality.IMAGE]
        ),
    )

    for candidate in response.candidates or []:
        content = getattr(candidate, "content", None)
        if content is None:
            continue
        for part in content.parts or []:
            inline_data = getattr(part, "inline_data", None)
            if inline_data is not None and getattr(inline_data, "data", None):
                mime_type = getattr(inline_data, "mime_type", None) or "image/png"
                return base64.b64encode(inline_data.data).decode("ascii"), mime_type

    raise RuntimeError("Vertex AI returned no image data")


def _build_tryon_render_spec(pet, clothing_item):
    category = _normalize_text(clothing_item.get("category"), "Top").casefold()
    size = _normalize_text(clothing_item.get("size"), "M").upper()
    primary_hex = _color_to_hex(clothing_item.get("color"))
    accent_hex = _accent_hex(primary_hex)
    size_tune = {
        "XS": (-0.08, -0.05),
        "S": (-0.04, -0.03),
        "M": (0.0, 0.0),
        "L": (0.04, 0.02),
        "XL": (0.08, 0.04),
    }.get(size, (0.0, 0.0))

    pet_weight = (pet or {}).get("weight")
    if pet_weight is None:
        pet_weight = 12

    body_tune = 0.0
    if pet_weight < 6:
        body_tune = -0.05
    elif pet_weight > 24:
        body_tune = 0.06

    presets = {
        "hoodie": {
            "widthFactor": 0.46,
            "heightFactor": 0.34,
            "centerY": 0.53,
            "neckInset": 0.24,
            "hemCurve": 0.12,
            "sleeveDrop": 0.13,
            "opacity": 0.82,
        },
        "coat": {
            "widthFactor": 0.5,
            "heightFactor": 0.38,
            "centerY": 0.55,
            "neckInset": 0.18,
            "hemCurve": 0.08,
            "sleeveDrop": 0.1,
            "opacity": 0.76,
        },
        "accessories": {
            "widthFactor": 0.32,
            "heightFactor": 0.18,
            "centerY": 0.46,
            "neckInset": 0.34,
            "hemCurve": 0.02,
            "sleeveDrop": 0.04,
            "opacity": 0.78,
        },
        "formal": {
            "widthFactor": 0.44,
            "heightFactor": 0.32,
            "centerY": 0.53,
            "neckInset": 0.22,
            "hemCurve": 0.07,
            "sleeveDrop": 0.11,
            "opacity": 0.8,
        },
        "top": {
            "widthFactor": 0.43,
            "heightFactor": 0.3,
            "centerY": 0.52,
            "neckInset": 0.26,
            "hemCurve": 0.09,
            "sleeveDrop": 0.1,
            "opacity": 0.8,
        },
    }

    preset_key = "top"
    if "hoodie" in category:
        preset_key = "hoodie"
    elif "coat" in category or "outerwear" in category:
        preset_key = "coat"
    elif "access" in category or "harness" in category:
        preset_key = "accessories"
    elif "formal" in category:
        preset_key = "formal"

    preset = presets[preset_key]
    width_factor = max(0.24, min(0.72, preset["widthFactor"] + size_tune[0] + body_tune))
    height_factor = max(
        0.14, min(0.58, preset["heightFactor"] + size_tune[1] + (body_tune * 0.5))
    )

    return {
        "renderer": "overlay-v1",
        "garmentType": preset_key,
        "primaryColor": primary_hex,
        "accentColor": accent_hex,
        "patternStyle": _detect_pattern_style(clothing_item),
        "widthFactor": round(width_factor, 3),
        "heightFactor": round(height_factor, 3),
        "centerX": 0.5,
        "centerY": round(preset["centerY"], 3),
        "neckInset": preset["neckInset"],
        "hemCurve": preset["hemCurve"],
        "sleeveDrop": preset["sleeveDrop"],
        "opacity": preset["opacity"],
        "label": clothing_item.get("name"),
        "patternSeed": md5(
            f"{clothing_item.get('name','')}-{clothing_item.get('color','')}".encode(
                "utf-8"
            )
        ).hexdigest()[:8],
    }


def _filter_items(items, *, predicate):
    return [item for item in items if predicate(item)]


@app.get("/health")
def health():
    return jsonify(
        {
            "ok": True,
            "service": SERVICE_NAME,
            "storageBackend": _get_store().store_name,
            "timestamp": _utc_now(),
        }
    )


@app.get("/")
def index():
    return jsonify(
        {
            "ok": True,
            "service": SERVICE_NAME,
            "storageBackend": _get_store().store_name,
            "message": "PetFashion backend is running.",
            "endpoints": [
                "/health",
                "/breeds",
                "/pets",
                "/closet/items",
                "/saved-looks",
                "/analyze-pet",
                "/recommend-outfits",
                "/tryon-demo",
            ],
        }
    )


@app.post("/analyze-pet")
def analyze_pet():
    payload = request.get_json(silent=True) or {}

    try:
        pet_data = _extract_pet_payload(payload)
    except ValueError as error:
        return _json_error(400, str(error))

    breed_name = pet_data["breed"]
    matched_breed = _match_breed_by_name(breed_name)
    body_size = _infer_body_size(pet_data["weight"], matched_breed)
    fur_color = pet_data["furColor"] or "unknown"
    style_tags = _normalize_text_list(payload.get("styleTags"))
    if not style_tags:
        style_tags = _infer_style_tags(body_size, fur_color)

    confidence = 0.92 if matched_breed is not None else 0.58

    return jsonify(
        {
            "ok": True,
            "result": {
                "analysisId": f"analysis_{uuid4().hex[:8]}",
                "petId": payload.get("petId"),
                "petName": pet_data["name"],
                "petType": pet_data["type"],
                "furColor": fur_color,
                "bodySize": body_size,
                "styleTags": style_tags,
                "matchedBreedId": matched_breed["id"] if matched_breed else None,
                "matchedBreedName": matched_breed["displayName"] if matched_breed else None,
                "baselineUsed": matched_breed is not None,
                "confidence": confidence,
                "createdAt": _utc_now(),
            },
        }
    )


@app.get("/breeds")
def list_breeds():
    species = _normalize_text(request.args.get("species"), "dog").casefold()
    items = _filter_items(
        BREED_BASELINES,
        predicate=lambda item: item["species"].casefold() == species,
    )
    return jsonify({"ok": True, "count": len(items), "items": items})


@app.get("/breeds/<breed_id>")
def get_breed(breed_id):
    item = BREED_BASELINE_BY_ID.get(breed_id)
    if item is None:
        return _not_found("Breed not found")
    return jsonify({"ok": True, "item": item})


@app.get("/pets")
def list_pets():
    store = _get_store()
    breed = _normalize_text(request.args.get("breed")).casefold()
    query = _normalize_text(request.args.get("q")).casefold()
    items = store.list_pets(breed=breed, query=query)
    serialized = [_serialize_pet(item) for item in items]
    return jsonify({"ok": True, "count": len(serialized), "items": serialized})


@app.get("/pets/<pet_id>")
def get_pet(pet_id):
    item = _get_store().get_pet(pet_id)
    if item is None:
        return _not_found("Pet not found")
    return jsonify({"ok": True, "item": _serialize_pet(item)})


@app.post("/pets")
def create_pet():
    store = _get_store()
    payload = request.get_json(silent=True) or {}
    try:
        pet_data = _extract_pet_payload(payload)
    except ValueError as error:
        return _json_error(400, str(error))

    if not pet_data["breed"]:
        return _json_error(400, "breed is required", "breed")

    item = {
        "petId": f"pet_{uuid4().hex[:8]}",
        **pet_data,
        "createdAt": _utc_now(),
    }
    store.create_pet(item)
    return jsonify({"ok": True, "item": _serialize_pet(item)}), 201


@app.put("/pets/<pet_id>")
def update_pet(pet_id):
    store = _get_store()
    existing = store.get_pet(pet_id)
    if existing is None:
        return _not_found("Pet not found")

    payload = request.get_json(silent=True) or {}
    try:
        pet_data = _extract_pet_payload(payload)
    except ValueError as error:
        return _json_error(400, str(error))

    if not pet_data["breed"]:
        return _json_error(400, "breed is required", "breed")

    item = {
        **existing,
        **pet_data,
        "petId": pet_id,
        "createdAt": existing.get("createdAt") or _utc_now(),
    }
    updated = store.update_pet(pet_id, item)
    return jsonify({"ok": True, "item": _serialize_pet(updated)})


@app.get("/closet/items")
def list_closet_items():
    store = _get_store()
    owner_id = _normalize_text(request.args.get("ownerId"))
    category = _normalize_text(request.args.get("category")).casefold()
    season = _normalize_text(request.args.get("season")).casefold()
    items = store.list_closet_items(owner_id=owner_id, category=category, season=season)
    serialized = [_serialize_closet_item(item) for item in items]
    return jsonify({"ok": True, "count": len(serialized), "items": serialized})


@app.get("/closet/items/<item_id>")
def get_closet_item(item_id):
    item = _get_store().get_closet_item(item_id)
    if item is None:
        return _not_found("Closet item not found")
    return jsonify({"ok": True, "item": _serialize_closet_item(item)})


@app.post("/closet/items")
def create_closet_item():
    store = _get_store()
    payload = request.get_json(silent=True) or {}
    name = _normalize_text(payload.get("name"))
    if not name:
        return _json_error(400, "name is required", "name")

    item = {
        "clothingId": f"closet_{uuid4().hex[:8]}",
        "ownerId": _normalize_text(payload.get("ownerId"), DEFAULT_OWNER_ID),
        "name": name,
        "category": _normalize_text(payload.get("category"), "Top"),
        "color": _normalize_text(payload.get("color"), "unknown"),
        "size": _normalize_text(payload.get("size"), "M"),
        "brand": _normalize_text(payload.get("brand"), "Unknown"),
        "seasonTags": _normalize_text_list(payload.get("seasonTags")) or ["all-season"],
        "imageUrl": _normalize_text(payload.get("imageUrl")) or None,
        "sourceUrl": _normalize_text(payload.get("sourceUrl")) or None,
        "createdAt": _utc_now(),
    }
    store.create_closet_item(item)
    return jsonify({"ok": True, "item": _serialize_closet_item(item)}), 201


@app.get("/saved-looks")
def list_saved_looks():
    store = _get_store()
    pet_id = _normalize_text(request.args.get("petId"))
    items = store.list_saved_looks(pet_id=pet_id)
    serialized = [_serialize_saved_look(item, store) for item in items]
    return jsonify({"ok": True, "count": len(serialized), "items": serialized})


@app.get("/saved-looks/<look_id>")
def get_saved_look(look_id):
    store = _get_store()
    item = store.get_saved_look(look_id)
    if item is None:
        return _not_found("Saved look not found")
    return jsonify({"ok": True, "item": _serialize_saved_look(item, store)})


@app.post("/saved-looks")
def create_saved_look():
    store = _get_store()
    payload = request.get_json(silent=True) or {}
    pet_id = _normalize_text(payload.get("petId"))
    if not pet_id:
        return _json_error(400, "petId is required", "petId")
    if store.get_pet(pet_id) is None:
        return _json_error(404, "Pet not found", "petId")

    clothing_ids = _normalize_text_list(payload.get("clothingIds"))
    if not clothing_ids:
        return _json_error(400, "clothingIds is required", "clothingIds")

    missing_ids = [
        clothing_id
        for clothing_id in clothing_ids
        if store.get_closet_item(clothing_id) is None
    ]
    if missing_ids:
        return _json_error(404, f"Closet items not found: {', '.join(missing_ids)}")

    item = {
        "lookId": f"look_{uuid4().hex[:8]}",
        "petId": pet_id,
        "clothingIds": clothing_ids,
        "thumbnailUrl": _normalize_text(payload.get("thumbnailUrl"))
        or _build_tryon_result_image_url(clothing_ids[0]),
        "memo": _normalize_text(payload.get("memo")),
        "createdAt": _utc_now(),
    }
    store.create_saved_look(item)
    return jsonify({"ok": True, "item": _serialize_saved_look(item, store)}), 201


@app.post("/recommend-outfits")
def recommend_outfits():
    store = _get_store()
    payload = request.get_json(silent=True) or {}
    pet_id = _normalize_text(payload.get("petId"))
    pet = store.get_pet(pet_id) if pet_id else None

    breed = _normalize_text(payload.get("breed") or (pet or {}).get("breed"))
    fur_color = _normalize_text(payload.get("furColor") or (pet or {}).get("furColor"), "unknown")
    body_size = _normalize_text(payload.get("bodySize"))

    if not body_size:
        baseline = _match_breed_by_name(breed) if breed else None
        try:
            weight = _parse_float(payload, "weight", "weightKg")
        except ValueError as error:
            return _json_error(400, f"Invalid numeric field: {error.args[0]}")
        if weight is None and pet is not None:
            weight = pet.get("weight")
        body_size = _infer_body_size(weight, baseline)

    requested_tags = _normalize_text_list(payload.get("styleTags"))
    derived_tags = requested_tags or _infer_style_tags(body_size, fur_color)
    preferred_season = _normalize_text(payload.get("season")).casefold()

    scored_items = []
    for item in store.list_closet_items():
        score = 0
        reasons = []
        item_name = _normalize_text(item.get("name")).casefold()
        category = _normalize_text(item.get("category")).casefold()
        season_tags = [tag.casefold() for tag in item.get("seasonTags", [])]
        item_color = _normalize_text(item.get("color")).casefold()

        if preferred_season and preferred_season in season_tags:
            score += 3
            reasons.append(f"Fits the requested {preferred_season} season")
        if "pastel-match" in derived_tags and item_color in {"blue", "pink", "cream"}:
            score += 2
            reasons.append("Works with lighter fur tones")
        if "outdoor" in derived_tags and category in {"coat", "hoodie"}:
            score += 2
            reasons.append("Matches an active outdoor style")
        if "cute" in derived_tags and any(keyword in item_name for keyword in ("hoodie", "vest")):
            score += 1
            reasons.append("Supports a softer casual look")
        if body_size in {"large", "x-large"} and item.get("size") in {"L", "XL"}:
            score += 2
            reasons.append("Size is more suitable for a larger frame")
        elif body_size in {"toy", "small"} and item.get("size") in {"XS", "S"}:
            score += 2
            reasons.append("Size is more suitable for a smaller frame")
        elif body_size == "medium" and item.get("size") == "M":
            score += 2
            reasons.append("Size is aligned with a medium frame")

        scored_items.append((score, reasons, item))

    scored_items.sort(
        key=lambda entry: (
            entry[0],
            entry[2].get("name", ""),
        ),
        reverse=True,
    )

    selected_items = []
    for score, reasons, item in scored_items[:3]:
        selected_items.append(
            {
                **_serialize_closet_item(item),
                "score": score,
                "matchReason": reasons[0] if reasons else "General profile match",
                "matchReasons": reasons or ["General profile match"],
            }
        )

    return jsonify(
        {
            "ok": True,
            "recommendationId": f"rec_{uuid4().hex[:8]}",
            "petId": pet_id or (pet or {}).get("petId"),
            "reason": "Seed-based recommendation using body size, fur tone, and closet metadata.",
            "styleTags": derived_tags,
            "createdAt": _utc_now(),
            "items": selected_items,
        }
    )


@app.post("/tryon-demo")
def tryon_demo():
    store = _get_store()
    payload = request.get_json(silent=True) or {}
    clothing_id = _normalize_text(payload.get("clothingId") or payload.get("outfitId"))
    clothing_item = None
    if clothing_id:
        clothing_item = store.get_closet_item(clothing_id)
    if clothing_item is None:
        clothing_item = _build_virtual_clothing_item(payload, clothing_id)
    if clothing_item is None:
        return _json_error(400, "clothingId or outfit name is required", "clothingId")

    pet_id = _normalize_text(payload.get("petId"))
    pet = store.get_pet(pet_id) if pet_id else None
    render_spec = _build_tryon_render_spec(pet, clothing_item)
    preview_mode = "overlay"
    generated_image_base64 = None
    generated_image_mime_type = None

    try:
        request_image, request_image_mime_type = _extract_tryon_image(payload)
    except ValueError:
        return _json_error(400, "imageBase64 is invalid", "imageBase64")

    if request_image is not None:
        try:
            (
                generated_image_base64,
                generated_image_mime_type,
            ) = _generate_vertex_tryon_image(
                request_image,
                request_image_mime_type,
                clothing_item,
                pet,
            )
            preview_mode = "vertex"
        except Exception as error:
            app.logger.exception("Vertex try-on generation failed: %s", error)

    summary_parts = []
    if pet is not None:
        summary_parts.append(f"{pet['name']} wearing {clothing_item['name']}")
    else:
        summary_parts.append(f"Previewing {clothing_item['name']}")
    summary_parts.append(f"color {clothing_item['color']}")

    return jsonify(
        {
            "ok": True,
            "tryOnId": f"tryon_{uuid4().hex[:8]}",
            "petId": pet_id or None,
            "clothingId": clothing_id,
            "resultImageUrl": _build_tryon_result_image_url(clothing_id),
            "overlaySummary": ", ".join(summary_parts),
            "previewMode": preview_mode,
            "item": _serialize_closet_item(clothing_item),
            "renderSpec": render_spec,
            "generatedImageBase64": generated_image_base64,
            "generatedImageMimeType": generated_image_mime_type,
            "createdAt": _utc_now(),
        }
    )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
