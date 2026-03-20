import json
import os
import sqlite3
from pathlib import Path

try:
    from google.cloud import firestore
except ImportError:  # pragma: no cover - optional during local bootstrap
    firestore = None

try:
    from .seed_data import CLOSET_ITEMS, PETS, SAVED_LOOKS
except ImportError:
    from seed_data import CLOSET_ITEMS, PETS, SAVED_LOOKS
class BaseStore:
    store_name = "base"

    def _sort(self, items, *keys):
        return sorted(
            items,
            key=lambda item: tuple(item.get(key) or "" for key in keys),
        )


class SQLiteStore(BaseStore):
    store_name = "sqlite"

    def __init__(self, db_path):
        self.db_path = Path(db_path)
        if self.db_path != Path(":memory:"):
            self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def _connect(self):
        connection = sqlite3.connect(str(self.db_path))
        connection.row_factory = sqlite3.Row
        return connection

    def _initialize(self):
        with self._connect() as connection:
            connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS pets (
                    pet_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    type TEXT NOT NULL,
                    breed TEXT NOT NULL,
                    age INTEGER,
                    weight REAL,
                    gender TEXT,
                    fur_color TEXT,
                    image_url TEXT,
                    size_note TEXT,
                    neck_girth_cm REAL,
                    chest_girth_cm REAL,
                    back_length_cm REAL,
                    created_at TEXT
                );

                CREATE TABLE IF NOT EXISTS closet_items (
                    clothing_id TEXT PRIMARY KEY,
                    owner_id TEXT NOT NULL,
                    name TEXT NOT NULL,
                    category TEXT NOT NULL,
                    color TEXT NOT NULL,
                    size TEXT NOT NULL,
                    brand TEXT NOT NULL,
                    season_tags TEXT NOT NULL,
                    image_url TEXT,
                    source_url TEXT,
                    created_at TEXT
                );

                CREATE TABLE IF NOT EXISTS saved_looks (
                    look_id TEXT PRIMARY KEY,
                    pet_id TEXT NOT NULL,
                    clothing_ids TEXT NOT NULL,
                    thumbnail_url TEXT,
                    memo TEXT,
                    created_at TEXT
                );
                """
            )
            self._seed_if_empty(connection)

    def _seed_if_empty(self, connection):
        if self._table_has_rows(connection, "pets"):
            return

        connection.executemany(
            """
            INSERT INTO pets (
                pet_id, name, type, breed, age, weight, gender, fur_color,
                image_url, size_note, neck_girth_cm, chest_girth_cm,
                back_length_cm, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    item["petId"],
                    item["name"],
                    item["type"],
                    item["breed"],
                    item.get("age"),
                    item.get("weight"),
                    item.get("gender"),
                    item.get("furColor"),
                    item.get("imageUrl"),
                    item.get("sizeNote"),
                    item.get("neckGirthCm"),
                    item.get("chestGirthCm"),
                    item.get("backLengthCm"),
                    item.get("createdAt"),
                )
                for item in PETS
            ],
        )
        connection.executemany(
            """
            INSERT INTO closet_items (
                clothing_id, owner_id, name, category, color, size, brand,
                season_tags, image_url, source_url, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    item["clothingId"],
                    item["ownerId"],
                    item["name"],
                    item["category"],
                    item["color"],
                    item["size"],
                    item["brand"],
                    json.dumps(item.get("seasonTags", [])),
                    item.get("imageUrl"),
                    item.get("sourceUrl"),
                    item.get("createdAt"),
                )
                for item in CLOSET_ITEMS
            ],
        )
        connection.executemany(
            """
            INSERT INTO saved_looks (
                look_id, pet_id, clothing_ids, thumbnail_url, memo, created_at
            ) VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    item["lookId"],
                    item["petId"],
                    json.dumps(item.get("clothingIds", [])),
                    item.get("thumbnailUrl"),
                    item.get("memo"),
                    item.get("createdAt"),
                )
                for item in SAVED_LOOKS
            ],
        )

    @staticmethod
    def _table_has_rows(connection, table_name):
        row = connection.execute(
            f"SELECT 1 FROM {table_name} LIMIT 1"
        ).fetchone()
        return row is not None

    @staticmethod
    def _deserialize_pet(row):
        return {
            "petId": row["pet_id"],
            "name": row["name"],
            "type": row["type"],
            "breed": row["breed"],
            "age": row["age"],
            "weight": row["weight"],
            "gender": row["gender"],
            "furColor": row["fur_color"],
            "imageUrl": row["image_url"],
            "sizeNote": row["size_note"],
            "neckGirthCm": row["neck_girth_cm"],
            "chestGirthCm": row["chest_girth_cm"],
            "backLengthCm": row["back_length_cm"],
            "createdAt": row["created_at"],
        }

    @staticmethod
    def _deserialize_closet_item(row):
        return {
            "clothingId": row["clothing_id"],
            "ownerId": row["owner_id"],
            "name": row["name"],
            "category": row["category"],
            "color": row["color"],
            "size": row["size"],
            "brand": row["brand"],
            "seasonTags": json.loads(row["season_tags"] or "[]"),
            "imageUrl": row["image_url"],
            "sourceUrl": row["source_url"],
            "createdAt": row["created_at"],
        }

    @staticmethod
    def _deserialize_saved_look(row):
        return {
            "lookId": row["look_id"],
            "petId": row["pet_id"],
            "clothingIds": json.loads(row["clothing_ids"] or "[]"),
            "thumbnailUrl": row["thumbnail_url"],
            "memo": row["memo"],
            "createdAt": row["created_at"],
        }

    def list_pets(self, breed="", query=""):
        with self._connect() as connection:
            rows = connection.execute(
                """
                SELECT * FROM pets
                WHERE (? = '' OR lower(breed) = ?)
                  AND (
                      ? = ''
                      OR lower(name) LIKE ?
                      OR lower(breed) LIKE ?
                  )
                ORDER BY created_at IS NULL, created_at, name
                """,
                (
                    breed,
                    breed,
                    query,
                    f"%{query}%",
                    f"%{query}%",
                ),
            ).fetchall()
        return [self._deserialize_pet(row) for row in rows]

    def get_pet(self, pet_id):
        with self._connect() as connection:
            row = connection.execute(
                "SELECT * FROM pets WHERE pet_id = ?",
                (pet_id,),
            ).fetchone()
        if row is None:
            return None
        return self._deserialize_pet(row)

    def create_pet(self, item):
        with self._connect() as connection:
            connection.execute(
                """
                INSERT INTO pets (
                    pet_id, name, type, breed, age, weight, gender, fur_color,
                    image_url, size_note, neck_girth_cm, chest_girth_cm,
                    back_length_cm, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    item["petId"],
                    item["name"],
                    item["type"],
                    item["breed"],
                    item.get("age"),
                    item.get("weight"),
                    item.get("gender"),
                    item.get("furColor"),
                    item.get("imageUrl"),
                    item.get("sizeNote"),
                    item.get("neckGirthCm"),
                    item.get("chestGirthCm"),
                    item.get("backLengthCm"),
                    item.get("createdAt"),
                ),
            )
        return item

    def update_pet(self, pet_id, item):
        with self._connect() as connection:
            connection.execute(
                """
                UPDATE pets
                SET name = ?,
                    type = ?,
                    breed = ?,
                    age = ?,
                    weight = ?,
                    gender = ?,
                    fur_color = ?,
                    image_url = ?,
                    size_note = ?,
                    neck_girth_cm = ?,
                    chest_girth_cm = ?,
                    back_length_cm = ?
                WHERE pet_id = ?
                """,
                (
                    item["name"],
                    item["type"],
                    item["breed"],
                    item.get("age"),
                    item.get("weight"),
                    item.get("gender"),
                    item.get("furColor"),
                    item.get("imageUrl"),
                    item.get("sizeNote"),
                    item.get("neckGirthCm"),
                    item.get("chestGirthCm"),
                    item.get("backLengthCm"),
                    pet_id,
                ),
            )
        return self.get_pet(pet_id)

    def list_closet_items(self, owner_id="", category="", season=""):
        with self._connect() as connection:
            rows = connection.execute(
                """
                SELECT * FROM closet_items
                WHERE (? = '' OR owner_id = ?)
                  AND (? = '' OR lower(category) = ?)
                ORDER BY created_at IS NULL, created_at, name
                """,
                (owner_id, owner_id, category, category),
            ).fetchall()

        items = [self._deserialize_closet_item(row) for row in rows]
        if not season:
            return items
        return [
            item
            for item in items
            if season in [tag.casefold() for tag in item.get("seasonTags", [])]
        ]

    def get_closet_item(self, clothing_id):
        with self._connect() as connection:
            row = connection.execute(
                "SELECT * FROM closet_items WHERE clothing_id = ?",
                (clothing_id,),
            ).fetchone()
        if row is None:
            return None
        return self._deserialize_closet_item(row)

    def create_closet_item(self, item):
        with self._connect() as connection:
            connection.execute(
                """
                INSERT INTO closet_items (
                    clothing_id, owner_id, name, category, color, size, brand,
                    season_tags, image_url, source_url, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    item["clothingId"],
                    item["ownerId"],
                    item["name"],
                    item["category"],
                    item["color"],
                    item["size"],
                    item["brand"],
                    json.dumps(item.get("seasonTags", [])),
                    item.get("imageUrl"),
                    item.get("sourceUrl"),
                    item.get("createdAt"),
                ),
            )
        return item

    def list_saved_looks(self, pet_id=""):
        with self._connect() as connection:
            rows = connection.execute(
                """
                SELECT * FROM saved_looks
                WHERE (? = '' OR pet_id = ?)
                ORDER BY created_at IS NULL, created_at, look_id
                """,
                (pet_id, pet_id),
            ).fetchall()
        return [self._deserialize_saved_look(row) for row in rows]

    def get_saved_look(self, look_id):
        with self._connect() as connection:
            row = connection.execute(
                "SELECT * FROM saved_looks WHERE look_id = ?",
                (look_id,),
            ).fetchone()
        if row is None:
            return None
        return self._deserialize_saved_look(row)

    def create_saved_look(self, item):
        with self._connect() as connection:
            connection.execute(
                """
                INSERT INTO saved_looks (
                    look_id, pet_id, clothing_ids, thumbnail_url, memo, created_at
                ) VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    item["lookId"],
                    item["petId"],
                    json.dumps(item.get("clothingIds", [])),
                    item.get("thumbnailUrl"),
                    item.get("memo"),
                    item.get("createdAt"),
                ),
            )
        return item


class FirestoreStore(BaseStore):
    store_name = "firestore"

    def __init__(self, project_id=None, database=None):
        if firestore is None:
            raise RuntimeError(
                "google-cloud-firestore is not installed. Add it to requirements.txt."
            )
        self.client = firestore.Client(project=project_id, database=database)
        self._seed_if_empty()

    def _collection(self, name):
        return self.client.collection(name)

    def _seed_if_empty(self):
        snapshot = list(self._collection("pets").limit(1).stream())
        if snapshot:
            return
        for item in PETS:
            self.create_pet(item)
        for item in CLOSET_ITEMS:
            self.create_closet_item(item)
        for item in SAVED_LOOKS:
            self.create_saved_look(item)

    @staticmethod
    def _clean_snapshot(snapshot):
        item = snapshot.to_dict() or {}
        return {key: value for key, value in item.items()}

    def list_pets(self, breed="", query=""):
        items = [self._clean_snapshot(doc) for doc in self._collection("pets").stream()]
        if breed:
            items = [
                item for item in items if str(item.get("breed", "")).casefold() == breed
            ]
        if query:
            items = [
                item
                for item in items
                if query in str(item.get("name", "")).casefold()
                or query in str(item.get("breed", "")).casefold()
            ]
        return self._sort(items, "createdAt", "name")

    def get_pet(self, pet_id):
        snapshot = self._collection("pets").document(pet_id).get()
        if not snapshot.exists:
            return None
        return self._clean_snapshot(snapshot)

    def create_pet(self, item):
        self._collection("pets").document(item["petId"]).set(item)
        return item

    def update_pet(self, pet_id, item):
        existing = self.get_pet(pet_id)
        if existing is None:
            return None
        updated = {
            **existing,
            **item,
            "petId": pet_id,
            "createdAt": existing.get("createdAt"),
        }
        self._collection("pets").document(pet_id).set(updated)
        return updated

    def list_closet_items(self, owner_id="", category="", season=""):
        items = [
            self._clean_snapshot(doc)
            for doc in self._collection("closet_items").stream()
        ]
        if owner_id:
            items = [item for item in items if item.get("ownerId") == owner_id]
        if category:
            items = [
                item
                for item in items
                if str(item.get("category", "")).casefold() == category
            ]
        if season:
            items = [
                item
                for item in items
                if season in [tag.casefold() for tag in item.get("seasonTags", [])]
            ]
        return self._sort(items, "createdAt", "name")

    def get_closet_item(self, clothing_id):
        snapshot = self._collection("closet_items").document(clothing_id).get()
        if not snapshot.exists:
            return None
        return self._clean_snapshot(snapshot)

    def create_closet_item(self, item):
        self._collection("closet_items").document(item["clothingId"]).set(item)
        return item

    def list_saved_looks(self, pet_id=""):
        items = [
            self._clean_snapshot(doc)
            for doc in self._collection("saved_looks").stream()
        ]
        if pet_id:
            items = [item for item in items if item.get("petId") == pet_id]
        return self._sort(items, "createdAt", "lookId")

    def get_saved_look(self, look_id):
        snapshot = self._collection("saved_looks").document(look_id).get()
        if not snapshot.exists:
            return None
        return self._clean_snapshot(snapshot)

    def create_saved_look(self, item):
        self._collection("saved_looks").document(item["lookId"]).set(item)
        return item


def default_sqlite_path():
    return str(Path(__file__).with_name("petfashion.db"))


def create_data_store():
    provider = os.environ.get("PETFASHION_DATA_BACKEND")
    if not provider:
        provider = "firestore" if os.environ.get("K_SERVICE") else "sqlite"
    provider = provider.casefold()

    if provider == "firestore":
        return FirestoreStore(
            project_id=os.environ.get("GOOGLE_CLOUD_PROJECT")
            or os.environ.get("GCP_PROJECT"),
            database=os.environ.get("FIRESTORE_DATABASE", "(default)"),
        )

    if provider == "sqlite":
        return SQLiteStore(os.environ.get("PETFASHION_DB_PATH", default_sqlite_path()))

    raise ValueError(f"Unsupported PETFASHION_DATA_BACKEND: {provider}")
