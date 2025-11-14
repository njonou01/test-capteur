#!/bin/bash

# ========================================
# ENTRANCE COCKPIT - Stop Script
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "🛑 Stopping Entrance Cockpit System"
echo "========================================="

cd "$PROJECT_DIR"

# Stop services
docker compose down

echo ""
echo "========================================="
echo "✅ All services stopped successfully!"
echo "========================================="
echo ""
echo "💡 To start again:"
echo "  ./scripts/start.sh"
echo ""
echo "🗑️  To remove all data (volumes):"
echo "  ./scripts/reset.sh"
echo ""
echo "========================================="
