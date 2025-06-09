#!/bin/bash

# Real-time location monitoring script for HelpingHand app
# This script monitors location updates and provides real-time feedback

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# Device and app configuration
DEVICE_ID="EC972889-9577-4C52-B528-98E2925994E4"
APP_BUNDLE_ID="com.helpinghand.app.local"

clear
echo ""
echo "${BLUE}${BOLD}======================================================${RESET}"
echo "${BLUE}${BOLD}    HELPING HAND - REAL-TIME LOCATION MONITOR        ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

# Check if simulator is running
if ! xcrun simctl list devices | grep -q "Booted"; then
    echo "${RED}❌ No simulator is currently booted${RESET}"
    echo "Please start the iPhone 16 simulator first."
    exit 1
fi

# Check current location simulation status
echo "${GREEN}${BOLD}Current Location Simulation Status:${RESET}"
echo ""

# Try to get current location simulation info
if xcrun simctl location "$DEVICE_ID" clear 2>/dev/null; then
    echo "🧹 Location simulation cleared - using default"
    xcrun simctl location "$DEVICE_ID" run "City Run"
    echo "🏃 City Run simulation restarted"
else
    echo "📱 Location simulation status unclear - restarting City Run"
    xcrun simctl location "$DEVICE_ID" run "City Run"
fi

echo ""
echo "${GREEN}${BOLD}Starting Real-Time Location Monitoring...${RESET}"
echo ""
echo "Monitor logs for location updates:"
echo "• 📍 Location updates"
echo "• 🔍 Search queries"
echo "• ✅ Successful location acceptance"
echo "• ⚠️  Location filtering"
echo ""
echo "Press ${BOLD}Ctrl+C${RESET} to stop monitoring"
echo ""
echo "${BLUE}${BOLD}--- REAL-TIME LOCATION LOG ---${RESET}"

# Start monitoring app logs with location-specific filtering
xcrun simctl spawn "$DEVICE_ID" log stream \
    --predicate 'processImagePath contains "HelpingHand"' \
    --info \
    --debug \
    2>/dev/null | while read -r line; do
    
    # Color-code different types of location events
    if [[ $line == *"📍 Real-time Location Update"* ]]; then
        echo "${GREEN}$line${RESET}"
    elif [[ $line == *"✅ Accepting real-time location update"* ]]; then
        echo "${GREEN}$line${RESET}"
    elif [[ $line == *"🔄 Refreshing current location"* ]]; then
        echo "${YELLOW}$line${RESET}"
    elif [[ $line == *"🔍 Searching for"* ]]; then
        echo "${BLUE}$line${RESET}"
    elif [[ $line == *"❌"* ]] || [[ $line == *"⚠️"* ]]; then
        echo "${RED}$line${RESET}"
    elif [[ $line == *"📍"* ]] || [[ $line == *"🚀"* ]] || [[ $line == *"🔐"* ]]; then
        echo "${CYAN}$line${RESET}"
    else
        # Only show location-related logs
        if [[ $line == *"location"* ]] || [[ $line == *"Location"* ]] || \
           [[ $line == *"GPS"* ]] || [[ $line == *"Coordinate"* ]] || \
           [[ $line == *"Accuracy"* ]]; then
            echo "$line"
        fi
    fi
done
