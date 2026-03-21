import { apiBaseUrl } from "@/lib/config";

export async function POST(request: Request) {
  const payload = await request.text();

  const upstream = await fetch(`${apiBaseUrl}/tryon-demo`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: payload,
    cache: "no-store"
  });

  const body = await upstream.text();

  return new Response(body, {
    status: upstream.status,
    headers: {
      "Content-Type": upstream.headers.get("Content-Type") ?? "application/json"
    }
  });
}
