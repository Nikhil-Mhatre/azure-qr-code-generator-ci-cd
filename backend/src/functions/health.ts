import { HttpRequest, HttpResponseInit, app } from "@azure/functions";

export async function health(request: HttpRequest): Promise<HttpResponseInit> {
  // ✅ Health check (FIRST)

  return {
    status: 200,
    jsonBody: {
      status: "ok",
      service: "generate-qr-code",
      timestamp: new Date().toISOString(),
    },
  };
}

app.http("health", {
  methods: ["GET"],
  route: "health",
  authLevel: "anonymous",
  handler: health,
});
