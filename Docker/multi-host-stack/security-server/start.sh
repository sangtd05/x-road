#!/bin/bash
# Start Security Server stack

set -e

echo "================================================"
echo "Starting X-Road Security Server Stack"
echo "================================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo ""
    echo "Please create .env file with the following content:"
    echo ""
    cat << 'EOF'
# X-Road Security Server Configuration
PACKAGE_SOURCE=external
SS_TOKEN_PIN=Secret1234
CS_HOST=192.168.1.10
CA_HOST=192.168.1.10
ISSOAP_HOST=192.168.1.10
ISREST_HOST=192.168.1.10
DIST=jammy-snapshot
REPO=https://artifactory.niis.org/xroad-snapshot-deb
EOF
    echo ""
    echo "IMPORTANT: Update CS_HOST with actual Central Server IP!"
    echo "Save this as .env file and run again."
    exit 1
fi

# Load environment variables
source .env

# Verify CS_HOST is configured
if [ "$CS_HOST" = "192.168.1.10" ]; then
    echo "Warning: CS_HOST is still set to default value"
    echo "Please update .env file with actual Central Server IP/hostname"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create necessary directories for volumes
echo "Creating volume directories..."
sudo mkdir -p /etc/xroad/ss /var/lib/xroad/ss /var/lib/postgresql/ss

echo ""
echo "Starting Security Server..."
docker compose up -d ss

echo ""
echo "Waiting for Security Server to be healthy..."
echo "This may take 2-3 minutes..."

# Wait for service to be healthy
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if docker compose ps ss | grep -q "healthy"; then
        echo ""
        echo "Security Server is healthy!"
        break
    else
        echo -n "."
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    fi
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo ""
    echo "Warning: Security Server did not become healthy within timeout"
    echo "Check logs with: docker compose logs ss"
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
echo "Security Server UI: https://localhost:4000"
echo "  Username: xrd-sys"
echo "  Password: secret"
echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo "1. Access the Security Server UI"
echo "2. Complete initialization wizard"
echo "3. Register with Central Server using the API token"
echo ""
echo "Central Server: $CS_HOST"
echo ""

