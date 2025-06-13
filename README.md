# HelpingHand iOS App

An intelligent location-based assistant that helps users find nearby places and services with AI-powered search capabilities.

## 🌟 Features

- **AI-Powered Search Intelligence**: Smart detection for Apple Store vs grocery store searches when users search for "apples"
- **Enhanced Emergency Services**: Comprehensive emergency contact system with one-tap calling
- **Real-time Location Services**: GPS-based location tracking with Dallas fallback
- **Multi-Category Search**: Support for restaurants, hotels, shopping, entertainment, and more
- **Premium Dark UI**: Lamborghini-inspired dark theme with yellow/orange accents
- **Intelligent Place Categorization**: Smart categorization of search results

## 🚀 Quick Start

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- OpenAI API Key (optional - app works with fallback responses)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/HelpingHand.git
cd HelpingHand
```

2. Install dependencies:
```bash
# Dependencies are automatically resolved via Swift Package Manager
open HelpingHand.xcodeproj
```

3. Configure API Key (optional):
```bash
# Copy the example secrets file
cp App/Config/secrets.json.example App/Config/secrets.json

# Edit with your OpenAI API key
# {
#   "OPENAI_API_KEY": "your-actual-api-key-here"
# }
```

4. Build and run:
- Select target device/simulator in Xcode
- Press `Cmd+R` to build and run

## 🛠 Architecture

### Core Components

- **AIService**: Handles intelligent query processing and Apple Store detection
- **LocationService**: GPS location management with multi-search capabilities
- **Place Models**: Enhanced categorization system for different location types
- **Emergency System**: Comprehensive emergency contact and calling functionality

### Key Features

#### Apple Store Search Intelligence
The app intelligently distinguishes between:
- **Apple Store searches**: "Apple Store near me", "buy iPhone", "Apple support"
- **Grocery searches**: "fresh apples", "organic apples", "grocery store apples"
- **Ambiguous searches**: "find apples" → searches both Apple Stores and grocery stores

#### Emergency Services
- 911 Emergency Services
- Poison Control Center
- Mental Health Crisis Hotline
- National Suicide Prevention
- Domestic Violence Hotline
- Child Abuse Hotline
- Animal Poison Control
- Disaster Distress Helpline

## 🔧 Configuration

### API Keys
The app supports multiple configuration methods:

1. **Environment Variables**: `OPENAI_API_KEY`
2. **Local Config File**: `App/Config/secrets.json` (gitignored)
3. **Fallback Mode**: Works without API key using predefined responses

### Location Services
- Requires location permission for optimal experience
- Falls back to Dallas, TX area when location unavailable
- Supports both real-time GPS and fallback locations

## 🧪 Testing

The project includes comprehensive tests for the Apple Store search intelligence:

```bash
# Run Apple Store search logic tests
swift TestAppleLogic.swift
```

## 📱 Screenshots

[Add screenshots of your app here]

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenAI for AI capabilities
- Apple MapKit for location services
- Swift Package Manager for dependency management

## 📞 Support

For support, email [your-email@example.com] or open an issue on GitHub.

---

**Note**: This app requires iOS 17.0+ and works best with location services enabled. API key configuration is optional - the app provides fallback functionality when no key is provided.
