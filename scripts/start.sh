#!/bin/bash

# ========================================
# ENTRANCE COCKPIT - Start Script
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "🚀 Starting Entrance Cockpit System"
echo "========================================="

cd "$PROJECT_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "✅ Please edit .env with your configuration before continuing."
    echo "   Use: nano .env or vim .env"
    exit 1
fi

# Check if certificates exist
if [ ! -f docker/traefik/certs/localhost.crt ]; then
    echo "⚠️  SSL certificates not found. Generating..."
    cd docker/traefik/certs
    ./generate-certs.sh localhost 365
    cd "$PROJECT_DIR"
fi

# Start services
echo ""
echo "📦 Starting Docker Compose services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 10

echo ""
echo "========================================="
echo "✅ Entrance Cockpit is running!"
echo "========================================="
echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "🌐 Access URLs:"
echo "  - Frontend:          https://localhost"
echo "  - Traefik Dashboard: http://localhost:8090"
echo "  - Static Server:     https://localhost:8080/health"
echo "  - Core Operational:  https://localhost:8081/health"
echo "  - Cache Loading:     https://localhost:8082/health"
echo "  - Entrance Cockpit:  https://localhost:8083/health"
echo "  - Telemetry:         https://localhost:8084/health"
echo ""
echo "📝 View logs:"
echo "  docker compose logs -f"
echo ""
echo "🛑 Stop services:"
echo "  ./scripts/stop.sh"
echo ""
echo "========================================="
