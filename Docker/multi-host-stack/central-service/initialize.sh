#!/bin/bash
# Initialize Central Service with test configuration

set -e

echo "================================================"
echo "Initializing X-Road Central Service"
echo "================================================"
echo ""

# Check if services are running
if ! docker compose ps | grep -q "cs"; then
    echo "Error: Services are not running!"
    echo "Please run ./start.sh first"
    exit 1
fi

echo "Running initialization setup..."
echo "This will configure:"
echo "  - Central Server instance"
echo "  - Management Security Server"
echo "  - Test member and subsystems"
echo "  - Example services"
echo ""

docker compose run --rm hurl

echo ""
echo "================================================"
echo "Initialization Complete!"
echo "================================================"
echo ""
echo "API Token for Security Server clients:"
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
echo ""
echo "Save this token - it's needed to register new Security Servers"
echo ""

