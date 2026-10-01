#!/bin/bash
# ============================================================
# pre_commit.sh - stronghold_flutter_sdk quality gate (macOS/Linux)
# Run before every commit: ./scripts/pre_commit.sh
# Mirrors scripts/pre_commit.ps1 exactly; keep both in sync.
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}  stronghold_flutter_sdk pre-commit check${NC}"
echo -e "${CYAN}==========================================${NC}"

# ---- Section 1: Format ----
echo ""
echo -e "${YELLOW}[1/3] dart format .${NC}"
if ! dart format .; then
  echo -e "${RED}FAILED: dart format encountered an error.${NC}"
  exit 1
fi
echo -e "${GREEN}Format: OK (files reformatted if needed, review before committing)${NC}"

# ---- Section 2: Analyze ----
echo ""
echo -e "${YELLOW}[2/3] dart analyze --fatal-infos${NC}"
if ! dart analyze --fatal-infos; then
  echo -e "${RED}FAILED: Analysis errors found.${NC}"
  exit 1
fi
echo -e "${GREEN}Analyze: OK${NC}"

# ---- Section 3: Test ----
echo ""
echo -e "${YELLOW}[3/3] flutter test --exclude-tags=integration${NC}"
if ! flutter test --exclude-tags=integration; then
  echo -e "${RED}FAILED: Tests failed.${NC}"
  exit 1
fi
echo -e "${GREEN}Tests: OK${NC}"

# ---- Done ----
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  All checks passed. Ready to commit.${NC}"
echo -e "${GREEN}==========================================${NC}"