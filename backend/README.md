# PetFashion Backend

Flask backend for local testing and Google Cloud Run deployment.

## Files

- `app.py`: Flask app and endpoint definitions
- `db.py`: Pluggable data store layer
  - local: SQLite
  - GCP / Cloud Run: Firestore
- `seed_data.py`: Seed rows used for first-time DB bootstrap
- `breed_baselines.py`: Dog breed standard measurement baselines
- `requirements.txt`: Python dependencies
- `Dockerfile`: Cloud Run container build definition

## Endpoints

- `GET /health`
- `GET /breeds`
- `GET /breeds/{breedId}`
- `GET /pets`
- `GET /pets/{petId}`
- `POST /pets`
- `PUT /pets/{petId}`
- `GET /closet/items`
- `GET /closet/items/{itemId}`
- `POST /closet/items`
- `GET /saved-looks`
- `GET /saved-looks/{lookId}`
- `POST /saved-looks`
- `POST /analyze-pet`
- `POST /recommend-outfits`
- `POST /tryon-demo`

## Local Run

Run from the `backend` directory:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
PORT=8080 python app.py
```

Server starts on `http://localhost:8080`.

Default storage backend:

- local shell / tests: SQLite (`backend/petfashion.db`)
- Cloud Run (`K_SERVICE` present): Firestore

Override explicitly with:

```bash
export PETFASHION_DATA_BACKEND=sqlite
```

or

```bash
export PETFASHION_DATA_BACKEND=firestore
```

For SQLite, override the DB file with:

```bash
export PETFASHION_DB_PATH=/path/to/file.db
```

## Local Checks With curl

Health check:

```bash
curl http://localhost:8080/health
```

List breed baselines:

```bash
curl http://localhost:8080/breeds
```

Get one breed baseline:

```bash
curl http://localhost:8080/breeds/jack_russell_terrier
```

List pets:

```bash
curl http://localhost:8080/pets
```

Create pet:

```bash
curl -X POST http://localhost:8080/pets \
  -H "Content-Type: application/json" \
  -d '{"name":"Charlie","breed":"Jack Russell Terrier","weight":7.0,"gender":"male"}'
```

Update pet:

```bash
curl -X PUT http://localhost:8080/pets/pet_001 \
  -H "Content-Type: application/json" \
  -d '{"petName":"Buddy Updated","breed":"Golden Retriever","weight":30.1}'
```

List closet items:

```bash
curl http://localhost:8080/closet/items
```

Create closet item:

```bash
curl -X POST http://localhost:8080/closet/items \
  -H "Content-Type: application/json" \
  -d '{"name":"City Hoodie","category":"Hoodie","color":"navy","size":"M","seasonTags":["autumn","winter"]}'
```

List saved looks:

```bash
curl http://localhost:8080/saved-looks
```

Create saved look:

```bash
curl -X POST http://localhost:8080/saved-looks \
  -H "Content-Type: application/json" \
  -d '{"petId":"pet_001","clothingIds":["closet_001","closet_002"],"memo":"Weekend walk"}'
```

Analyze pet:

```bash
curl -X POST http://localhost:8080/analyze-pet \
  -H "Content-Type: application/json" \
  -d '{"petId":"pet_001","petName":"Buddy","breed":"Golden Retriever","furColor":"golden"}'
```

Recommend outfits:

```bash
curl -X POST http://localhost:8080/recommend-outfits \
  -H "Content-Type: application/json" \
  -d '{"petId":"pet_001","petType":"dog","furColor":"golden","bodySize":"medium"}'
```

Try-on demo:

```bash
curl -X POST http://localhost:8080/tryon-demo \
  -H "Content-Type: application/json" \
  -d '{"petId":"pet_001","clothingId":"closet_002"}'
```

## Cloud Run Deploy

Run from the `backend` directory:

```bash
gcloud run deploy petfashion-backend \
  --source . \
  --region asia-northeast1 \
  --allow-unauthenticated
```

After deploy, verify:

```bash
curl "YOUR_CLOUD_RUN_URL/health"
```

When deployed on Cloud Run, the app defaults to Firestore. Ensure these are in
place before deploy:

1. Firestore database is created in the same GCP project
2. Cloud Run service account can access Firestore
3. `GOOGLE_CLOUD_PROJECT` / ADC are available via the runtime environment

Optional Firestore database selection:

```bash
gcloud run services update petfashion-backend \
  --region asia-northeast1 \
  --update-env-vars PETFASHION_DATA_BACKEND=firestore,FIRESTORE_DATABASE='(default)'
```

## Notes

- Uses `PORT` environment variable for startup
- Mutable resources (`/pets`, `/closet/items`, `/saved-looks`) use the configured data store
- Firestore is the intended GCP / Cloud Run backend
- SQLite remains as a local development fallback
- Seed rows are inserted only when the selected store is empty
- No Firestore, Storage, Secret Manager, auth, or external AI API integration yet
- `GET /pets`, `GET /closet/items`, `GET /saved-looks` support simple query filters
- Dog-only backend for the current product scope
- Breed data is currently a seed baseline list with one standard measurement per breed
- Actual pet measurements should still be entered and adjusted by the user
