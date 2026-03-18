import os
from datetime import datetime, timezone
from uuid import uuid4

from flask import Flask, jsonify, request

try:
    from .breed_baselines import BREED_BASELINES, BREED_BASELINE_BY_ID
    from .seed_data import CLOSET_ITEMS, PETS, SAVED_LOOKS
except ImportError:
    from breed_baselines import BREED_BASELINES, BREED_BASELINE_BY_ID
    from seed_data import CLOSET_ITEMS, PETS, SAVED_LOOKS

app = Flask(__name__)


SERVICE_NAME = "petfashion-backend"
DEFAULT_OWNER_ID = "demo_user"


def _utc_now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _find_by_id(items, field_name, item_id):
    return next((item for item in items if item[field_name] == item_id), None)


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


def _serialize_saved_look(item):
    closet_items = []
    for clothing_id in item.get("clothingIds", []):
        closet_item = _find_by_id(CLOSET_ITEMS, "clothingId", clothing_id)
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


def _filter_items(items, *, predicate):
    return [item for item in items if predicate(item)]


@app.get("/health")
def health():
    return jsonify({"ok": True, "service": SERVICE_NAME, "timestamp": _utc_now()})


@app.get("/")
def index():
    return jsonify(
        {
            "ok": True,
            "service": SERVICE_NAME,
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
    breed = _normalize_text(request.args.get("breed")).casefold()
    query = _normalize_text(request.args.get("q")).casefold()

    items = _filter_items(
        PETS,
        predicate=lambda item: (
            (not breed or _normalize_text(item.get("breed")).casefold() == breed)
            and (
                not query
                or query in _normalize_text(item.get("name")).casefold()
                or query in _normalize_text(item.get("breed")).casefold()
            )
        ),
    )
    serialized = [_serialize_pet(item) for item in items]
    return jsonify({"ok": True, "count": len(serialized), "items": serialized})


@app.get("/pets/<pet_id>")
def get_pet(pet_id):
    item = _find_by_id(PETS, "petId", pet_id)
    if item is None:
        return _not_found("Pet not found")
    return jsonify({"ok": True, "item": _serialize_pet(item)})


@app.post("/pets")
def create_pet():
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
    PETS.append(item)
    return jsonify({"ok": True, "item": _serialize_pet(item)}), 201


@app.get("/closet/items")
def list_closet_items():
    owner_id = _normalize_text(request.args.get("ownerId"))
    category = _normalize_text(request.args.get("category")).casefold()
    season = _normalize_text(request.args.get("season")).casefold()

    items = _filter_items(
        CLOSET_ITEMS,
        predicate=lambda item: (
            (not owner_id or item.get("ownerId") == owner_id)
            and (not category or _normalize_text(item.get("category")).casefold() == category)
            and (
                not season
                or season in [tag.casefold() for tag in item.get("seasonTags", [])]
            )
        ),
    )
    serialized = [_serialize_closet_item(item) for item in items]
    return jsonify({"ok": True, "count": len(serialized), "items": serialized})


@app.get("/closet/items/<item_id>")
def get_closet_item(item_id):
    item = _find_by_id(CLOSET_ITEMS, "clothingId", item_id)
    if item is None:
        return _not_found("Closet item not found")
    return jsonify({"ok": True, "item": _serialize_closet_item(item)})


@app.post("/closet/items")
def create_closet_item():
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
    CLOSET_ITEMS.append(item)
    return jsonify({"ok": True, "item": _serialize_closet_item(item)}), 201


@app.get("/saved-looks")
def list_saved_looks():
    pet_id = _normalize_text(request.args.get("petId"))
    items = _filter_items(
        SAVED_LOOKS,
        predicate=lambda item: not pet_id or item.get("petId") == pet_id,
    )
    serialized = [_serialize_saved_look(item) for item in items]
    return jsonify({"ok": True, "count": len(serialized), "items": serialized})


@app.get("/saved-looks/<look_id>")
def get_saved_look(look_id):
    item = _find_by_id(SAVED_LOOKS, "lookId", look_id)
    if item is None:
        return _not_found("Saved look not found")
    return jsonify({"ok": True, "item": _serialize_saved_look(item)})


@app.post("/saved-looks")
def create_saved_look():
    payload = request.get_json(silent=True) or {}
    pet_id = _normalize_text(payload.get("petId"))
    if not pet_id:
        return _json_error(400, "petId is required", "petId")
    if _find_by_id(PETS, "petId", pet_id) is None:
        return _json_error(404, "Pet not found", "petId")

    clothing_ids = _normalize_text_list(payload.get("clothingIds"))
    if not clothing_ids:
        return _json_error(400, "clothingIds is required", "clothingIds")

    missing_ids = [
        clothing_id
        for clothing_id in clothing_ids
        if _find_by_id(CLOSET_ITEMS, "clothingId", clothing_id) is None
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
    SAVED_LOOKS.append(item)
    return jsonify({"ok": True, "item": _serialize_saved_look(item)}), 201


@app.post("/recommend-outfits")
def recommend_outfits():
    payload = request.get_json(silent=True) or {}
    pet_id = _normalize_text(payload.get("petId"))
    pet = _find_by_id(PETS, "petId", pet_id) if pet_id else None

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
    for item in CLOSET_ITEMS:
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
    payload = request.get_json(silent=True) or {}
    clothing_id = _normalize_text(payload.get("clothingId") or payload.get("outfitId"))
    if not clothing_id:
        return _json_error(400, "clothingId is required", "clothingId")

    clothing_item = _find_by_id(CLOSET_ITEMS, "clothingId", clothing_id)
    if clothing_item is None:
        return _json_error(404, "Closet item not found", "clothingId")

    pet_id = _normalize_text(payload.get("petId"))
    pet = _find_by_id(PETS, "petId", pet_id) if pet_id else None

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
            "item": _serialize_closet_item(clothing_item),
            "createdAt": _utc_now(),
        }
    )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
