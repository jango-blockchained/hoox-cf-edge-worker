# Crypto Trading System with Cloudflare Workers

> A secure, high-performance automated trading system that executes cryptocurrency grid trading strategies using serverless Cloudflare Workers. The system processes TradingView alerts through a webhook system, executes trades on cryptocurrency exchanges, and provides real-time notifications via Telegram.

This project implements a secure, serverless trading system using Cloudflare Workers to execute trades on cryptocurrency exchanges based on signals from TradingView alerts.

## Platform Requirements

This system is specifically designed for and requires Cloudflare Workers due to its use of Cloudflare-specific features:
- **D1 Database**: Used for logging and data persistence
- **Workers KV**: For caching and state management
- **Workers Secrets**: For secure credential management
- **Service bindings**: For secure worker-to-worker communication

While other serverless platforms like Vercel Edge Functions or AWS Lambda offer similar capabilities, porting this system would require significant architectural changes and loss of key features.

## Deployment Options

### Quick Deploy (Individual Workers)

Deploy each worker to your Cloudflare account with one click:

| Worker | Deploy Button |
|--------|--------------|
| D1 Worker | [![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/yourusername/grid-trading/tree/main/d1-worker) |
| Trade Worker | [![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/yourusername/grid-trading/tree/main/trade-worker) |
| Webhook Receiver | [![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/yourusername/grid-trading/tree/main/webhook-receiver) |
| Telegram Worker | [![Deploy to Cloudflare Workers](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/yourusername/grid-trading/tree/main/telegram-worker) |

### Alternative Deployment Methods

1. **Cloudflare Dashboard**
   ```bash
   # Build workers
   cd webhook-receiver && bun run build
   cd ../trade-worker && bun run build
   cd ../telegram-worker && bun run build
   cd ../d1-worker && bun run build
   
   # Upload the built workers through the Cloudflare Dashboard
   # https://dash.cloudflare.com/?to=/:account/workers/overview
   ```

2. **Wrangler CLI (Recommended for Teams/Enterprise)**
   ```bash
   # Deploy all workers with environment configuration
   ./scripts/deploy-all.sh
   ```

## Architecture

The system consists of four main components:

1. **Webhook Receiver**: Public-facing endpoint that receives TradingView webhook signals, validates them, and forwards to the appropriate workers
2. **Trade Worker**: Internal service that executes trades on cryptocurrency exchanges (Binance, MEXC, Bybit)
3. **Telegram Worker**: Internal service that sends notifications via Telegram
4. **D1 Worker**: Database service for logging and data persistence

### Communication Flow

```
TradingView Alert → Webhook Receiver → Trade Worker → Exchange API
                                     ↓
                               Telegram Worker
                                     ↓
                                 Telegram Bot
                                     
           Any Worker ←→ D1 Worker ←→ D1 Database
```

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

2. Create a D1 database:
   ```
   cd d1-worker
   wrangler d1 create grid-trading-db
   ```

3. Update the `database_id` in `d1-worker/wrangler.toml` with the ID from the previous command.

4. Set up secrets for each worker:
   ```
   # Webhook Receiver
   cd webhook-receiver
   wrangler secret put INTERNAL_SERVICE_KEY
   wrangler secret put API_SECRET_KEY
   
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
   
   # D1 Worker
   cd ../d1-worker
   wrangler secret put INTERNAL_SERVICE_KEY
   ```

5. Update worker URLs in `wrangler.toml` for each worker to point to your deployed worker URLs.

6. Deploy all workers:
   ```
   cd webhook-receiver && bun run deploy
   cd ../trade-worker && bun run deploy
   cd ../telegram-worker && bun run deploy
   cd ../d1-worker && bun run deploy
   ```

## Local Development

Local development requires running all workers on separate ports to avoid conflicts:

| Worker | Development Port |
|--------|-----------------|
| d1-worker | 8787 |
| trade-worker | 8788 |
| webhook-receiver | 8789 |
| telegram-worker | 8790 |

### Environment Variables

For local development, environment variables are loaded from `.dev.vars` files in each worker directory. Example `.dev.vars` file for the trade-worker:

```
INTERNAL_SERVICE_KEY=your_development_key
MEXC_API_KEY=your_mexc_key
MEXC_API_SECRET=your_mexc_secret
D1_WORKER_URL=http://localhost:8787
```

In production, environment variables are set through `wrangler.toml` or using `wrangler secret put`.

### Running Local Development Servers

Start each worker on its dedicated port:

```bash
# D1 Worker (use --local for local SQLite database)
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

## TradingView Setup

Configure a TradingView alert with the following webhook settings:

- **URL**: `https://webhook-receiver.your-domain.workers.dev`
- **Method**: POST
- **Body**:
  ```json
  {
    "apiKey": "your-api-secret-key",
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

## Worker Details

### Webhook Receiver
- Public-facing endpoint for TradingView
- Validates API key included in the JSON payload
- Routes requests to the appropriate worker
- Sends notifications via Telegram
- Current implementation in `webhook-receiver/src/index.js`

### Trade Worker
- Executes trades on multiple exchanges (MEXC, Binance, Bybit)
- Only accepts authenticated requests from the webhook receiver
- Handles various trade actions (LONG, SHORT, CLOSE_LONG, CLOSE_SHORT)
- Logs requests and responses to D1 database (if enabled)
- Exchange-specific client implementations in separate files
- Current implementation in `trade-worker/src/index.js`

### Telegram Worker
- Sends notifications to Telegram
- Only accepts authenticated requests from the webhook receiver
- Supports HTML formatting for messages
- Current implementation in `telegram-worker/src/index.js`

### D1 Worker
- Provides centralized database operations
- Stores trade requests and responses
- Supports SQL queries and batch operations
- Secure API with authentication
- Current implementation in `d1-worker/src/index.js`
