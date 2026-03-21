# PetFit Web

Next.js frontend for the hackathon demo.

## Run

```bash
cd web_app
npm install
npm run dev
```

## Environment

Optional:

```bash
NEXT_PUBLIC_API_BASE_URL=https://petfashion-backend-604416065934.asia-northeast1.run.app
```

The app proxies browser requests through Next route handlers under `app/api/*`,
so the first web version does not require direct browser-to-Cloud-Run CORS setup.
