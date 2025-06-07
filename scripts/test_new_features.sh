#!/bin/zsh

# New Features Testing Script for Helping Hand App
# This script focuses on testing the recently added features

# Colors for formatted output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# App project path
APP_PATH="/Users/martinrizk/Desktop/Helping-Hand"

clear
echo "${BLUE}${BOLD}======================================================${RESET}"
echo "${BLUE}${BOLD}   HELPING HAND APP - NEW FEATURES TESTING            ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

# Step 1: Check for required service files
echo "${GREEN}${BOLD}STEP 1: Verifying new feature files...${RESET}"
echo ""

cd "$APP_PATH/Helping-Hand"
MISSING_FILES=0

NEW_SERVICE_FILES=(
  "Source/Services/PersistenceService.swift"
  "Source/Services/CharacterAnimationService.swift"
  "Source/Services/SpeechRecognitionService.swift"
  "Source/Services/ThemeService.swift"
  "Source/Views/SettingsView.swift"
  "Source/Views/LocationDetailView.swift"
)

for file in "${NEW_SERVICE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ Found $file"
  else
    echo "❌ Missing $file"
    MISSING_FILES=$((MISSING_FILES+1))
  fi
done

if [ $MISSING_FILES -eq 0 ]; then
  echo "${GREEN}All new feature files are present!${RESET}"
else
  echo "${RED}WARNING: $MISSING_FILES feature files are missing!${RESET}"
  echo "${YELLOW}Some new features may not be available for testing${RESET}"
fi

# Check Info.plist for new permissions
echo ""
echo "${GREEN}${BOLD}STEP 2: Checking for required permissions...${RESET}"
echo ""

if grep -q "NSMicrophoneUsageDescription" "Info.plist" && \
   grep -q "NSSpeechRecognitionUsageDescription" "Info.plist"; then
  echo "✅ Voice input permissions found in Info.plist"
else
  echo "${YELLOW}⚠️ Voice input permissions missing from Info.plist${RESET}"
  echo "Voice input features may not work properly"
fi

# Display test cases for new features
echo ""
echo "${GREEN}${BOLD}STEP 3: New features test plan${RESET}"
echo ""

echo "${BOLD}Feature 1: Voice Input${RESET}"
echo "✓ Tap the microphone button in the chat interface"
echo "✓ In test mode, a test query should appear automatically"
echo "✓ The query should be processed and generate relevant responses"
echo "✓ Try tapping the mic button again to toggle recording on/off"
echo ""

echo "${BOLD}Feature 2: Theme & Appearance${RESET}"
echo "✓ Open Settings (gear icon) and locate Theme selector"
echo "✓ Test Light, Dark, and System theme options"
echo "✓ Use the color picker to change accent colors"
echo "✓ Test 'Reset to Default Colors' functionality"
echo "✓ Ensure theme changes persist after app restart"
echo ""

echo "${BOLD}Feature 3: Chat Persistence${RESET}"
echo "✓ Send several messages with various queries"
echo "✓ Force close the app completely"
echo "✓ Relaunch and verify chat history persists"
echo "✓ Test Clear History functionality in Settings"
echo "✓ Verify only welcome message remains after clearing"
echo ""

echo "${BOLD}Feature 4: Enhanced Location Details${RESET}"
echo "✓ Search for locations (e.g., 'I need a window repair')"
echo "✓ Tap on a location result to open detailed view"
echo "✓ Check for detailed contact information"
echo "✓ Verify map shows correct location pin"
echo "✓ Test action buttons (call, website, directions)"
echo "✓ Close detail view and try with another location"
echo ""

echo "${BOLD}Feature 5: Character Animations${RESET}"
echo "✓ Observe character mood changes based on queries"
echo "✓ Try tapping on the character to see interaction"
echo "✓ Verify different moods display correctly"
echo "✓ Check animation transitions between states"
echo ""

# Launch options
echo ""
echo "${GREEN}${BOLD}STEP 4: Launch app for testing${RESET}"
echo ""
echo "${YELLOW}Would you like to open the project in Xcode now? (y/n)${RESET}"
read open_xcode

if [[ $open_xcode == "y" || $open_xcode == "Y" ]]; then
  echo "Opening Xcode project..."
  open "$APP_PATH/Helping-Hand.xcodeproj"
  
  echo ""
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo "${BLUE}${BOLD}              NEW FEATURES TEST NOTES                 ${RESET}"
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  echo "${GREEN}1. In Xcode, select an iPhone simulator target${RESET}"
  echo "${GREEN}2. Click the Run button or press Command+R${RESET}"
  echo "${GREEN}3. Follow the feature test cases listed above${RESET}"
  echo ""
  echo "${YELLOW}Remember: The app is running in TEST MODE${RESET}"
  echo "• Voice input will use simulated responses"
  echo "• Location services use mock data"
  echo "• No real API calls are made"
  echo ""
  
  # Wait for user to complete testing
  echo "${YELLOW}Press Enter when you've completed testing the new features...${RESET}"
  read completed
  
  # Collect feedback on new features
  clear
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo "${BLUE}${BOLD}                  NEW FEATURES FEEDBACK                ${RESET}"
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  echo "${BOLD}Please rate each new feature (1-5 stars, with 5 being best):${RESET}"
  echo ""
  
  features=(
    "Voice input functionality"
    "Theme and appearance customization"
    "Chat history persistence"
    "Enhanced location details"
    "Character animations and interactions"
  )
  
  ratings=()
  for feature in "${features[@]}"; do
    while true; do
      echo "${YELLOW}How would you rate '${feature}'? (1-5)${RESET}"
      read rating
      if [[ $rating =~ ^[1-5]$ ]]; then
        stars=""
        for ((i=1; i<=$rating; i++)); do
          stars+="★"
        done
        for ((i=$rating+1; i<=5; i++)); do
          stars+="☆"
        done
        ratings+=("$stars ($rating/5): $feature")
        break
      else
        echo "${RED}Please enter a number between 1 and 5${RESET}"
      fi
    done
  done
  
  # Show summary
  clear
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo "${BLUE}${BOLD}              NEW FEATURES RATING SUMMARY              ${RESET}"
  echo "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  
  for rating in "${ratings[@]}"; do
    echo "$rating"
  done
  
  echo ""
  echo "${YELLOW}Any additional feedback or comments on the new features?${RESET}"
  echo "${YELLOW}(Type your feedback and press Enter, or just press Enter to skip)${RESET}"
  read feedback
  
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  feedback_file="$APP_PATH/feature_feedback_$timestamp.txt"
  
  echo "# Helping Hand App - New Features Feedback" > "$feedback_file"
  echo "Date: $(date)" >> "$feedback_file"
  echo "" >> "$feedback_file"
  echo "## Feature Ratings" >> "$feedback_file"
  
  for rating in "${ratings[@]}"; do
    # Strip color codes for file output
    clean_rating=$(echo "$rating" | sed 's/\x1b\[[0-9;]*m//g')
    echo "- $clean_rating" >> "$feedback_file"
  done
  
  if [[ ! -z "$feedback" ]]; then
    echo "" >> "$feedback_file"
    echo "## Additional Comments" >> "$feedback_file"
    echo "$feedback" >> "$feedback_file"
  fi
  
  echo "${GREEN}Feedback saved to: $feedback_file${RESET}"
  
else
  echo "You can open the project later with:"
  echo "${BOLD}open $APP_PATH/Helping-Hand.xcodeproj${RESET}"
fi

echo ""
echo "${GREEN}${BOLD}New features testing complete!${RESET}"
