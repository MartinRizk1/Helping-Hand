#!/bin/zsh

# End-to-End Testing Script for Helping Hand App
# This script guides you through the process of testing all app features

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
echo "${BLUE}${BOLD}   HELPING HAND APP - COMPLETE END-TO-END TESTING    ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

# Step 1: Verify project files and structure
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

echo "${BOLD}Test Case 6: Voice Input${RESET}"
echo "✓ Tap the microphone button in the input area"
echo "✓ Observe system requesting microphone permission (first time only)"
echo "✓ In test mode, a simulated voice query should appear"
echo "✓ The query should automatically send after a moment"
echo "✓ Results should display as with text input"
echo ""

echo "${BOLD}Test Case 7: Theme & Appearance${RESET}"
echo "✓ Tap the settings (gear) icon in the top-right"
echo "✓ Select different themes (Light, Dark, System) and observe changes"
echo "✓ Use the color picker to change accent colors"
echo "✓ Tap 'Reset to Default Colors' to restore original colors"
echo ""

echo "${BOLD}Test Case 8: Chat History & Persistence${RESET}"
echo "✓ Send several messages with the assistant"
echo "✓ Force close the app (swipe up in app switcher)"
echo "✓ Relaunch the app - chat history should be preserved"
echo "✓ Go to Settings and tap 'Clear Chat History'"
echo "✓ Confirm and verify history is cleared except welcome message"
echo ""

echo "${BOLD}Test Case 9: Location Details${RESET}"
echo "✓ After receiving location results, tap on a location"
echo "✓ A detailed view should appear with location information"
echo "✓ Map should show a pin at the location"
echo "✓ Contact information and buttons should be available"
echo "✓ Tap the X button to close the details view"
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
  
  # Wait for user to complete testing
  echo ""
  echo "${YELLOW}Press Enter when you've completed the test cases...${RESET}"
  read completed
  
  # Post-test checklist
  clear
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo "${BLUE}${BOLD}                  TEST RESULTS CHECKLIST               ${RESET}"
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  echo "${BOLD}Please mark each feature as PASS or FAIL:${RESET}"
  echo ""
  
  features=(
    "App launches successfully"
    "Character displays properly"
    "Chat interface works"
    "Location search for window repair"
    "Location search for restaurants"
    "Location search for hotels"
    "Map displays locations correctly"
    "Voice input functionality"
    "Theme switching (light/dark)"
    "Accent color customization"
    "Chat history persistence"
    "Settings menu functionality"
    "Location detail view"
    "Character animations/mood changes"
  )
  
  results=()
  for feature in "${features[@]}"; do
    echo "${YELLOW}Does '${feature}' work correctly? (y/n)${RESET}"
    read result
    if [[ $result == "y" || $result == "Y" ]]; then
      results+=("${GREEN}✅ PASS: ${feature}${RESET}")
    else
      results+=("${RED}❌ FAIL: ${feature}${RESET}")
    fi
  done
  
  # Show summary
  clear
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo "${BLUE}${BOLD}                  TEST RESULTS SUMMARY                 ${RESET}"
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  
  pass_count=0
  fail_count=0
  
  for result in "${results[@]}"; do
    echo "$result"
    if [[ $result == *"PASS"* ]]; then
      pass_count=$((pass_count+1))
    else
      fail_count=$((fail_count+1))
    fi
  done
  
  total=$((pass_count + fail_count))
  pass_percent=$((pass_count * 100 / total))
  
  echo ""
  echo "${BOLD}Summary: $pass_count/$total passed ($pass_percent%)${RESET}"
  
  if [[ $fail_count -eq 0 ]]; then
    echo "${GREEN}${BOLD}All tests passed! App is ready for use.${RESET}"
  else
    echo "${YELLOW}${BOLD}Some tests failed. Please check the TESTING_GUIDE.md for troubleshooting.${RESET}"
  fi
  
  # Export results
  echo ""
  echo "${YELLOW}Would you like to export these test results to a file? (y/n)${RESET}"
  read export_results
  
  if [[ $export_results == "y" || $export_results == "Y" ]]; then
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    result_file="$APP_PATH/test-results/test_results_$timestamp.txt"
    
    echo "# Helping Hand App Test Results - $(date)" > "$result_file"
    echo "Total: $pass_count/$total passed ($pass_percent%)" >> "$result_file"
    echo "" >> "$result_file"
    
    for result in "${results[@]}"; do
      # Strip color codes for file output
      clean_result=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')
      echo "$clean_result" >> "$result_file"
    done
    
    echo "" >> "$result_file"
    echo "Generated on: $(date)" >> "$result_file"
    
    echo "${GREEN}Results exported to: $result_file${RESET}"
  fi
  
else
  echo "You can open the project later with:"
  echo "${BOLD}open $APP_PATH/Helping-Hand.xcodeproj${RESET}"
fi

echo ""
echo "${GREEN}${BOLD}Testing complete!${RESET}"
