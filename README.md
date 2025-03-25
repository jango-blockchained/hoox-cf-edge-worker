# Crypto Trading System with Cloudflare Workers

This project implements a secure, serverless trading system using Cloudflare Workers to execute trades on cryptocurrency exchanges based on signals from TradingView alerts.

## Architecture

The system consists of three main components:

1. **Webhook Receiver**: Public-facing endpoint that receives TradingView webhook signals
2. **Trade Worker**: Internal service that executes trades on cryptocurrency exchanges
3. **Telegram Worker**: Internal service that sends notifications via Telegram

## Setup Instructions

### Prerequisites

- Cloudflare account
- Node.js and npm
- Wrangler CLI (`npm install -g wrangler`)

### Installation

1. Install dependencies for each worker:
   ```
   cd webhook-receiver && npm install
   cd ../trade-worker && npm install
   cd ../telegram-worker && npm install
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
   
   # Telegram Worker
   cd ../telegram-worker
   wrangler secret put INTERNAL_SERVICE_KEY
   wrangler secret put TELEGRAM_BOT_TOKEN
   ```

4. Deploy all workers:
   ```
   ./scripts/deploy-all.sh
   ```

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
- Executes trades on MEXC
- Only accepts authenticated requests from the webhook receiver
- Handles various trade actions (LONG, SHORT, CLOSE_LONG, CLOSE_SHORT)

### Telegram Worker
- Sends notifications to Telegram
- Only accepts authenticated requests from the webhook receiver
- Supports custom message formatting
