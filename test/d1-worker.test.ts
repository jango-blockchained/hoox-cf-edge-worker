import { describe, expect, test, beforeEach, mock } from "bun:test";
import d1Worker from "../workers/d1-worker/src/index.js";

describe("D1 Worker", () => {
    // Mock D1 database prepared statement and response
    const mockPreparedStatement = {
        bind: mock(() => mockPreparedStatement),
        run: mock(() => Promise.resolve({
            meta: {
                last_row_id: 123,
                changes: 1
            }
        })),
        all: mock(() => Promise.resolve({
            results: [{ id: 1, name: "test" }]
        }))
    };

    // Mock D1 database
    const mockDB = {
        prepare: mock(() => mockPreparedStatement),
        batch: mock((statements) => ({
            run: mock(() => Promise.resolve([
                { meta: { last_row_id: 123, changes: 1 } },
                { meta: { changes: 1 } }
            ]))
        }))
    };

    const mockEnv = {
        INTERNAL_SERVICE_KEY: "test-internal-key",
        DB: mockDB
    };

    // Valid query request payload
    const validQueryRequest = {
        query: "SELECT * FROM trade_requests WHERE id = ?",
        params: [123]
    };

    // Valid batch request payload
    const validBatchRequest = {
        statements: [
            {
                query: "INSERT INTO trade_requests (method, path) VALUES (?, ?)",
                params: ["POST", "/trade"]
            },
            {
                query: "UPDATE trade_responses SET error = ? WHERE request_id = ?",
                params: ["Connection timeout", 123]
            }
        ]
    };

    test("validates internal service key", async () => {
        const request = new Request("https://d1-worker.workers.dev/query", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "invalid-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validQueryRequest)
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(403);
    });

    test("validates request ID", async () => {
        const request = new Request("https://d1-worker.workers.dev/query", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                // Missing X-Request-ID
            },
            body: JSON.stringify(validQueryRequest)
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(403);
    });

    test("returns 404 for unknown endpoint", async () => {
        const request = new Request("https://d1-worker.workers.dev/unknown", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validQueryRequest)
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(404);
    });

    test("handles SELECT query", async () => {
        const request = new Request("https://d1-worker.workers.dev/query", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify({
                query: "SELECT * FROM trade_requests",
                params: []
            })
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(200);

        const responseData = await response.json();
        expect(responseData.success).toBe(true);
        expect(responseData.results).toBeDefined();
    });

    test("handles INSERT query", async () => {
        const request = new Request("https://d1-worker.workers.dev/query", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify({
                query: "INSERT INTO trade_requests (method, path) VALUES (?, ?)",
                params: ["POST", "/trade"]
            })
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(200);

        const responseData = await response.json();
        expect(responseData.success).toBe(true);
        expect(responseData.lastRowId).toBeDefined();
        expect(responseData.changes).toBeDefined();
    });

    test("handles batch operations", async () => {
        const request = new Request("https://d1-worker.workers.dev/batch", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validBatchRequest)
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(200);

        const responseData = await response.json();
        expect(responseData.success).toBe(true);
        expect(responseData.results).toBeDefined();
    });

    test("rejects unsupported methods", async () => {
        const request = new Request("https://d1-worker.workers.dev/query", {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            }
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(405);
    });

    test("handles database errors", async () => {
        // Override the mock to simulate a database error
        mockDB.prepare = mock(() => {
            throw new Error("Database error");
        });

        const request = new Request("https://d1-worker.workers.dev/query", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-Internal-Key": "test-internal-key",
                "X-Request-ID": "test-request-id"
            },
            body: JSON.stringify(validQueryRequest)
        });

        const response = await d1Worker.fetch(request, mockEnv);
        expect(response.status).toBe(500);

        const responseData = await response.json();
        expect(responseData.success).toBe(false);
        expect(responseData.error).toBeDefined();
    });
}); 