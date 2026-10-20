import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

// GET /api/hello returns a greeting. The route holds no private data, so it
// accepts anonymous calls. The Orders Processor calls it.
export async function hello(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  const caller = request.query.get("from") ?? "anonymous";
  context.log(`hello called by ${caller}`);
  return {
    status: 200,
    jsonBody: {
      service: process.env.SERVICE_NAME ?? "orders-api",
      message: "Hello from the Orders API (Azure Functions, Node.js 22)",
      caller,
      time: new Date().toISOString(),
    },
  };
}

app.http("hello", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "hello",
  handler: hello,
});
