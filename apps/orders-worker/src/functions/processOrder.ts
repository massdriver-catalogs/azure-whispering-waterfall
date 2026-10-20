import { app, InvocationContext } from "@azure/functions";

// The queue trigger reads one order event at a time. The runtime sets the app
// setting EVENTS_CONNECTION_STRING from the `events` dependency, and
// EVENTS_QUEUE_NAME from the app envs.
export async function processOrder(message: unknown, context: InvocationContext): Promise<void> {
  const event = typeof message === "string" ? safeParse(message) : message;
  context.log(
    JSON.stringify({
      msg: "order event processed",
      worker: process.env.SERVICE_NAME ?? "orders-worker",
      dequeueCount: context.triggerMetadata?.dequeueCount,
      event,
    }),
  );
}

function safeParse(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}

app.storageQueue("processOrder", {
  queueName: "%EVENTS_QUEUE_NAME%",
  connection: "EVENTS_CONNECTION_STRING",
  handler: processOrder,
});
