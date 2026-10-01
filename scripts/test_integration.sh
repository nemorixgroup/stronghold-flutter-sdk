#!/bin/bash
# ============================================================
# test_integration.sh - runs tests tagged 'integration' (macOS/Linux)
# These hit real networks (Testnet, Mainnet reads). Run manually,
# not as part of every commit.
# Usage: ./scripts/test_integration.sh
# Mirrors scripts/test_integration.ps1 exactly; keep both in sync.
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${YELLOW}Running integration tests (real network calls)...${NC}"

if ! flutter test --tags=integration; then
  echo -e "${RED}FAILED: Integration tests failed.${NC}"
  exit 1
fi

echo -e "${GREEN}Integration tests: OK${NC}"