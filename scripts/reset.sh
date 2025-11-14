#!/bin/bash

# ========================================
# ENTRANCE COCKPIT - Reset Script
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "🗑️  Resetting Entrance Cockpit System"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL data!"
echo "   - PostgreSQL database"
echo "   - Redis cache"
echo "   - Kafka topics"
echo "   - All logs"
echo ""
read -p "Are you sure? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "❌ Reset cancelled."
    exit 1
fi

cd "$PROJECT_DIR"

# Stop and remove everything
echo "🛑 Stopping all services..."
docker compose down -v --remove-orphans

echo "🧹 Cleaning up volumes..."
docker volume prune -f

echo "🧹 Cleaning up networks..."
docker network prune -f

echo ""
echo "========================================="
echo "✅ System reset complete!"
echo "========================================="
echo ""
echo "💡 To start fresh:"
echo "  ./scripts/start.sh"
echo ""
echo "========================================="
