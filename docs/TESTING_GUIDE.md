# Testing Guide for Helping Hand App

This guide will help you test the Helping Hand application in the iOS Simulator.

## Prerequisites

1. Xcode 13.0 or later
2. macOS Monterey (12.0) or later
3. Basic familiarity with Xcode

## Getting Started

1. **Open the project in Xcode:**

   ```
   open ./Helping-Hand.xcodeproj
   ```

2. **Add a placeholder character image:**

   - Find a simple cartoon character image online (~200x200px)
   - In Xcode, click on Assets.xcassets
   - Locate the "helper_neutral" image set
   - Drag your image into the 1x slot

3. **Select a simulator target:**

   - Click on the device selector in the Xcode toolbar
   - Choose "iPhone 13" or any other iPhone model
   - Make sure the scheme is set to "Helping-Hand"

4. **Build and Run:**
   - Press Command+R or click the Play button
   - The app should build and launch in the simulator

## Testing the App

### Basic UI Testing

1. **Character Display:**

   - Verify the character appears at the top of the screen
   - The character should display with the name "Helper" below it

2. **Chat Interface:**
   - The chat interface should show a welcome message
   - Type a message in the text field at the bottom
   - Tap the send button (arrow icon)
   - Verify that your message appears in the chat

### Testing Location Features

1. **Window Repair Services:**

   - Type "I have a broken window" and send
   - The character should respond with a message about window repair
   - A list of window repair locations should appear
   - The character's mood should change to "helping"

2. **Restaurant Search:**

   - Type "I'm looking for Chinese food" and send
   - The app should respond with information about Chinese restaurants
   - Verify that restaurant results appear in the list
   - Tap on any result to see it highlighted on the map

3. **Hotel Search:**
   - Type "I need a place to stay tonight" and send
   - The app should display hotel options nearby
   - Verify the results show in both list and map form

### Map Testing

1. **Map View:**

   - When location results appear, the map should show pins for each location
   - Check that the pins have appropriate icons based on the category
   - Tap on a pin to see the location name

2. **Location Details:**
   - Tap on a location in the list or on the map
   - A detail card should appear at the bottom of the map
   - Verify that it shows name, address, distance, and rating information
   - The card should include buttons for calling, website, and directions

## Testing in Different Conditions

1. **No Location Permission:**

   - In the simulator, go to Settings > Privacy > Location Services
   - Turn off location access for the app
   - Test the app again to ensure it works with mock data

2. **Different Query Types:**
   - Try various queries like "hospitals near me", "coffee shops", etc.
   - The app should respond appropriately to different types of requests

## Testing New Features

### Voice Input Testing

1. **Launch the App:**

   - Open the Helping Hand app in the simulator
   - Verify the microphone button appears in the bottom input area

2. **Tap the Microphone Button:**
   - When running in test mode, tapping the microphone button will simulate voice recognition
   - After a brief delay, a test query should appear in the input field
   - The query should be automatically sent to the assistant

### Theme Testing

1. **Open Settings:**

   - Tap the gear icon in the top-right corner
   - Verify the Settings screen appears with a Theme option

2. **Try Different Themes:**

   - Choose "Light" theme and verify the app uses light mode
   - Choose "Dark" theme and verify the app switches to dark mode
   - Choose "System" theme to follow the device settings

3. **Change Accent Color:**
   - Tap on the color picker in Settings
   - Choose a new accent color
   - Verify the app's accent elements change to the new color
   - Test resetting to the default color

### Location Detail Testing

1. **Get Location Results:**

   - Ask for a service like "I need a window repair"
   - Verify location results appear in the chat

2. **View Location Details:**

   - Tap on any location in the results list
   - Verify a detailed view appears with:
     - A map showing the location
     - Address and contact information
     - Action buttons for call, website, and directions

3. **Test Actions:**
   - Tap the directions button and verify the alert appears
   - Test other action buttons function as expected (in test mode)

### Chat Persistence Testing

1. **Send Several Messages:**

   - Have a conversation with several messages and location results

2. **Close and Reopen the App:**

   - Force-quit the app completely
   - Relaunch the app
   - Verify your chat history is preserved

3. **Clear History:**
   - Go to Settings
   - Tap "Clear Chat History"
   - Confirm the action
   - Verify chat resets to just the welcome message

## Troubleshooting

If the app doesn't build or run:

1. Check the Xcode console for error messages
2. Make sure all required files are included in the target
3. Verify that Info.plist contains all necessary permissions
4. Check that the character image is properly added to Assets.xcassets

## Next Steps for Development

- Add more detailed character animations
- Integrate with a real AI service
- Implement real location search using MapKit
- Add voice interaction capabilities
- Enhance UI with more polished design elements
