#!/bin/bash
# Start Central Service stack

set -e

echo "================================================"
echo "Starting X-Road Central Service Stack"
echo "================================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Load environment variables
source .env

# Create necessary directories for volumes
echo "Creating volume directories..."
sudo mkdir -p /etc/xroad/cs /var/lib/xroad/cs /var/lib/postgresql/cs
sudo mkdir -p /etc/xroad/ss0 /var/lib/xroad/ss0 /var/lib/postgresql/ss0

# Create testmail directory
mkdir -p testmail

echo ""
echo "Starting services..."
docker compose up -d cs testca ss0 issoap isrest mailpit

echo ""
echo "Waiting for services to be healthy..."
echo "This may take 2-3 minutes..."

# Wait for all services to be healthy
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if docker compose ps | grep -q "unhealthy"; then
        echo -n "."
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    else
        echo ""
        echo "All services are healthy!"
        break
    fi
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "Warning: Services did not become healthy within timeout"
    echo "Check logs with: docker compose logs"
fi

echo ""
echo "================================================"
echo "Services Status:"
echo "================================================"
docker compose ps

echo ""
echo "================================================"
echo "Access Information:"
echo "================================================"
echo "Central Server UI: https://localhost:4000"
echo "  Username: xrd-sys"
echo "  Password: secret"
echo ""
echo "Management Security Server UI: https://localhost:4200"
echo "  Username: xrd-sys"
echo "  Password: secret"
echo ""
echo "Test CA: http://localhost:8888"
echo "Mail UI: http://localhost:8025"
echo ""
echo "================================================"
echo "Get API Token for Security Server clients:"
echo "================================================"
echo "Run: docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token"
echo ""
echo "Share this token and the Central Server IP with Security Server administrators"
echo ""

