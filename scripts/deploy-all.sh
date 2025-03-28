#!/bin/bash

# Function to deploy a worker
deploy_worker() {
    local worker_name=$1
    echo "Deploying $worker_name..."
    cd "workers/$worker_name" || exit 1
    
    # Check if wrangler.toml exists
    if [ ! -f wrangler.toml ]; then
        echo "Error: wrangler.toml not found in workers/$worker_name"
        cd ../..
        return 1
    }
    
    # Deploy using wrangler
    echo "Running wrangler deploy for $worker_name..."
    bunx wrangler deploy
    
    # Check deployment status
    if [ $? -eq 0 ]; then
        echo "✅ Successfully deployed $worker_name"
    else
        echo "❌ Failed to deploy $worker_name"
    fi
    
    cd ../..
}

# Main script
echo "🚀 Starting deployment of all workers..."

# Deploy each worker
deploy_worker "webhook-receiver"
deploy_worker "telegram-worker"
deploy_worker "trade-worker"

echo "✨ Deployment process completed!"
