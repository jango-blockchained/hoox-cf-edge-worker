# Cloudflare Worker TypeScript Template

This is a TypeScript-based Cloudflare Worker template with routing, CORS support, and error handling.

## Features

- TypeScript support
- Request routing with itty-router
- CORS middleware
- Error handling
- Environment variables support
- Type definitions for Cloudflare Workers
- Webpack bundling
- Jest testing setup
- ESLint and Prettier for code quality

## Prerequisites

- Node.js (v16 or later)
- npm or yarn
- Cloudflare account
- Wrangler CLI (`npm install -g wrangler`)

## Getting Started

1. Install dependencies:
```bash
npm install
```

2. Configure your environment:
   - Copy `wrangler.toml.example` to `wrangler.toml`
   - Update the configuration with your account details
   - Add your environment variables in the Cloudflare dashboard

3. Development:
```bash
npm run dev
```

4. Testing:
```bash
npm test
```

5. Production build:
```bash
npm run build
```

6. Deploy:
```bash
npm run publish
```

## API Endpoints

- `GET /`: Welcome message
- `GET /health`: Health check endpoint
- `GET /protected`: Protected endpoint (requires API key)

## Environment Variables

Configure these in your Cloudflare dashboard:

- `API_KEY`: Your API key for protected routes
- `DATABASE`: Optional D1 database binding
- `KV_STORE`: Optional KV namespace binding

## Development

### Adding New Routes

Add new routes in `src/index.ts`:

```typescript
router.get('/new-route', async (request: Request, env: Env) => {
  try {
    // Your route logic here
    return jsonResponse({ data: 'your data' });
  } catch (error) {
    return handleError(error as Error);
  }
});
```

### Testing

Add tests in the `test` directory. Example:

```typescript
import { describe, expect, it } from '@jest/globals';

describe('API', () => {
  it('should return welcome message', async () => {
    // Your test here
  });
});
```

## License

MIT 