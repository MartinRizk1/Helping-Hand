#!/bin/bash

# Build and Run Helper Script for Helping Hand App
# This script helps test the app by building and running it in the iOS simulator

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Helping Hand App Testing Helper ===${NC}"
echo "This script will help you build and run the app in the iOS simulator."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not found${NC}"
    echo "Please make sure Xcode is installed and command line tools are set up."
    exit 1
fi

PROJECT_PATH="$(dirname "$0")/../HelpingHand.xcodeproj"

# Check if the project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project not found at $PROJECT_PATH${NC}"
    exit 1
fi

echo -e "\n${GREEN}1. Checking for character image...${NC}"
if [ ! -f "$(dirname "$0")/../add_character_image.txt" ]; then
    echo -e "${YELLOW}Please make sure to add a character image as described in the TESTING_GUIDE.md${NC}"
else
    echo -e "Character image instructions found. Please follow the instructions in add_character_image.txt"
    cat "$(dirname "$0")/../add_character_image.txt"
fi

echo -e "\n${GREEN}2. Opening Xcode project...${NC}"
open "$PROJECT_PATH"

echo -e "\n${GREEN}3. Testing instructions:${NC}"
echo "- Select an iOS simulator (iPhone 13 recommended)"
echo "- Build and run the app (Cmd+R)"
echo "- Try these test phrases:"
echo "  • \"I have a broken window\""
echo "  • \"I'm looking for Chinese food\""
echo "  • \"I need a hotel nearby\""

echo -e "\n${YELLOW}For more detailed testing instructions, please refer to:${NC}"
echo "$(dirname "$0")/../TESTING_GUIDE.md"

echo -e "\n${GREEN}Happy testing!${NC}"
