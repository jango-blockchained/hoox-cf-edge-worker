import { describe, expect, test, beforeEach, mock } from "bun:test";
import telegramWorker from "../workers/telegram-worker/src/index.js";

describe("Telegram Worker", () => {
    const mockEnv = {
        INTERNAL_SERVICE_KEY: "test-internal-key",
        TELEGRAM_BOT_TOKEN: "test-bot-token"
    };

    const validNotification = {
        message: "⚠️ BTC Hoox Signal: LONG at 50000",
        chatId: 123456789
    };

    beforeEach(() => {
        // Mock Telegram API calls
        global.fetch = mock(() =>
            Promise.resolve(new Response(
                JSON.stringify({ success: true }),
                {
                    status: 200,
                    headers: { "Content-Type": "application/json" }
                }
            ))
        );
    });

    test("validates internal service key", async () => {
        const request = new Request("https://telegram-worker.workers.dev", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "invalid-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validNotification)
        });

        const response = await telegramWorker.fetch(request, mockEnv);
        expect(response.status).toBe(403);
    });

    test("sends telegram message", async () => {
        global.fetch = mock(() =>
            Promise.resolve(new Response(
                JSON.stringify({ ok: true, result: { message_id: 123 } }),
                {
                    status: 200,
                    headers: { "Content-Type": "application/json" }
                }
            ))
        );

        const request = new Request("https://telegram-worker.workers.dev", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validNotification)
        });

        const response = await telegramWorker.fetch(request, mockEnv);
        expect(response.status).toBe(200);

        const responseData = await response.json();
        expect(responseData.success).toBe(true);
        expect(responseData.requestId).toBeDefined();
    });

    test("handles Telegram API errors", async () => {
        global.fetch = mock(() => Promise.reject(new Error("Telegram API Error")));

        const request = new Request("https://telegram-worker.workers.dev", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validNotification)
        });

        const response = await telegramWorker.fetch(request, mockEnv);
        expect(response.status).toBe(500);
    });
}); 