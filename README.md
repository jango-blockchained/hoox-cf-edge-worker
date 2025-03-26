# Crypto Trading System with Cloudflare Workers

> A secure, high-performance automated trading system that executes cryptocurrency grid trading strategies using serverless Cloudflare Workers. The system processes TradingView alerts through a webhook system, executes trades on MEXC exchange, and provides real-time notifications via Telegram.

This project implements a secure, serverless trading system using Cloudflare Workers to execute trades on cryptocurrency exchanges based on signals from TradingView alerts.

## Architecture

The system consists of four main components:

1. **Webhook Receiver**: Public-facing endpoint that receives TradingView webhook signals
2. **Trade Worker**: Internal service that executes trades on cryptocurrency exchanges
3. **Telegram Worker**: Internal service that sends notifications via Telegram
4. **D1 Worker**: Database service for logging and data persistence

## Setup Instructions

### Prerequisites

- Cloudflare account
- Node.js and npm
- Bun (for package management)
- Wrangler CLI (`npm install -g wrangler`)

### Installation

1. Install dependencies for each worker:
   ```
   cd webhook-receiver && bun install
   cd ../trade-worker && bun install
   cd ../telegram-worker && bun install
   cd ../d1-worker && bun install
   ```

2. Generate secure API keys:
   ```
   node scripts/generate-api-key.js
   ```

3. Set up secrets for each worker:
   ```
   # Webhook Receiver
   cd webhook-receiver
   wrangler secret put API_SECRET_KEY
   wrangler secret put INTERNAL_SERVICE_KEY
   
   # Trade Worker
   cd ../trade-worker
   wrangler secret put INTERNAL_SERVICE_KEY
   wrangler secret put MEXC_API_KEY
   wrangler secret put MEXC_API_SECRET
   wrangler secret put BINANCE_API_KEY
   wrangler secret put BINANCE_API_SECRET
   wrangler secret put BYBIT_API_KEY
   wrangler secret put BYBIT_API_SECRET
   
   # Telegram Worker
   cd ../telegram-worker
   wrangler secret put INTERNAL_SERVICE_KEY
   wrangler secret put TELEGRAM_BOT_TOKEN
   wrangler secret put ALLOWED_CHAT_IDS
   
   # D1 Worker
   cd ../d1-worker
   wrangler secret put INTERNAL_SERVICE_KEY
   ```

4. Deploy all workers:
   ```
   ./scripts/deploy-all.sh
   ```

## Local Development

Each worker requires its own port for local development to avoid conflicts:

| Worker | Development Port |
|--------|-----------------|
| d1-worker | 8787 |
| trade-worker | 8788 |
| webhook-receiver | 8789 |
| telegram-worker | 8790 |

### Environment Variables

For local development, environment variables are loaded from `.dev.vars` files in each worker directory:

```bash
# Example for trade-worker/.dev.vars
INTERNAL_SERVICE_KEY=your_development_key
MEXC_API_KEY=your_mexc_key
MEXC_API_SECRET=your_mexc_secret
D1_WORKER_URL=http://localhost:8787
```

In production, environment variables are set through `wrangler.toml` or using `wrangler secret put`.

### Running Local Development Servers

Start each worker on its dedicated port:

```bash
# D1 Worker
cd d1-worker
bun run dev -- --port 8787 --local

# Trade Worker
cd ../trade-worker
bun run dev -- --port 8788

# Webhook Receiver
cd ../webhook-receiver
bun run dev -- --port 8789

# Telegram Worker
cd ../telegram-worker
bun run dev -- --port 8790
```

For D1 database operations, you can use the `--local` flag to use a local SQLite database instead of connecting to your Cloudflare D1 database.

## TradingView Setup

Configure a TradingView alert with the following webhook settings:

- **URL**: `https://webhook-receiver.your-domain.workers.dev`
- **Method**: POST
- **Body**:
  ```json
  {
    "apiKey": "your-generated-api-key",
    "exchange": "mexc",
    "action": "LONG",
    "symbol": "BTC_USDT",
    "quantity": {{strategy.order.contracts}},
    "price": {{close}},
    "leverage": 20,
    "notify": {
      "message": "⚠️ BTC Grid Signal: {{strategy.order.action}} at {{close}}",
      "chatId": 123456789
    }
  }
  ```

## Security Considerations

- Use strong, randomly generated API keys
- Set up rate limiting on your Cloudflare account
- Implement IP access rules to restrict webhook access
- Rotate API keys periodically

## Important Notes for TradingView Webhooks

- TradingView webhooks can only send plain JSON data in the request body
- They cannot add custom HTTP headers
- Only standard HTTP ports (80/443) are supported

## Worker Details

### Webhook Receiver
- Public-facing endpoint for TradingView
- Validates API key included in the JSON payload
- Routes requests to the appropriate worker

### Trade Worker
- Executes trades on multiple exchanges (MEXC, Binance, Bybit)
- Only accepts authenticated requests from the webhook receiver
- Handles various trade actions (LONG, SHORT, CLOSE_LONG, CLOSE_SHORT)
- Logs requests and responses to D1 database (if enabled)

### Telegram Worker
- Sends notifications to Telegram
- Only accepts authenticated requests from the webhook receiver
- Supports custom message formatting
- Handles bot commands and interactions

### D1 Worker
- Provides centralized database operations
- Stores trade requests and responses
- Supports SQL queries and batch operations
- Secure API with authentication
