# Helping-Hand

Helping Hand is an iOS application designed to assist users in finding local services through an interactive AI character interface. The app provides a friendly and accessible way to get information about nearby businesses, services, and points of interest.

## Features

- **Interactive Character Assistant**: Chat with a friendly character that responds to your queries in a conversational manner
- **Location-Based Services**: Find nearby businesses, restaurants, repair services, and more based on your location
- **Visual Map Interface**: See recommended locations on a map with detailed information
- **Accessibility-Focused Design**: Simple, intuitive interface designed for users with varying levels of technical ability
- **Persistent Chat History**: Conversations are saved between app sessions
- **Enhanced Character Animations**: Character responds with different moods and animations
- **Settings Menu**: Configure app options and clear history when needed
- **Voice Input**: Speak queries instead of typing for hands-free operation
- **Rich Location Details**: View comprehensive information about each location
- **Theme Support**: Choose between light, dark, or system appearance modes
- **Custom Accent Colors**: Personalize the app's look and feel

## Technology Stack

- SwiftUI for modern UI development
- Combine framework for reactive programming
- MapKit & CoreLocation for mapping and location services
- MVVM (Model-View-ViewModel) architecture

## Getting Started

1. Clone the repository
2. Open the project in Xcode
3. Build and run on an iOS Simulator or physical device

## Testing the App

The app includes a test script to guide you through testing all features:

```bash
cd /Users/martinrizk/Desktop/Helping-Hand
./test_app.sh
```

This will:

1. Open the project in Xcode
2. Guide you through running the app in the simulator
3. Test each core feature (window repair, restaurant search, hotels)
4. Verify map interactions and location details
5. Provide feedback on test results

The app runs in **Test Mode** by default, which means:

- No real location permissions are required
- Mock data is used for all searches
- All UI components will display correctly

For more detailed testing information, see `TESTING_GUIDE.md`

## Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

## Future Enhancements

- Voice interaction capabilities
- Expanded library of character animations
- Integration with real AI services
- Enhanced accessibility features
- Support for additional languages

## License

MIT License - See LICENSE file for details
