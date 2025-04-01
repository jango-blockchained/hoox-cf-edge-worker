#!/bin/bash

# Script to check status of all workers without interactive TUI
# For use in CI/CD pipelines or when stdin is not available

# Colors for better terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Navigate to the worker directory
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo -e "${YELLOW}Hoox Trading System Status${NC}\n"

# Check status of each worker
check_worker() {
  local worker_name=$1
  local port=$2
  local pid=$(pgrep -f "bun run dev -- --port $port")

  if [ -n "$pid" ]; then
    echo -e "${GREEN}✓ ${worker_name}: Running (PID: $pid, Port: $port)${NC}"
    return 0
  else
    echo -e "${RED}✗ ${worker_name}: Stopped${NC}"
    return 1
  fi
}

# Check all workers
check_worker "D1 Worker" 8787
check_worker "Trade Worker" 8788
check_worker "Webhook Receiver" 8789
check_worker "Telegram Worker" 8790

# Return to previous directory
cd - > /dev/null 