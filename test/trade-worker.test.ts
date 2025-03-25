import { describe, expect, test, beforeEach, mock } from "bun:test";
import tradeWorker from "../trade-worker/src/index.js";

describe("Trade Worker", () => {
    const mockEnv = {
        INTERNAL_SERVICE_KEY: "test-internal-key",
        MEXC_API_KEY: "test-mexc-key",
        MEXC_API_SECRET: "test-mexc-secret"
    };

    const validTradeRequest = {
        exchange: "mexc",
        action: "LONG",
        symbol: "BTC_USDT",
        quantity: 0.1,
        price: 50000,
        leverage: 20
    };

    beforeEach(() => {
        // Mock MEXC API calls
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
        const request = new Request("https://trade-worker.workers.dev", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "invalid-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validTradeRequest)
        });

        const response = await tradeWorker.fetch(request, mockEnv);
        expect(response.status).toBe(403);
    });

    test("executes long position", async () => {
        global.fetch = mock(() =>
            Promise.resolve(new Response(
                JSON.stringify({ success: true, orderId: "123456" }),
                {
                    status: 200,
                    headers: { "Content-Type": "application/json" }
                }
            ))
        );

        const request = new Request("https://trade-worker.workers.dev", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validTradeRequest)
        });

        const response = await tradeWorker.fetch(request, mockEnv);
        expect(response.status).toBe(200);

        const responseData = await response.json();
        expect(responseData.success).toBe(true);
        expect(responseData.requestId).toBeDefined();
    });

    test("handles MEXC API errors", async () => {
        global.fetch = mock(() => Promise.reject(new Error("MEXC API Error")));

        const request = new Request("https://trade-worker.workers.dev", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validTradeRequest)
        });

        const response = await tradeWorker.fetch(request, mockEnv);
        expect(response.status).toBe(500);
    });
}); 