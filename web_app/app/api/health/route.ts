import { apiBaseUrl } from "@/lib/config";

export async function GET() {
  const upstream = await fetch(`${apiBaseUrl}/health`, {
    method: "GET",
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
