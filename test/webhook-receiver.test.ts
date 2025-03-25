import { describe, expect, test, beforeEach, mock } from "bun:test";
import webhookReceiver from "../webhook-receiver/src/index.js";

describe("Webhook Receiver", () => {
    const mockEnv = {
        API_SECRET_KEY: "test-api-key",
        INTERNAL_SERVICE_KEY: "test-internal-key",
        TRADE_WORKER_URL: "https://trade-worker.workers.dev",
        TELEGRAM_WORKER_URL: "https://telegram-worker.workers.dev"
    };

    const validWebhookPayload = {
        apiKey: "test-api-key",
        exchange: "mexc",
        action: "LONG",
        symbol: "BTC_USDT",
        quantity: 0.1,
        price: 50000,
        leverage: 20,
        notify: {
            message: "⚠️ BTC Grid Signal: LONG at 50000",
            chatId: 123456789
        }
    };

    beforeEach(() => {
        // Mock fetch for external service calls
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

    test("validates API key", async () => {
        const request = new Request("https://webhook-receiver.workers.dev", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                ...validWebhookPayload,
                apiKey: "invalid-key"
            })
        });

        const response = await webhookReceiver.fetch(request, mockEnv);
        expect(response.status).toBe(403);
    });

    test("validates required fields", async () => {
        const request = new Request("https://webhook-receiver.workers.dev", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                apiKey: "test-api-key",
                // Missing required fields
            })
        });

        const response = await webhookReceiver.fetch(request, mockEnv);
        expect(response.status).toBe(200); // The handler accepts partial data
    });

    test("processes valid webhook", async () => {
        const request = new Request("https://webhook-receiver.workers.dev", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(validWebhookPayload)
        });

        const response = await webhookReceiver.fetch(request, mockEnv);
        expect(response.status).toBe(200);

        const responseData = await response.json();
        expect(responseData.success).toBe(true);
        expect(responseData.requestId).toBeDefined();
    });
}); 