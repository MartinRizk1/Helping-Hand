#!/bin/zsh

# Helping Hand App - Master Test Launcher
# This script provides a unified way to run all testing tools

# Colors for formatted output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Get the directory where the script is located
APP_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

clear
echo "${BLUE}${BOLD}======================================================${RESET}"
echo "${BLUE}${BOLD}   HELPING HAND APP - TESTING TOOLKIT                 ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

# Check for test scripts
if [ ! -f "$APP_PATH/test_app_complete.sh" ] || [ ! -f "$APP_PATH/test_new_features.sh" ] || [ ! -f "$APP_PATH/generate_quality_report.sh" ]; then
  echo "${RED}Some testing scripts are missing. Checking permissions...${RESET}"
  chmod +x "$APP_PATH/test_app_complete.sh" "$APP_PATH/test_new_features.sh" "$APP_PATH/generate_quality_report.sh" 2>/dev/null
fi

# Display menu
echo "${GREEN}${BOLD}Please select a testing option:${RESET}"
echo ""
echo "${BOLD}1. Complete App Testing${RESET} - End-to-end test of all app features"
echo "${BOLD}2. New Features Testing${RESET} - Focus on testing recent additions"
echo "${BOLD}3. Generate Quality Report${RESET} - Create detailed quality assessment document"
echo "${BOLD}4. Open in Xcode${RESET} - Launch the app project in Xcode"
echo "${BOLD}5. Exit${RESET}"
echo ""

# Get user selection
echo "${YELLOW}Enter your choice (1-5):${RESET}"
read choice

case $choice in
    1)
        echo "${GREEN}Launching complete app testing...${RESET}"
        "$APP_PATH/test_app_complete.sh"
        ;;
    2)
        echo "${GREEN}Launching new features testing...${RESET}"
        "$APP_PATH/test_new_features.sh"
        ;;
    3)
        echo "${GREEN}Generating quality report...${RESET}"
        "$APP_PATH/generate_quality_report.sh"
        ;;
    4)
        echo "${GREEN}Opening project in Xcode...${RESET}"
        open "$APP_PATH/Helping-Hand.xcodeproj"
        ;;
    5)
        echo "${GREEN}Exiting...${RESET}"
        exit 0
        ;;
    *)
        echo "${RED}Invalid selection. Please run the script again and choose a valid option.${RESET}"
        exit 1
        ;;
esac
echo "${GREEN}${BOLD}STEP 1: Verifying project files and structure...${RESET}"
echo ""

if [ -d "$APP_PATH/Helping-Hand" ] && [ -d "$APP_PATH/Helping-Hand.xcodeproj" ]; then
  echo "✅ Project folders found"
  
  # Check critical files
  cd "$APP_PATH/Helping-Hand"
  MISSING_FILES=0
  
  CRITICAL_FILES=(
    "Source/AppDelegate.swift"
    "Source/SceneDelegate.swift"
    "Source/Models/Character.swift"
    "Source/Models/ChatMessage.swift"
    "Source/Models/LocationResult.swift"
    "Source/ViewModels/ChatViewModel.swift"
    "Source/ViewModels/LocationViewModel.swift"
    "Source/Views/MainView.swift"
    "Source/Views/ChatView.swift"
    "Source/Views/CharacterView.swift"
    "Source/Views/MapView.swift"
    "Source/Views/LocationResultsView.swift"
    "Source/Services/AIService.swift"
    "Source/Services/LocationService.swift"
    "Source/Services/MapService.swift"
    "Info.plist"
  )
  
  for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
      echo "✅ Found $file"
    else
      echo "❌ Missing $file"
      MISSING_FILES=$((MISSING_FILES+1))
    fi
  done
  
  if [ $MISSING_FILES -eq 0 ]; then
    echo "${GREEN}All critical files are present!${RESET}"
  else
    echo "${RED}WARNING: $MISSING_FILES critical files are missing!${RESET}"
  fi
else
  echo "${RED}❌ Project folders not found at $APP_PATH${RESET}"
  exit 1
fi

echo ""
echo "${GREEN}${BOLD}STEP 2: Preparing for testing...${RESET}"
echo ""

# Check if character images are available or create placeholder instructions
if [ -d "Assets.xcassets/helper_neutral.imageset" ]; then
  if [ -f "Assets.xcassets/helper_neutral.imageset/helper_neutral.png" ]; then
    echo "✅ Character image is available"
  else
    echo "${YELLOW}⚠️ Character image file missing, but fallback SF Symbols will be used${RESET}"
    echo "To add a character image, follow the instructions in PLACEHOLDER_IMAGE.md"
  fi
else
  echo "${YELLOW}⚠️ Character image folder missing, fallback SF Symbols will be used${RESET}"
fi

# Create a test plan with key scenarios
echo ""
echo "${GREEN}${BOLD}STEP 3: Test plan with key scenarios${RESET}"
echo ""
echo "${BOLD}Test Case 1: App Launch & Initial UI${RESET}"
echo "✓ App should launch without errors"
echo "✓ Character should appear at the top"
echo "✓ Welcome message should be displayed"
echo "✓ Text input field should be visible at the bottom"
echo ""

echo "${BOLD}Test Case 2: Window Repair Query${RESET}"
echo "✓ Send message: \"I have a broken window\""
echo "✓ Assistant should respond with repair services information"
echo "✓ Location results should display repair shops"
echo "✓ Character mood should change to 'helping'"
echo ""

echo "${BOLD}Test Case 3: Food Query${RESET}"
echo "✓ Send message: \"Show me Chinese restaurants nearby\""
echo "✓ Assistant should respond about Chinese restaurants"
echo "✓ Location results should display Chinese restaurants"
echo "✓ Character mood should change to 'happy'"
echo ""

echo "${BOLD}Test Case 4: Hotel Query${RESET}"
echo "✓ Send message: \"I need a place to stay tonight\""
echo "✓ Assistant should respond with hotel information"
echo "✓ Location results should display hotels or accommodations"
echo "✓ Character mood should change to 'helping'"
echo ""

echo "${BOLD}Test Case 5: Map Interaction${RESET}"
echo "✓ Tap on a location in any results list"
echo "✓ Map should focus on the selected location"
echo "✓ Location detail card should appear"
echo "✓ Verify buttons for call, website, directions work"
echo ""

echo ""
echo "${GREEN}${BOLD}STEP 4: Open in Xcode and run the app${RESET}"
echo ""
echo "${YELLOW}Would you like to open the project in Xcode now? (y/n)${RESET}"
read open_xcode

if [[ $open_xcode == "y" || $open_xcode == "Y" ]]; then
  echo "Opening Xcode project..."
  open "$APP_PATH/Helping-Hand.xcodeproj"
  
  echo ""
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo "${BLUE}${BOLD}                  TESTING INSTRUCTIONS                ${RESET}"
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  echo "${GREEN}1. In Xcode, select an iPhone simulator target${RESET}"
  echo "${GREEN}2. Click the Run button or press Command+R${RESET}"
  echo "${GREEN}3. Follow the test cases listed above${RESET}"
  echo ""
  echo "${YELLOW}The app is running in TEST MODE - location permissions are not required${RESET}"
  echo ""
  echo "For detailed testing information, see: $APP_PATH/Helping-Hand/TESTING_GUIDE.md"
  echo ""
  echo "${BLUE}${BOLD}======================================================${RESET}"
else
  echo "You can open the project later with:"
  echo "${BOLD}open $APP_PATH/Helping-Hand.xcodeproj${RESET}"
fi

echo ""
echo "${GREEN}${BOLD}Testing preparation complete!${RESET}"
