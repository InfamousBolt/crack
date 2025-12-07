# Interview Helper

A Flutter app that helps with interview preparation by providing camera feed, questions, and answers.

## Features

- **Camera Screen**: Live camera feed for video interviews
- **Questions Screen**: Interview questions (coming soon)
- **Answers Screen**: Suggested answers (coming soon)
- **Permissions**: Automatically requests camera and microphone permissions

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Xcode (for iOS development)
- An iPhone or iOS simulator
- Apple Developer account (for running on physical iPhone)

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Running on iPhone Simulator

```bash
# List available simulators
flutter devices

# Run on iOS simulator
flutter run
```

### 3. Running on Physical iPhone

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Select your development team in Signing & Capabilities
   - Connect your iPhone via USB
   - Trust the computer on your iPhone if prompted
   - Select your iPhone as the target device
   - Build and run (⌘ + R)

Or use Flutter CLI:
```bash
# Connect your iPhone via USB
# Trust the computer on your iPhone

# Run on connected iPhone
flutter run
```

### 4. Permissions

The app will automatically request the following permissions on first launch:
- **Camera**: Required to show live camera feed
- **Microphone**: Required for audio recording during interviews

If permissions are denied, the app will prompt you to open Settings to enable them.

## Project Structure

```
lib/
├── main.dart                 # Main app entry point with bottom navigation
└── screens/
    ├── camera_screen.dart    # Camera feed screen
    ├── questions_screen.dart # Questions screen (placeholder)
    └── answers_screen.dart   # Answers screen (placeholder)
```

## Troubleshooting

### Camera not working on simulator
The iOS simulator doesn't support camera hardware. You'll need to run the app on a physical iPhone to test camera functionality.

### Permission denied
If permissions are denied:
1. Go to iPhone Settings
2. Scroll down to "Interview Helper"
3. Enable Camera and Microphone permissions
4. Restart the app

### Build errors
If you encounter build errors:
```bash
# Clean build files
flutter clean

# Get dependencies again
flutter pub get

# Try running again
flutter run
```

## Tech Stack

- **Flutter**: Cross-platform framework
- **camera**: Camera plugin for Flutter
- **permission_handler**: Permission handling plugin

## Development

This app uses:
- Material Design 3
- Bottom Navigation Bar for screen switching
- Permission handling with user-friendly dialogs
- Front-facing camera for interview scenarios

## Next Steps

- Implement questions database
- Add answer suggestions
- Implement interview recording
- Add AI-powered interview assistance
