#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ANSI escape sequences for cursor control and screen management
CLEAR_SCREEN='\033[2J'
CURSOR_HOME='\033[H'

# Define the session name
SESSION_NAME="grid-trading"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}tmux is not installed. Please install it first.${NC}"
    echo "For Ubuntu/Debian: sudo apt-get install tmux"
    echo "For macOS with Homebrew: brew install tmux"
    exit 1
fi

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo -e "${RED}bun is not installed. Please install it first.${NC}"
    echo "Visit https://bun.sh for installation instructions"
    exit 1
fi

# Kill an existing session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null

# Create a new session
tmux new-session -d -s $SESSION_NAME

# Split the window for the D1 Worker
tmux split-window -h -t $SESSION_NAME
tmux select-pane -t 0
tmux send-keys "echo -e '${GREEN}Starting D1 Worker on port 8787...${NC}'" C-m
tmux send-keys "cd workers/d1-worker && bun run dev -- --port 8787 --local" C-m

# Split for Trade Worker
tmux split-window -v -t $SESSION_NAME
tmux select-pane -t 1
tmux send-keys "echo -e '${GREEN}Starting Trade Worker on port 8788...${NC}'" C-m
tmux send-keys "cd workers/trade-worker && bun run dev -- --port 8788" C-m

# Split for Webhook Receiver
tmux split-window -v -t $SESSION_NAME
tmux select-pane -t 2
tmux send-keys "echo -e '${GREEN}Starting Webhook Receiver on port 8789...${NC}'" C-m
tmux send-keys "cd workers/webhook-receiver && bun run dev -- --port 8789" C-m

# Split for Telegram Worker
tmux select-pane -t 0
tmux split-window -v -t $SESSION_NAME
tmux select-pane -t 1
tmux send-keys "echo -e '${GREEN}Starting Telegram Worker on port 8790...${NC}'" C-m
tmux send-keys "cd workers/telegram-worker && bun run dev -- --port 8790" C-m

# Create a control panel in a separate pane
tmux select-pane -t 3
tmux split-window -v -t $SESSION_NAME
tmux select-pane -t 4
tmux send-keys "clear" C-m
tmux send-keys "bash scripts/control-panel.sh" C-m

# Adjust layout
tmux select-layout tiled

# Attach to the session
tmux attach-session -t $SESSION_NAME

exit 0 