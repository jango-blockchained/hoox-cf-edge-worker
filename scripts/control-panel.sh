#!/bin/bash

# Colors for better UI
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ANSI escape sequences for cursor control
CLEAR_SCREEN='\033[2J'
CURSOR_HOME='\033[H'

# Define session name
SESSION_NAME="hoox-trading"

# Store worker PIDs for control
d1_worker_pid=""
trade_worker_pid=""
webhook_receiver_pid=""
telegram_worker_pid=""

# Function to display menu
show_menu() {
    echo -e "${CLEAR_SCREEN}${CURSOR_HOME}"
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "${CYAN}           Hoox Trading System Control Panel           ${NC}"
    echo -e "${CYAN}=======================================================${NC}"
    echo -e ""
    echo -e "${YELLOW}Worker Status:${NC}"
    
    # Get status of each worker
    if tmux list-panes -t $SESSION_NAME -F '#{pane_title}' 2>/dev/null | grep -q "d1-worker"; then
        echo -e "  D1 Worker:         ${GREEN}Running${NC} (Port 8787)"
    else
        echo -e "  D1 Worker:         ${RED}Stopped${NC}"
    fi
    
    if tmux list-panes -t $SESSION_NAME -F '#{pane_title}' 2>/dev/null | grep -q "trade-worker"; then
        echo -e "  Trade Worker:      ${GREEN}Running${NC} (Port 8788)"
    else
        echo -e "  Trade Worker:      ${RED}Stopped${NC}"
    fi
    
    if tmux list-panes -t $SESSION_NAME -F '#{pane_title}' 2>/dev/null | grep -q "webhook-receiver"; then
        echo -e "  Webhook Receiver:  ${GREEN}Running${NC} (Port 8789)"
    else
        echo -e "  Webhook Receiver:  ${RED}Stopped${NC}"
    fi
    
    if tmux list-panes -t $SESSION_NAME -F '#{pane_title}' 2>/dev/null | grep -q "telegram-worker"; then
        echo -e "  Telegram Worker:   ${GREEN}Running${NC} (Port 8790)"
    else
        echo -e "  Telegram Worker:   ${RED}Stopped${NC}"
    fi
    
    echo -e ""
    echo -e "${YELLOW}Available Commands:${NC}"
    echo -e "  ${BLUE}[1]${NC} - Start All Workers"
    echo -e "  ${BLUE}[2]${NC} - Stop All Workers"
    echo -e "  ${BLUE}[3]${NC} - Restart All Workers"
    echo -e "  ${BLUE}[4]${NC} - Start D1 Worker"
    echo -e "  ${BLUE}[5]${NC} - Start Trade Worker"
    echo -e "  ${BLUE}[6]${NC} - Start Webhook Receiver"
    echo -e "  ${BLUE}[7]${NC} - Start Telegram Worker"
    echo -e "  ${BLUE}[8]${NC} - Stop D1 Worker"
    echo -e "  ${BLUE}[9]${NC} - Stop Trade Worker"
    echo -e "  ${BLUE}[10]${NC} - Stop Webhook Receiver"
    echo -e "  ${BLUE}[11]${NC} - Stop Telegram Worker"
    echo -e "  ${BLUE}[r]${NC} - Refresh Status"
    echo -e "  ${BLUE}[q]${NC} - Quit (Stop All Workers and Exit)"
    echo -e ""
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "${YELLOW}Enter your choice: ${NC}"
}

# Function to start a specific worker
start_worker() {
    local worker_name=$1
    local port=$2
    local extra_args=$3
    
    # Check if the worker is already running
    if tmux list-panes -t $SESSION_NAME -F '#{pane_title}' 2>/dev/null | grep -q "$worker_name"; then
        echo -e "${YELLOW}${worker_name} is already running.${NC}"
        read -n 1 -s -p "Press any key to continue..."
        return
    fi
    
    # Create a new pane for the worker
    tmux split-window -t $SESSION_NAME
    tmux select-pane -t $SESSION_NAME:0.$(($(tmux list-panes -t $SESSION_NAME | wc -l) - 1))
    tmux send-keys "echo -e '${GREEN}Starting ${worker_name} on port ${port}...${NC}'" C-m
    tmux send-keys "cd workers/${worker_name} && bun run dev -- --port ${port} ${extra_args}" C-m
    
    echo -e "${GREEN}${worker_name} started on port ${port}.${NC}"
    read -n 1 -s -p "Press any key to continue..."
}

# Function to stop a specific worker
stop_worker() {
    local worker_name=$1
    
    # Find the pane running the worker
    local pane_id=$(tmux list-panes -t $SESSION_NAME -F '#{pane_id}:#{pane_title}' 2>/dev/null | grep "$worker_name" | cut -d':' -f1)
    
    if [ -n "$pane_id" ]; then
        tmux send-keys -t $pane_id C-c
        sleep 1
        tmux kill-pane -t $pane_id
        echo -e "${GREEN}${worker_name} stopped.${NC}"
    else
        echo -e "${YELLOW}${worker_name} is not running.${NC}"
    fi
    
    read -n 1 -s -p "Press any key to continue..."
}

# Function to stop and exit
stop_and_exit() {
    # Kill the tmux session which will stop all workers
    tmux kill-session -t $SESSION_NAME
    exit 0
}

# Main loop for user input
while true; do
    show_menu
    read -n 2 choice
    
    case $choice in
        1)  # Start All Workers
            tmux kill-session -t $SESSION_NAME 2>/dev/null
            bash scripts/dev-start.sh
            ;;
        2)  # Stop All Workers
            for pane in $(tmux list-panes -t $SESSION_NAME -F '#{pane_id}' 2>/dev/null); do
                tmux send-keys -t $pane C-c
            done
            echo -e "${GREEN}All workers stopped.${NC}"
            read -n 1 -s -p "Press any key to continue..."
            ;;
        3)  # Restart All Workers
            for pane in $(tmux list-panes -t $SESSION_NAME -F '#{pane_id}' 2>/dev/null); do
                tmux send-keys -t $pane C-c
            done
            sleep 2
            bash scripts/dev-start.sh
            ;;
        4)  # Start D1 Worker
            start_worker "d1-worker" "8787" "--local"
            ;;
        5)  # Start Trade Worker
            start_worker "trade-worker" "8788" ""
            ;;
        6)  # Start Webhook Receiver
            start_worker "webhook-receiver" "8789" ""
            ;;
        7)  # Start Telegram Worker
            start_worker "telegram-worker" "8790" ""
            ;;
        8)  # Stop D1 Worker
            stop_worker "d1-worker"
            ;;
        9)  # Stop Trade Worker
            stop_worker "trade-worker"
            ;;
        10) # Stop Webhook Receiver
            stop_worker "webhook-receiver"
            ;;
        11) # Stop Telegram Worker
            stop_worker "telegram-worker"
            ;;
        r|R) # Refresh status - do nothing, the loop will refresh
            ;;
        q|Q) # Quit
            stop_and_exit
            ;;
        *)  # Invalid option
            echo -e "${RED}Invalid option. Please try again.${NC}"
            read -n 1 -s -p "Press any key to continue..."
            ;;
    esac
done 