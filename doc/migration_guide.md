# Migration Guides
# #
This document provides guidance for migrating between different versions of the ShowCaseView package.

## Migration guide for release 4.0.0

The 4.0.0 release includes changes to parameter names to better reflect their purpose and behavior.

### Parameter Renaming

The parameters `titleAlignment` and `descriptionAlignment` have been renamed to `titleTextAlign` and `descriptionTextAlign` to correspond more accurately with the TextAlign property. The original parameter names `titleAlignment` and `descriptionAlignment` are now reserved for widget alignment.

#### Before (Pre-4.0.0):

```dart
Showcase(
  titleAlignment: TextAlign.center,
  descriptionAlignment: TextAlign.center,
),
```

#### After (4.0.0+):

```dart
Showcase(
  titleTextAlign: TextAlign.center,
  descriptionTextAlign: TextAlign.center,
),
```

## Migration guide for release 3.0.0

The 3.0.0 release simplified the API by removing the need for a Builder widget in the ShowCaseWidget.

### Builder Widget Removal

The `ShowCaseWidget` no longer requires a `Builder` widget and instead accepts a builder function directly.

#### Before (Pre-3.0.0):

```dart
ShowCaseWidget(
  builder: Builder(
    builder: (context) => SomeWidget()
  ),
),
```

#### After (3.0.0+):

```dart
ShowCaseWidget(
  builder: (context) => SomeWidget(),
),
```

## Tips for Smooth Migration

1. Run `flutter pub upgrade showcaseview` to get the latest version
2. Do a search in your codebase for the old parameter names and update them
3. For large applications, consider updating one screen at a time to ensure stability
4. Test thoroughly after migration to ensure all showcase functionality still works as expected

## Breaking Changes History

### 4.0.0
- Renamed `titleAlignment` to `titleTextAlign`
- Renamed `descriptionAlignment` to `descriptionTextAlign`

### 3.0.0
- Removed Builder widget from `ShowCaseWidget`
- Changed builder property to accept a function directly

For a complete list of changes and new features in each version, please refer to the [release notes](https://github.com/SimformSolutionsPvtLtd/flutter_showcaseview/releases) on GitHub.
