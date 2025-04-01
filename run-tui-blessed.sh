#!/bin/bash

# Script for running Hoox Trading System TUI (Blessed version)

# Go to the script directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# Ensure we're in a TTY-capable environment
if [ ! -t 0 ]; then
  echo "Error: This TUI requires an interactive terminal."
  echo "Please run it directly in a terminal window."
  exit 1
fi

# Make the script executable (optional, but good practice)
chmod +x ./src/tui/app_blessed.js

# Run the TUI application directly with node, redirecting stdin from the TTY
node ./src/tui/app_blessed.js < /dev/tty

echo "TUI (Blessed) terminated." 