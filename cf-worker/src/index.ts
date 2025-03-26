import { Router } from 'itty-router';
import { Env, ApiResponse } from './types';

// Create a new router
const router = Router();

// Middleware to handle CORS
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
};

// Helper function to handle responses
const jsonResponse = <T>(data: T, status: number = 200): Response => {
    return new Response(JSON.stringify(data), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
        },
    });
};

// Error handler
const handleError = (error: Error): Response => {
    console.error('Error:', error);
    return jsonResponse({ error: error.message }, 500);
};

// Routes
router.get('/', () => {
    return jsonResponse({ message: 'Welcome to the API' });
});

// Health check endpoint
router.get('/health', () => {
    return jsonResponse({ status: 'healthy' });
});

// Example protected route
router.get('/protected', async (request: Request, env: Env) => {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader || authHeader !== `Bearer ${env.API_KEY}`) {
            return jsonResponse({ error: 'Unauthorized' }, 401);
        }

        return jsonResponse({ message: 'Protected data' });
    } catch (error) {
        return handleError(error as Error);
    }
});

// Handle OPTIONS requests for CORS
router.options('*', () => {
    return new Response(null, {
        headers: corsHeaders,
    });
});

// 404 for everything else
router.all('*', () => jsonResponse({ error: 'Not Found' }, 404));

// Export the worker
export default {
    async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
        try {
            // Handle the request with the router
            return router.handle(request, env, ctx);
        } catch (error) {
            return handleError(error as Error);
        }
    },
}; 