# Helping Hand App - Test Execution Guide

This guide provides step-by-step instructions for performing a complete end-to-end test of the Helping Hand app.

## Prerequisites

Before starting the tests, ensure you have:

- macOS with Xcode 13.0+ installed
- Access to an iOS Simulator (iPhone 13 recommended)
- The Helping Hand project directory at `/Users/martinrizk/Desktop/Helping-Hand/`

## Testing Preparation

1. **Setup Character Image (Optional)**

   The app can run without a character image (it will use SF Symbols instead), but you can add one:

   ```bash
   cd /Users/martinrizk/Desktop/Helping-Hand/
   ./setup_character.sh
   ```

   Follow the prompts to either:

   - Use the default SF Symbols
   - Create a simple character image
   - Import an existing character image

2. **Run the Test Script**

   Execute the automated test script which will guide you through testing all features:

   ```bash
   cd /Users/martinrizk/Desktop/Helping-Hand/
   ./test_app.sh
   ```

   The script will:

   - Open the project in Xcode
   - Provide step-by-step instructions for testing
   - Verify the results of each test

## Manual Testing Checklist

If you prefer to test manually, follow these steps:

### 1. Launch the App

- Open the project in Xcode
- Select an iPhone simulator
- Build and run (Command+R)

### 2. Initial UI Test

Verify:

- Character appears at the top (either custom image or SF Symbol)
- Welcome message is displayed
- Text input field is present at the bottom

### 3. Window Repair Query Test

- Type: "I have a broken window"
- Tap the send button
- Verify:
  - Character mood changes to 'helping'
  - App responds with window repair information
  - Results show repair businesses
  - Tapping a result shows it on the map

### 4. Food Query Test

- Type: "Show me Chinese restaurants nearby"
- Tap the send button
- Verify:
  - Character mood changes to 'happy'
  - App responds about restaurants
  - Results show Chinese restaurants
  - Map displays restaurant locations when tapped

### 5. Hotel Query Test

- Type: "I need a place to stay tonight"
- Tap the send button
- Verify:
  - Character mood changes
  - App responds with hotel information
  - Results show accommodation options
  - Map shows hotel locations when tapped

### 6. Map Interaction Test

- Tap on a location in any results list
- Verify:
  - Map focuses on selected location
  - Detail card appears with information
  - Buttons for call, website, and directions are present

## Troubleshooting

If any issues occur during testing:

1. **App doesn't build:** Check Xcode for error messages
2. **No character appears:** The app will use SF Symbol fallbacks
3. **No map appears:** Make sure a location result is tapped
4. **Location services prompt:** The app is in test mode and doesn't require real location permissions

For more detailed information, refer to the full testing guide:
`/Users/martinrizk/Desktop/Helping-Hand/Helping-Hand/TESTING_GUIDE.md`
