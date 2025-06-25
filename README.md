# HelpingHand iOS App

An advanced AI-powered location service that learns your preferences and provides intelligent, personalized recommendations using machine learning and natural language processing.

## 🧠 Advanced AI & Machine Learning Features

- **🎯 Personalized Recommendations**: ML-powered place ranking based on your behavior patterns
- **🗣 Natural Language Processing**: Advanced query understanding with intent detection and sentiment analysis
- **🤖 On-Device Intelligence**: TensorFlow Lite integration for real-time preference prediction
- **📊 Continuous Learning**: Core ML models that improve from your interactions
- **🌍 Hybrid Search**: Combines MapKit and Google Places API with AI ranking
- **🎨 Context-Aware Results**: Considers time, location, weather, and activity patterns

## 🌟 Core Features

- **Smart Query Processing**: Intelligently distinguishes "Apple Store" vs "grocery store apples"
- **Real-Time Learning**: Adapts to your preferences with every interaction
- **Enhanced Emergency Services**: Comprehensive emergency contact system
- **Advanced Location Tracking**: GPS-based with intelligent fallback
- **Multi-Source Search**: MapKit + Google Places + AI ranking
- **Premium Dark UI**: Lamborghini-inspired design with intelligent place highlighting

## 🚀 AI/ML Technology Stack

### Machine Learning Models
- **User Preference Model**: Predicts your likelihood to prefer specific places
- **Place Recommendation Engine**: Ranks results based on personal behavior patterns
- **Contextual Embeddings**: Semantic understanding of queries and place descriptions
- **Intent Classification**: Automatically detects what you're looking for

### Natural Language Processing
- **Query Analysis**: Tokenization, named entity recognition, sentiment analysis
- **Semantic Search**: Understanding context beyond simple keyword matching
- **Ambiguity Resolution**: Smart handling of queries with multiple meanings
- **Confidence Scoring**: AI confidence levels for better user experience

### Data Intelligence
- **Behavioral Analytics**: Learns from interaction duration, selections, and patterns
- **Temporal Preferences**: Understands time-based preferences (morning coffee, lunch spots)
- **Location Familiarity**: Recognizes and adapts to your familiar areas
- **Privacy-First Learning**: All learning happens on-device with anonymous data

## 🚀 Quick Start

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- OpenAI API Key (for enhanced AI responses)
- Google Places API Key (for comprehensive place data)

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

3. Configure API Keys:
```bash
# Copy the example secrets file
cp App/Config/secrets.json.example App/Config/secrets.json

# Edit with your API keys
# {
#   "openai_api_key": "your-openai-api-key-here",
#   "google_places_api_key": "your-google-places-api-key-here"
# }
```

4. Build and run:
- Select target device/simulator in Xcode
- Press `Cmd+R` to build and run
- The app works with fallback functionality even without API keys

## 🧠 AI/ML Architecture

## 🧠 AI/ML Architecture

### Advanced Services Layer
- **AIService**: Enhanced NLP with intent detection and semantic analysis
- **TensorFlowLiteService**: On-device ML inference for real-time predictions
- **UserPreferenceService**: Core ML-based behavioral learning and preference management
- **GooglePlacesService**: Rich place data integration with AI-enhanced search
- **MLModelTrainingService**: Continuous learning infrastructure with automated retraining
- **LocationService**: Hybrid search combining multiple data sources with ML ranking

### Intelligence Pipeline
```
User Query → NLP Analysis → Intent Detection → Multi-Source Search → 
ML Ranking → Personalization → Context Filtering → Smart Results
```

### Key AI/ML Features

#### Advanced Search Intelligence
- **Contextual Understanding**: "apple" → Apple Store (tech context) vs grocery stores (food context)
- **Multi-Intent Queries**: Handles complex queries with multiple search intentions
- **Semantic Similarity**: Beyond keyword matching to understand meaning
- **Real-Time Adaptation**: Learns and adapts during each session

#### Personalization Engine
- **Behavioral Pattern Recognition**: Learns from every interaction and decision
- **Temporal Preferences**: Morning coffee spots, lunch restaurants, evening entertainment
- **Location-Based Learning**: Familiar areas vs exploration preferences
- **Activity Context**: Business meetings, leisure time, emergency situations

#### Intelligent Data Fusion
- **Hybrid Search Results**: MapKit + Google Places + AI ranking
- **Duplicate Detection**: Smart deduplication using Levenshtein distance
- **Quality Scoring**: ML-based relevance and quality assessment
- **Confidence Weighting**: Higher weight for well-established user preferences

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
