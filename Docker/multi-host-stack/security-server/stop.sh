#!/bin/bash
# Stop Security Server stack

set -e

echo "================================================"
echo "Stopping X-Road Security Server Stack"
echo "================================================"

docker compose down

echo ""
echo "Stack stopped. Data is preserved in volumes."
echo "To remove all data, run: docker compose down -v"

