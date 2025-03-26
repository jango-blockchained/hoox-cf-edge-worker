import { describe, expect, it } from '@jest/globals';
import worker from '../src/index';

describe('Worker', () => {
    const env = {
        API_KEY: 'test-key',
    };

    const ctx = {
        waitUntil: () => { },
        passThroughOnException: () => { },
    };

    it('should return welcome message for root path', async () => {
        const req = new Request('http://localhost/');
        const res = await worker.fetch(req, env, ctx);
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data).toEqual({ message: 'Welcome to the API' });
    });

    it('should return health status', async () => {
        const req = new Request('http://localhost/health');
        const res = await worker.fetch(req, env, ctx);
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data).toEqual({ status: 'healthy' });
    });

    it('should require authentication for protected route', async () => {
        const req = new Request('http://localhost/protected');
        const res = await worker.fetch(req, env, ctx);
        const data = await res.json();

        expect(res.status).toBe(401);
        expect(data).toEqual({ error: 'Unauthorized' });
    });

    it('should allow access to protected route with valid token', async () => {
        const req = new Request('http://localhost/protected', {
            headers: {
                'Authorization': `Bearer ${env.API_KEY}`,
            },
        });
        const res = await worker.fetch(req, env, ctx);
        const data = await res.json();

        expect(res.status).toBe(200);
        expect(data).toEqual({ message: 'Protected data' });
    });

    it('should return 404 for unknown routes', async () => {
        const req = new Request('http://localhost/unknown');
        const res = await worker.fetch(req, env, ctx);
        const data = await res.json();

        expect(res.status).toBe(404);
        expect(data).toEqual({ error: 'Not Found' });
    });
}); 