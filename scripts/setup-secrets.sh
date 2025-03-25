#!/bin/bash

# Function to set secrets for a worker
set_worker_secrets() {
    local worker_name=$1
    shift
    local secrets=("$@")
    
    echo "Setting secrets for $worker_name..."
    cd "$worker_name" || exit 1
    
    for secret in "${secrets[@]}"; do
        echo "Setting $secret..."
        read -p "Enter value for $secret: " secret_value
        bunx wrangler secret put "$secret" <<< "$secret_value"
    done
    
    cd ..
    echo "✅ Completed setting secrets for $worker_name"
    echo
}

# Main script
echo "🔐 Starting secrets setup for all workers..."

# Webhook Receiver secrets
webhook_secrets=("API_SECRET_KEY" "INTERNAL_SERVICE_KEY")
set_worker_secrets "webhook-receiver" "${webhook_secrets[@]}"

# Telegram Worker secrets
telegram_secrets=("INTERNAL_SERVICE_KEY" "TELEGRAM_BOT_TOKEN" "TELEGRAM_CHAT_ID")
set_worker_secrets "telegram-worker" "${telegram_secrets[@]}"

# Trade Worker secrets
trade_secrets=("INTERNAL_SERVICE_KEY" "MEXC_API_KEY" "MEXC_API_SECRET")
set_worker_secrets "trade-worker" "${trade_secrets[@]}"

echo "✨ All secrets have been configured!" 