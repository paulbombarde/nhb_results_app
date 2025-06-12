# nhb_results_app

A Flutter application to retrieve match results for the Nyon Handball - La Cote and generate png images to be shared on social media.

## High level information

### Image templates

The images are created based on a set of svg templates. Several templates are available. They will be used in various usecases, depending on the number of matches to display, with special one for the two senior teams. The SVGs files have ids for specific strings to be replaced by real data.

### Data retrieval

The match results will be retrieved from the official website of the Swiss Handball Federation (FSH). 
Details of that mechanism can be found in Query.md.

### Names replacement

The official team names sometime does not fit in the templates, or some teams are better known but a different name. Some replacement strings will be provided later.

## Install and run

### Development Tools Required

- **Flutter SDK**: Compatible with Dart SDK ^3.5.3
- **Dart SDK**: ^3.5.3
- **Android Studio** or **VS Code**: For development environment
- **Xcode**: Required for iOS development
- **Git**: For version control

### Installation Links

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio)
- [VS Code](https://code.visualstudio.com/download)
- [Xcode](https://developer.apple.com/xcode/) (macOS only)
- [Git](https://git-scm.com/downloads)

### Setup Instructions

```bash
# Clone the repository
git clone https://github.com/yourusername/nhb_results_app.git

# Navigate to project directory
cd nhb_results_app

# Install dependencies
flutter pub get
```

### Running the App

This project supports multiple platforms. For platform-specific instructions, refer to the official Flutter documentation:

- [Run on Android](https://docs.flutter.dev/get-started/test-drive?tab=androidstudio#run-the-app)
- [Run on iOS](https://docs.flutter.dev/get-started/test-drive?tab=androidstudio#run-the-app-on-ios)
- [Run on Web](https://docs.flutter.dev/get-started/web)
- [Run on Desktop](https://docs.flutter.dev/desktop)


## Flutter resources for reference

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
