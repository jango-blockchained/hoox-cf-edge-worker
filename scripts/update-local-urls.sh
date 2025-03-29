#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=======================================${NC}"
echo -e "${YELLOW}  Update Worker URLs for Local Dev     ${NC}"
echo -e "${YELLOW}=======================================${NC}"
echo

# Define the default ports for each worker
declare -A default_ports=(
    ["d1-worker"]=8787
    ["trade-worker"]=8788
    ["webhook-receiver"]=8789
    ["telegram-worker"]=8790
)

# Navigate to the root directory
cd "$(dirname "$0")/.." || {
    echo -e "${RED}Error: Could not navigate to the root directory.${NC}"
    exit 1
}

# Get list of all worker directories
worker_dirs=$(find workers -maxdepth 1 -type d -not -path "workers" | sort)
worker_names=()

# First pass: Get all worker information
echo -e "${BLUE}Checking worker configurations...${NC}"
for worker_path in $worker_dirs; do
    # Extract just the worker name from the path
    worker_name=$(basename "$worker_path")
    worker_names+=("$worker_name")
    
    # Check if wrangler.toml exists
    if [ ! -f "$worker_path/wrangler.toml" ]; then
        echo -e "${RED}Error: wrangler.toml not found in $worker_path${NC}"
        exit 1
    fi
    
    # Display default port
    port="${default_ports[$worker_name]}"
    echo -e "Worker: ${YELLOW}$worker_name${NC} -> Default Port: ${BLUE}$port${NC}"
done

echo
# Confirm default ports or allow customization
read -p "Do you want to use these default ports? (y/n): " use_defaults
if [[ "$use_defaults" != "y" && "$use_defaults" != "Y" ]]; then
    echo -e "${YELLOW}Let's customize the ports:${NC}"
    for i in "${!worker_names[@]}"; do
        worker_name="${worker_names[$i]}"
        default_port="${default_ports[$worker_name]}"
        read -p "Enter port for $worker_name [$default_port]: " custom_port
        if [ -n "$custom_port" ]; then
            default_ports["$worker_name"]="$custom_port"
        fi
    done
    
    echo -e "\n${BLUE}Updated port configuration:${NC}"
    for worker_name in "${worker_names[@]}"; do
        echo -e "Worker: ${YELLOW}$worker_name${NC} -> Port: ${BLUE}${default_ports[$worker_name]}${NC}"
    done
    
    # Final confirmation
    echo
    read -p "Proceed with these settings? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi
fi

# Map to store worker URLs for cross-references
declare -A worker_urls

# Populate the map with URLs
for worker_name in "${worker_names[@]}"; do
    port="${default_ports[$worker_name]}"
    worker_urls["$worker_name"]="http://localhost:$port"
done

# Now update .dev.vars files
echo -e "\n${BLUE}Updating worker configurations...${NC}"

for worker_name in "${worker_names[@]}"; do
    worker_path="workers/$worker_name"
    DEV_VARS_FILE="$worker_path/.dev.vars"
    
    echo -e "\n${BLUE}Configuring worker: ${YELLOW}$worker_name${NC}"
    
    # Check if .dev.vars exists, create if not
    if [ ! -f "$DEV_VARS_FILE" ]; then
        touch "$DEV_VARS_FILE"
    fi
    
    # Check for dependencies on other workers and update URLs
    needs_update=false
    
    # Scan wrangler.toml for vars referencing other workers
    toml_file="$worker_path/wrangler.toml"
    
    # Check for references to other workers in vars section
    if grep -q "\[vars\]" "$toml_file"; then
        for other_worker in "${worker_names[@]}"; do
            # Skip self-references
            if [ "$other_worker" == "$worker_name" ]; then
                continue
            fi
            
            # Check if this worker references the other worker in uppercase format (e.g., TRADE_WORKER_URL)
            uppercase_var=$(echo "${other_worker}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
            var_name="${uppercase_var}_URL"
            
            if grep -q "$var_name" "$toml_file"; then
                new_url="${worker_urls[$other_worker]}"
                echo "Setting $var_name to $new_url in .dev.vars"
                
                # Update or add the URL in the .dev.vars file
                if grep -q "^$var_name=" "$DEV_VARS_FILE"; then
                    # Update existing entry
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        # macOS uses BSD sed
                        sed -i '' "s|^$var_name=.*|$var_name=$new_url|g" "$DEV_VARS_FILE"
                    else
                        # Linux uses GNU sed
                        sed -i "s|^$var_name=.*|$var_name=$new_url|g" "$DEV_VARS_FILE"
                    fi
                else
                    # Add new entry
                    echo "$var_name=$new_url" >> "$DEV_VARS_FILE"
                fi
                
                needs_update=true
            fi
        done
    fi
    
    if [ "$needs_update" = true ]; then
        echo -e "${GREEN}✅ Updated URLs in .dev.vars for $worker_name${NC}"
    else
        echo -e "${GREEN}No URL updates needed for $worker_name${NC}"
    fi
done

echo -e "\n${GREEN}✅ Local URL configuration completed!${NC}"
echo -e "${YELLOW}IMPORTANT: These URLs are now configured for local development:${NC}"

for worker_name in "${worker_names[@]}"; do
    echo -e "${YELLOW}${worker_name}${NC}: ${GREEN}${worker_urls[$worker_name]}${NC}"
done

echo -e "\n${BLUE}Note: To use these settings, restart your workers with 'scripts/dev-start.sh'${NC}" 