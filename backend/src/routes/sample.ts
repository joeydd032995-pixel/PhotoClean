import { Hono } from "hono";

const sampleRouter = new Hono();

const GREETINGS = ["Hello", "Hola", "Namaste", "Bonjour"] as const;

sampleRouter.get("/", (c) => {
  try {
    const greeting = GREETINGS[Math.floor(Math.random() * GREETINGS.length)];
    return c.json({
      data: {
        message: `${greeting} from the backend!`,
        timestamp: new Date().toLocaleTimeString(),
      },
    });
  } catch (err) {
    return c.json({ error: { message: "Internal server error", code: "INTERNAL_ERROR" } }, 500);
  }
});

export { sampleRouter };
