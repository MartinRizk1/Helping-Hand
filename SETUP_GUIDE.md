# HelpingHand App Setup Guide

## 🚀 Quick Setup for Real AI Integration

### 1. OpenAI API Key Setup

To enable **real ChatGPT responses** instead of fallback messages:

1. **Get your OpenAI API Key:**
   - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
   - Sign up or log in to your account
   - Create a new API key
   - Copy the key (starts with `sk-...`)

2. **Add the key to your app:**
   - Open `App/Source/Configuration/APIConfig.swift`
   - Replace `"your-openai-api-key-here"` with your actual API key:
   ```swift
   let testKey = "sk-your-actual-openai-api-key-here"
   ```

3. **Alternative: Use Environment Variable (Recommended for production):**
   ```bash
   export OPENAI_API_KEY="sk-your-actual-openai-api-key-here"
   ```

### 2. Location Setup & Testing

#### For iOS Simulator:
1. **Set Custom Location:**
   - In simulator: `Device` → `Location` → `Custom Location`
   - Enter your actual coordinates or a test location
   - Example: New York (40.7128, -74.0060)

2. **Test Different Locations:**
   - Apple Park: 37.3349, -122.0090
   - Times Square: 40.7580, -73.9855
   - Your address coordinates (use Google Maps to find)

#### For Physical Device:
- Location will automatically use your real GPS coordinates
- Ensure location permissions are granted when prompted

### 3. Testing the Enhanced Features

#### Real AI Responses:
1. Start the app
2. Ask: "Find me Chinese restaurants"
3. With API key configured: You'll get personalized ChatGPT responses
4. Without API key: You'll get helpful fallback responses (but they'll be faster/more generic)

#### Location-Based Search:
1. Enable location permissions
2. Try these queries:
   - "Chinese food"
   - "Gas stations"
   - "Coffee shops nearby"
   - "Hotels"
   - "Pharmacies"

## 🔧 Build & Run

```bash
# Build the project
xcodebuild -project HelpingHand.xcodeproj -scheme HelpingHand -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run in simulator
open -a Simulator
xcodebuild -project HelpingHand.xcodeproj -scheme HelpingHand -destination 'platform=iOS Simulator,name=iPhone 15' build
```

Or use VS Code tasks:
- `Cmd+Shift+P` → `Tasks: Run Task` → `Build HelpingHand` or `Run HelpingHand`

## 🐛 Troubleshooting

### Location Issues:
- **Shows San Francisco by default:** This is normal in simulator - set custom location
- **No location updates:** Check location permissions in iOS Settings → Privacy → Location
- **Inaccurate location:** Enable "Precise Location" in app settings

### AI Response Issues:
- **Too fast/generic responses:** API key not configured - follow step 1 above
- **No responses:** Check internet connection and API key validity
- **API errors:** Verify your OpenAI account has credits/usage available

### Build Issues:
- **Code signing errors:** Project is configured for simulator - ensure you're building for simulator
- **Missing dependencies:** Clean build folder and rebuild

## 📱 Testing Scenarios

1. **Location Permission Flow:**
   - Fresh install → Grant location permission → Test search

2. **Different Cuisines:**
   - "Chinese restaurants"
   - "Italian food"
   - "Pizza places"
   - "Coffee shops"

3. **General Services:**
   - "Gas stations"
   - "Pharmacies"
   - "Banks"
   - "Hotels nearby"

4. **Conversational AI:**
   - "Hi there"
   - "What can you help me with?"
   - "I'm hungry"

## 🎯 Expected Behavior

### With OpenAI API Key:
- Responses take 1-3 seconds (real ChatGPT processing time)
- Personalized, conversational responses
- Context-aware suggestions
- Natural language understanding

### Without API Key (Fallback):
- Instant responses (< 1 second)
- Helpful but more generic responses
- Still functional location search
- Category-based suggestions

Both modes provide full location search functionality!
