import tempfile
import unittest

from backend.app import _build_tryon_vertex_prompt, app
from backend.db import SQLiteStore


class BackendApiTestCase(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.store = SQLiteStore(f"{self.temp_dir.name}/test_backend.db")
        app.config["DATA_STORE"] = self.store
        self.client = app.test_client()

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_health_returns_service_status(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["service"], "petfashion-backend")
        self.assertEqual(payload["storageBackend"], "sqlite")
        self.assertIn("timestamp", payload)

    def test_root_returns_endpoint_index(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertTrue(payload["ok"])
        self.assertIn("/health", payload["endpoints"])

    def test_breeds_endpoint_returns_seeded_items(self):
        response = self.client.get("/breeds")

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertGreater(payload["count"], 0)
        self.assertEqual(payload["count"], len(payload["items"]))

    def test_analyze_pet_uses_breed_baseline(self):
        response = self.client.post(
            "/analyze-pet",
            json={
                "petName": "Buddy",
                "breed": "Golden Retriever",
                "weight": 29,
                "furColor": "golden",
            },
        )

        self.assertEqual(response.status_code, 200)
        result = response.get_json()["result"]
        self.assertEqual(result["matchedBreedId"], "golden_retriever")
        self.assertEqual(result["bodySize"], "large")
        self.assertTrue(result["baselineUsed"])

    def test_create_pet_accepts_frontend_measurement_keys(self):
        response = self.client.post(
            "/pets",
            json={
                "petName": "Coco",
                "breed": "Pomeranian",
                "weight": 3.4,
                "neckGirth": 21.5,
                "chestGirth": 31.0,
                "backLength": 22.0,
                "photoPath": "/tmp/coco.png",
            },
        )

        self.assertEqual(response.status_code, 201)
        item = response.get_json()["item"]
        self.assertEqual(item["name"], "Coco")
        self.assertEqual(item["breed"], "Pomeranian")
        self.assertEqual(item["neckGirthCm"], 21.5)
        self.assertEqual(item["neckGirth"], 21.5)
        self.assertEqual(item["imageUrl"], "/tmp/coco.png")

    def test_created_pet_is_readable_from_following_request(self):
        create_response = self.client.post(
            "/pets",
            json={
                "petName": "Nana",
                "breed": "Shiba Inu",
                "weight": 9.2,
            },
        )

        self.assertEqual(create_response.status_code, 201)
        pet_id = create_response.get_json()["item"]["petId"]

        fetch_response = self.client.get(f"/pets/{pet_id}")

        self.assertEqual(fetch_response.status_code, 200)
        item = fetch_response.get_json()["item"]
        self.assertEqual(item["name"], "Nana")
        self.assertEqual(item["breed"], "Shiba Inu")

    def test_update_pet_overwrites_existing_fields(self):
        response = self.client.put(
            "/pets/pet_001",
            json={
                "petName": "Buddy Updated",
                "breed": "Golden Retriever",
                "weight": 30.1,
                "neckGirth": 43,
                "chestGirth": 69,
                "backLength": 56,
                "photoPath": "/tmp/buddy_updated.png",
            },
        )

        self.assertEqual(response.status_code, 200)
        item = response.get_json()["item"]
        self.assertEqual(item["petId"], "pet_001")
        self.assertEqual(item["name"], "Buddy Updated")
        self.assertEqual(item["imageUrl"], "/tmp/buddy_updated.png")
        self.assertEqual(item["neckGirthCm"], 43)

    def test_list_closet_items_supports_season_filter(self):
        response = self.client.get("/closet/items?season=rainy")

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload["count"], 1)
        self.assertEqual(payload["items"][0]["clothingId"], "closet_003")

    def test_create_saved_look_validates_references(self):
        response = self.client.post(
            "/saved-looks",
            json={"petId": "pet_001", "clothingIds": ["missing_item"]},
        )

        self.assertEqual(response.status_code, 404)
        payload = response.get_json()
        self.assertFalse(payload["ok"])

    def test_create_saved_look_returns_embedded_items(self):
        response = self.client.post(
            "/saved-looks",
            json={
                "petId": "pet_001",
                "clothingIds": ["closet_001", "closet_002"],
                "memo": "Weekend look",
            },
        )

        self.assertEqual(response.status_code, 201)
        item = response.get_json()["item"]
        self.assertEqual(item["itemCount"], 2)
        self.assertEqual(len(item["items"]), 2)
        self.assertEqual(item["memo"], "Weekend look")

    def test_recommend_outfits_returns_ranked_items(self):
        response = self.client.post(
            "/recommend-outfits",
            json={
                "petId": "pet_001",
                "furColor": "golden",
                "bodySize": "large",
                "season": "winter",
            },
        )

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertTrue(payload["items"])
        self.assertIn("matchReason", payload["items"][0])
        self.assertGreaterEqual(payload["items"][0]["score"], payload["items"][-1]["score"])

    def test_tryon_demo_requires_existing_item(self):
        response = self.client.post(
            "/tryon-demo",
            json={"petId": "pet_001", "clothingId": "missing_item"},
        )

        self.assertEqual(response.status_code, 400)
        payload = response.get_json()
        self.assertFalse(payload["ok"])

    def test_tryon_demo_accepts_virtual_outfit_payload(self):
        response = self.client.post(
            "/tryon-demo",
            json={
                "petId": "pet_001",
                "outfitName": "Prototype Hoodie",
                "category": "Hoodie",
                "color": "blue",
                "size": "M",
                "pattern": "check",
            },
        )

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload["item"]["name"], "Prototype Hoodie")
        self.assertEqual(payload["renderSpec"]["renderer"], "overlay-v1")
        self.assertEqual(payload["renderSpec"]["garmentType"], "hoodie")
        self.assertEqual(payload["renderSpec"]["patternStyle"], "check")

    def test_tryon_prompt_mentions_panda_details(self):
        prompt = _build_tryon_vertex_prompt(
            {
                "clothingId": "virtual_001",
                "presetId": "moncheri-panda-parka",
                "name": "Panda Parka",
                "category": "Hoodie",
                "color": "Mocha",
                "brand": "moncheri",
                "description": "Soft panda-inspired parka",
                "hasReferenceImage": True,
            },
            {"breed": "Jack Russell Terrier"},
        )

        self.assertIn("second image as the clothing reference", prompt)
        self.assertIn("panda ear details on the hood", prompt)
        self.assertIn("small rounded panda tail patch", prompt)

    def test_tryon_prompt_mentions_security_back_print(self):
        prompt = _build_tryon_vertex_prompt(
            {
                "clothingId": "virtual_002",
                "presetId": "amazon-security-hoodie",
                "name": "Security Hoodie",
                "category": "Hoodie",
                "color": "Red",
                "brand": "Amazon",
                "description": "Playful red hoodie with a bold back print",
                "hasReferenceImage": False,
            },
            {"breed": "Jack Russell Terrier"},
        )

        self.assertIn("SECURITY print visible across the back panel", prompt)

    def test_tryon_prompt_mentions_carrot_details(self):
        prompt = _build_tryon_vertex_prompt(
            {
                "clothingId": "virtual_003",
                "presetId": "amazon-carrot-vest",
                "name": "Carrot Vest",
                "category": "Vest",
                "color": "Orange",
                "brand": "Amazon",
                "description": "Warm carrot-themed fleece vest",
                "hasReferenceImage": True,
            },
            {"breed": "Jack Russell Terrier"},
        )

        self.assertIn("green carrot-leaf collar detail", prompt)
        self.assertIn("stitched yellow carrot-cut accents", prompt)

    def test_tryon_prompt_mentions_ribbon_details(self):
        prompt = _build_tryon_vertex_prompt(
            {
                "clothingId": "virtual_004",
                "presetId": "moncheri-ribbon-dress",
                "name": "Ribbon Dress",
                "category": "Dress",
                "color": "Beige",
                "brand": "moncheri",
                "description": "A soft ribbon-pattern dress with a large back bow",
                "hasReferenceImage": True,
            },
            {"breed": "Jack Russell Terrier"},
        )

        self.assertIn("oversized back bow", prompt)
        self.assertIn("tiny embroidered ribbon pattern", prompt)

    def test_tryon_prompt_mentions_raincoat_details(self):
        prompt = _build_tryon_vertex_prompt(
            {
                "clothingId": "virtual_005",
                "presetId": "amazon-raincoat",
                "name": "Reflective Rain Coat",
                "category": "Outerwear",
                "color": "Black",
                "brand": "Amazon",
                "description": "Lightweight rain coat with reflective sleeve accents",
                "hasReferenceImage": True,
            },
            {"breed": "Jack Russell Terrier"},
        )

        self.assertIn("reflective silver sleeve stripes", prompt)
        self.assertIn("black lightweight outer shell", prompt)


if __name__ == "__main__":
    unittest.main()
