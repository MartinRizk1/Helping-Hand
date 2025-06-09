#!/bin/bash

# Setup script for real-time location testing
# This script configures the iOS Simulator to use dynamic location data

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# iPhone 16 Simulator Device ID
DEVICE_ID="EC972889-9577-4C52-B528-98E2925994E4"
APP_BUNDLE_ID="com.helpinghand.app.local"

echo ""
echo "${BLUE}${BOLD}======================================================${RESET}"
echo "${BLUE}${BOLD}     HELPING HAND - REAL-TIME LOCATION SETUP         ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

echo "${GREEN}${BOLD}STEP 1: Configuring Simulator for Real-Time Location${RESET}"
echo ""

# Check if simulator is available
if ! xcrun simctl list devices | grep -q "$DEVICE_ID"; then
    echo "${RED}❌ iPhone 16 simulator not found${RESET}"
    exit 1
fi

echo "📱 Using iPhone 16 Simulator: $DEVICE_ID"

# Boot the simulator if not already running
echo "🚀 Booting simulator..."
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || echo "Simulator already running"

# Clear any existing location simulation
echo "🧹 Clearing existing location simulation..."
xcrun simctl location "$DEVICE_ID" clear

echo ""
echo "${GREEN}${BOLD}STEP 2: Location Configuration Options${RESET}"
echo ""

echo "Choose a real-time location configuration:"
echo ""
echo "1. ${BOLD}Apple Park${RESET} - Static location at Apple headquarters"
echo "2. ${BOLD}City Run${RESET} - Dynamic movement simulation through city"
echo "3. ${BOLD}City Bicycle Ride${RESET} - Bicycle route simulation"
echo "4. ${BOLD}Freeway Drive${RESET} - Highway driving simulation"
echo "5. ${BOLD}Custom Location${RESET} - Set your own coordinates"
echo "6. ${BOLD}None${RESET} - Use default simulator location (Cupertino)"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo "🏢 Setting location to Apple Park..."
        xcrun simctl location "$DEVICE_ID" set 37.3349,-122.0090
        echo "✅ Static location set to Apple Park"
        ;;
    2)
        echo "🏃 Starting City Run simulation..."
        xcrun simctl location "$DEVICE_ID" run "City Run"
        echo "✅ Dynamic city run simulation started"
        ;;
    3)
        echo "🚴 Starting City Bicycle Ride simulation..."
        xcrun simctl location "$DEVICE_ID" run "City Bicycle Ride"
        echo "✅ Dynamic bicycle ride simulation started"
        ;;
    4)
        echo "🚗 Starting Freeway Drive simulation..."
        xcrun simctl location "$DEVICE_ID" run "Freeway Drive"
        echo "✅ Dynamic freeway drive simulation started"
        ;;
    5)
        echo "📍 Enter custom coordinates:"
        read -p "Latitude: " lat
        read -p "Longitude: " lon
        xcrun simctl location "$DEVICE_ID" set "$lat,$lon"
        echo "✅ Custom location set to $lat, $lon"
        ;;
    6)
        echo "🏠 Using default simulator location"
        echo "✅ No location override - using Cupertino default"
        ;;
    *)
        echo "${YELLOW}⚠️ Invalid choice, using default location${RESET}"
        ;;
esac

echo ""
echo "${GREEN}${BOLD}STEP 3: Building and Installing App${RESET}"
echo ""

# Build the app
echo "🔨 Building HelpingHand app..."
cd "$(dirname "$0")/.."

if xcodebuild -project HelpingHand.xcodeproj -scheme HelpingHand -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16,OS=18.3.1" build > /dev/null 2>&1; then
    echo "✅ Build successful"
else
    echo "${RED}❌ Build failed${RESET}"
    exit 1
fi

# Install the app
echo "📲 Installing app on simulator..."
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/HelpingHand-*/Build/Products/Debug-iphonesimulator/HelpingHand.app"

if [ -d "$APP_PATH" ]; then
    xcrun simctl install "$DEVICE_ID" "$APP_PATH"
    echo "✅ App installed successfully"
else
    echo "${RED}❌ App bundle not found at $APP_PATH${RESET}"
    exit 1
fi

echo ""
echo "${GREEN}${BOLD}STEP 4: Launching App with Real-Time Location${RESET}"
echo ""

# Launch the app
echo "🚀 Launching HelpingHand app..."
xcrun simctl launch "$DEVICE_ID" "$APP_BUNDLE_ID"
echo "✅ App launched"

# Open Simulator app
echo "📱 Opening Simulator..."
open -a Simulator

echo ""
echo "${BLUE}${BOLD}======================================================${RESET}"
echo "${BLUE}${BOLD}           REAL-TIME LOCATION TESTING READY          ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

echo "${GREEN}${BOLD}Configuration Complete!${RESET}"
echo ""
echo "${BOLD}Your app is now configured for real-time location testing:${RESET}"

case $choice in
    1)
        echo "• 📍 Static location: Apple Park, Cupertino"
        echo "• 🔄 Location will not change during testing"
        ;;
    2|3|4)
        echo "• 🏃 Dynamic location simulation active"
        echo "• 📍 Location will update continuously along route"
        echo "• 🔄 Watch console for real-time location updates"
        ;;
    5)
        echo "• 📍 Custom location: $lat, $lon"
        echo "• 🔄 Static location set to your coordinates"
        ;;
    6)
        echo "• 🏠 Default location: Cupertino, CA"
        echo "• 📍 Using simulator's default location"
        ;;
esac

echo ""
echo "${YELLOW}${BOLD}Testing Instructions:${RESET}"
echo "1. The app should request location permission - tap 'Allow'"
echo "2. Try queries like: 'Find restaurants nearby'"
echo "3. Watch the console output for real-time location updates"
echo "4. Verify that search results are based on the configured location"
echo ""

echo "${BLUE}${BOLD}Monitor real-time location updates:${RESET}"
echo "You can monitor location updates by watching the Xcode console or running:"
echo "${BOLD}xcrun simctl spawn $DEVICE_ID log stream --predicate 'processImagePath contains \"HelpingHand\"'${RESET}"
echo ""

echo "${GREEN}Ready for real-time location testing! 🎉${RESET}"
