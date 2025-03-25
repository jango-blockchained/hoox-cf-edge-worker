#!/bin/bash

# Run all tests with Bun
echo "Running tests with Bun..."
bun test

# Run tests with coverage
echo "Running tests with coverage..."
bun test --coverage

# Watch mode (uncomment to use)
# echo "Running tests in watch mode..."
# bun test --watch 