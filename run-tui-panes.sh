#!/bin/bash

# Enhanced script for running Hoox Trading System TUI (Panes) with tsx

# Go to the script directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Ensure we're in a TTY-capable environment
if [ ! -t 0 ]; then
  echo "Error: This TUI requires an interactive terminal."
  echo "Please run it directly in a terminal window."
  exit 1
fi

# Make the necessary scripts executable
chmod +x ./hoox-tui
chmod +x ./scripts/tui.sh
chmod +x ./hoox-tui.js
chmod +x ./hoox-tui-panes.js # Make the new script executable

# Run the TUI application using tsx, redirecting stdin from the TTY
# tsx handles JSX/TS compilation on the fly
./node_modules/.bin/tsx ./hoox-tui-panes.js < /dev/tty

echo "TUI (Panes) terminated." 