#!/bin/bash

# Script to run documentation tests for repository_audit_tasks.md
# This script should be run from the repository root directory

set -e

echo "================================================"
echo "Running Documentation Tests"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${YELLOW}Checking Flutter version...${NC}"
flutter --version
echo ""

# Ensure we're in the repository root
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Please run this script from the repository root.${NC}"
    exit 1
fi

echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get
echo ""

echo -e "${YELLOW}Running documentation tests...${NC}"
echo ""

# Run the tests with expanded output
flutter test test/docs/repository_audit_tasks_test.dart --reporter expanded

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}All documentation tests passed!${NC}"
    echo -e "${GREEN}================================================${NC}"
else
    echo ""
    echo -e "${RED}================================================${NC}"
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    echo -e "${RED}================================================${NC}"
    exit 1
fi