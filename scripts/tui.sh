#!/bin/bash

# Check if running in a terminal
if [ ! -t 0 ]; then
  echo "Error: This TUI application must be run in an interactive terminal."
  echo "Try running it directly in your terminal with:"
  echo "  ./hoox-tui"
  exit 1
fi

# Navigate to the worker directory
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Make sure we have required permissions
if [ -e /dev/stdin ]; then
  # On Linux/macOS, ensure stdin is readable
  if [ ! -r /dev/stdin ]; then
    echo "Warning: Unable to read from stdin. Interactive features may not work."
  fi
fi

# Run the TUI with explicit stdin
exec < /dev/tty
bun run tui

# Return to previous directory
cd - > /dev/null 