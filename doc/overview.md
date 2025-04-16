# ShowCaseView
# #
A Flutter package that allows you to showcase or highlight your widgets step by step, providing interactive tutorials for your application's UI.

## Features

- Guide user through your app by highlighting specific widget step by step
- Customize tooltips with titles, descriptions, and styling
- Auto-scroll to showcase elements outside the current viewport
- Support for custom tooltip widgets
- Animation and transition effects for tooltip
- Options to showcase multiple widget at the same time

## Preview

![The example app running in Android](https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_showcaseview/master/preview/showcaseview.gif)

## Key Components

- **ShowCaseWidget**: The parent widget that manages showcase interactions
- **Showcase**: Widget to create default showcases with titles and descriptions
- **Showcase.withWidget**: Widget to create custom showcase tooltips

## Main Use Cases

- App onboarding experiences
- Feature introduction
- User guidance through complex interfaces
- Highlighting new features

## Installation

```yaml
dependencies:
  showcaseview: <latest-version>
```

## Basic Implementation

```dart
// Import the package
import 'package:showcaseview/showcaseview.dart';

// Define global keys for your showcases
GlobalKey _one = GlobalKey();
GlobalKey _two = GlobalKey();

// Wrap your app with ShowCaseWidget
ShowCaseWidget(
  builder: (context) => MyApp(),
),

// Add showcases to widgets
Showcase(
  key: _one,
  title: 'Menu',
  description: 'Click here to see menu options',
  child: Icon(Icons.menu),
),

// Start the showcase
void startShowcase() {
  ShowCaseWidget.of(context).startShowCase([_one, _two]);
}
```

## Customizations

The package offers extensive customization options for:
- Tooltip appearance and positioning
- Text styling and alignment
- Overlay colors and opacity
- Animation effects and durations
- Interactive controls
- Auto-scrolling behavior
