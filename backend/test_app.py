import copy
import unittest

from backend.app import app
from backend.seed_data import CLOSET_ITEMS, PETS, SAVED_LOOKS


class BackendApiTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self._pets = copy.deepcopy(PETS)
        self._closet_items = copy.deepcopy(CLOSET_ITEMS)
        self._saved_looks = copy.deepcopy(SAVED_LOOKS)

    def tearDown(self):
        PETS[:] = self._pets
        CLOSET_ITEMS[:] = self._closet_items
        SAVED_LOOKS[:] = self._saved_looks

    def test_health_returns_service_status(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["service"], "petfashion-backend")
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

        self.assertEqual(response.status_code, 404)
        payload = response.get_json()
        self.assertFalse(payload["ok"])


if __name__ == "__main__":
    unittest.main()
