#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${BLUE}=== Running tests for all workers ===${RESET}\n"

# Check if --coverage flag is passed
COVERAGE_FLAG=""
WATCH_FLAG=""

for arg in "$@"; do
  if [ "$arg" == "--coverage" ]; then
    COVERAGE_FLAG="--coverage"
  fi
  if [ "$arg" == "--watch" ]; then
    WATCH_FLAG="--watch"
  fi
done

# Track exit status
EXIT_STATUS=0

# Run tests for each worker
for worker in workers/*; do
  if [ -d "$worker" ]; then
    WORKER_NAME=$(basename "$worker")
    echo -e "${YELLOW}Testing $WORKER_NAME...${RESET}"
    
    # Check if test directory exists
    if [ -d "$worker/test" ]; then
      cd "$worker"
      
      # Check if bun is installed
      if ! command -v bun &> /dev/null; then
        echo -e "${RED}Bun is not installed. Please install it first.${RESET}"
        exit 1
      fi
      
      # Run tests with the specified flags
      bun test $COVERAGE_FLAG $WATCH_FLAG
      
      # Capture the exit status
      WORKER_STATUS=$?
      
      if [ $WORKER_STATUS -ne 0 ]; then
        EXIT_STATUS=1
        echo -e "${RED}$WORKER_NAME tests failed${RESET}"
      else
        echo -e "${GREEN}$WORKER_NAME tests passed${RESET}"
      fi
      
      cd ../..
    else
      echo -e "${YELLOW}No tests found for $WORKER_NAME${RESET}"
    fi
    
    echo ""
  fi
done

# Exit with the appropriate status
if [ $EXIT_STATUS -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${RESET}"
else
  echo -e "${RED}Some tests failed.${RESET}"
fi

exit $EXIT_STATUS 