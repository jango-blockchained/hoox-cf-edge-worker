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
    fi
    
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

# Get list of all directories in the workers folder
worker_dirs=$(find workers -maxdepth 1 -type d -not -path "workers" | sort)

# Loop through and deploy each worker
for worker_path in $worker_dirs; do
    # Extract just the worker name from the path
    worker_name=$(basename "$worker_path")
    deploy_worker "$worker_name"
done

echo "✨ Deployment process completed!"
