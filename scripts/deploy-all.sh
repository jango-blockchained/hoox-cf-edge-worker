#!/bin/bash

# Deploy all workers
echo "Deploying webhook-receiver..."
cd ../webhook-receiver && npx wrangler deploy

echo "Deploying trade-worker..."
cd ../trade-worker && npx wrangler deploy

echo "Deploying telegram-worker..."
cd ../telegram-worker && npx wrangler deploy

echo "All workers deployed successfully!"
