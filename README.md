# Helping Hand

A mobile app designed to help people with user interface difficulties access assistance and resources in their area.

## Features

- Intuitive chat interface with character assistance
- Location-based services for finding help nearby
- Voice input support for accessibility
- Map integration for visualizing locations
- Dark mode and theme customization
- Persistent chat history
- Offline functionality with mock data

## Getting Started

### Prerequisites

- Xcode 13.0+
- iOS 14.0+
- macOS for development

### Installation

1. Clone the repository

```bash
git clone https://github.com/yourusername/Helping-Hand.git
cd Helping-Hand
```

2. Open the project in Xcode

```bash
open Helping-Hand.xcodeproj
```

3. Build and run using the iOS Simulator (iPhone 13 recommended)

### Test Mode

The app runs in test mode by default, which means:

- Mock data is used instead of real API calls
- Location permissions are not required
- Voice input uses simulated responses
- No API keys needed for development

To run the test suite:

```bash
./test_app.sh
```

## Project Structure

```
Helping-Hand/
├── Source/
│   ├── Models/         # Data models
│   ├── Views/          # SwiftUI views
│   ├── ViewModels/     # View business logic
│   └── Services/       # Core services
├── Assets.xcassets/    # Images and assets
└── Info.plist         # App configuration
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow SwiftUI best practices
- Use mock data for testing
- Don't commit API keys or sensitive data
- Update documentation for new features
- Add tests for new functionality

## Testing

The project includes several testing scripts:

- `test_app.sh` - Main testing suite
- `test_app_complete.sh` - End-to-end testing
- `test_new_features.sh` - New feature testing
- `generate_quality_report.sh` - Generate quality reports

See `TEST_EXECUTION_GUIDE.md` for detailed testing instructions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- SF Symbols for character fallback images
- SwiftUI for the modern UI framework
- CoreLocation and MapKit for mapping features
