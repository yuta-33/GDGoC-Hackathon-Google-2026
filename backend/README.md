# PetFashion Backend

Minimal Flask backend for local testing and Google Cloud Run deployment.

## Files

- `app.py`: Flask app with dummy endpoints
- `seed_data.py`: In-memory dog profiles, closet items, and saved looks
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

## Notes

- Uses `PORT` environment variable for startup
- No Firestore, Storage, Secret Manager, auth, or external AI API integration yet
- Returns fixed or in-memory dummy JSON for frontend-backend connectivity checks
- `GET /pets`, `GET /closet/items`, `GET /saved-looks` support simple query filters
- Dog-only backend for the current product scope
- Breed data is currently a seed baseline list with one standard measurement per breed
- Actual pet measurements should still be entered and adjusted by the user
