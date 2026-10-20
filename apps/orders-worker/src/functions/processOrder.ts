import { app, InvocationContext } from "@azure/functions";

// The queue trigger reads one order event at a time. The app envs set
// EVENTS_CONNECTION_STRING and EVENTS_QUEUE_NAME from the `events` dependency,
// and DATABRICKS_HOST and DATABRICKS_WORKSPACE from the `lakehouse` dependency.
// The worker does not call Databricks. It writes the values to the log.
export async function processOrder(message: unknown, context: InvocationContext): Promise<void> {
  const event = typeof message === "string" ? safeParse(message) : message;
  context.log(
    JSON.stringify({
      msg: "order event processed",
      worker: process.env.SERVICE_NAME ?? "orders-worker",
      databricksHost: process.env.DATABRICKS_HOST,
      databricksWorkspace: process.env.DATABRICKS_WORKSPACE,
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
