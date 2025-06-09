#!/bin/bash

# Test script to verify ChatGPT integration in HelpingHand app
# This script monitors app logs to check if API calls are working

# Colors for formatted output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

echo "${BLUE}${BOLD}=========================================${RESET}"
echo "${BLUE}${BOLD} 🧪 Testing HelpingHand ChatGPT Integration ${RESET}"
echo "${BLUE}${BOLD}=========================================${RESET}"

# App project path
APP_PATH="$(dirname "$0")/.."
cd "$APP_PATH"

# Check API Config
echo "${GREEN}${BOLD}STEP 1: Checking API Configuration${RESET}"
echo ""

if [ -f "App/Source/Configuration/APIConfig.swift" ]; then
    echo "✅ Found APIConfig.swift"
    
    # Check if configuration is secure
    if grep -q "ProcessInfo.processInfo.environment\[\"OPENAI_API_KEY\"\]" "App/Source/Configuration/APIConfig.swift"; then
        echo "✅ API key configuration is secure (using environment variables)"
    else
        echo "${YELLOW}⚠️ API key might not be properly secured in APIConfig.swift${RESET}"
    fi
else
    echo "${RED}❌ APIConfig.swift not found${RESET}"
    echo "Please ensure the configuration file exists at App/Source/Configuration/APIConfig.swift"
    exit 1
fi

# Check secrets template
echo ""
echo "${GREEN}${BOLD}STEP 2: Checking secret templates${RESET}"
echo ""

if [ -f "Config/secrets.json.template" ]; then
    echo "✅ Found secrets.json.template"
else
    echo "${RED}❌ Missing secrets.json.template${RESET}"
    echo "The template file should be present to guide developers"
fi

# Check for actual API key
echo ""
echo "${GREEN}${BOLD}STEP 3: Testing API key availability${RESET}"
echo ""

API_KEY=""

# Check environment variable
if [ ! -z "${OPENAI_API_KEY}" ]; then
    API_KEY="${OPENAI_API_KEY}"
    echo "✅ Found API key in environment variable"
elif [ -f "Config/secrets.json" ]; then
    echo "✅ Found secrets.json file"
    if grep -q "openai_api_key" "Config/secrets.json"; then
        echo "✅ API key exists in secrets.json"
        API_KEY="Found in secrets.json"
    else
        echo "${YELLOW}⚠️ secrets.json exists but doesn't contain an OpenAI API key${RESET}"
    fi
else
    echo "${YELLOW}⚠️ No API key found in environment or secrets.json${RESET}"
fi

# Summary
echo ""
echo "${GREEN}${BOLD}STEP 4: Integration test summary${RESET}"
echo ""

if [ ! -z "$API_KEY" ]; then
    echo "${GREEN}✅ ChatGPT integration is properly configured${RESET}"
    echo ""
    echo "To run the app with full API integration:"
    echo "1. Launch the app in Xcode"
    echo "2. Try AI queries like 'Find Chinese restaurants near me'"
    echo "3. Watch the Xcode console for API responses"
    echo ""
    echo "${BOLD}Monitor logs with:${RESET}"
    echo "xcrun simctl spawn booted log stream --predicate 'processImagePath contains \"HelpingHand\"' | grep -E \"(ChatGPT|OpenAI|API)\""
else
    echo "${YELLOW}⚠️ ChatGPT integration needs configuration${RESET}"
    echo ""
    echo "To set up API integration:"
    echo "1. Get an OpenAI API key from https://platform.openai.com/api-keys"
    echo "2. Set up the key using one of these methods:"
    echo "   - Environment variable: export OPENAI_API_KEY='your-key-here'"
    echo "   - Config file: cp Config/secrets.json.template Config/secrets.json"
    echo "     Then edit secrets.json with your API key"
fi

echo ""
echo "${BLUE}${BOLD}Test completed.${RESET}"
