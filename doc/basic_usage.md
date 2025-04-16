# Basic Usage
# #
This guide covers the fundamental implementation of ShowCaseView in your Flutter application.

## Setup ShowCaseWidget

First, wrap your main widget with the `ShowCaseWidget`:

```dart
ShowCaseWidget(
  builder: (context) => MyHomePage(),
),
```

## Define Global Keys

Create global keys for each widget you want to showcase:

```dart
// Define in your widget class
final GlobalKey _one = GlobalKey();
final GlobalKey _two = GlobalKey();
final GlobalKey _three = GlobalKey();
```

## Add Showcase to Widgets

Wrap each target widget with a `Showcase` widget:

```dart
Showcase(
  key: _one,
  title: 'Menu',
  description: 'Click here to see menu options',
  child: Icon(
    Icons.menu,
    color: Colors.black45,
  ),
)
```

## Start the Showcase

There are several ways to start the showcase sequence:

### On Button Press

```dart
ElevatedButton(
  child: Text('Start Showcase'),
  onPressed: () {
    ShowCaseWidget.of(context).startShowCase([_one, _two, _three]);
  },
)
```

### On Screen Load

To start showcase immediately after the screen loads:

```dart
@override
void initState() {
  super.initState();
  // Delayed execution to ensure the UI is fully rendered
  WidgetsBinding.instance.addPostFrameCallback((_) =>
    ShowCaseWidget.of(context).startShowCase([_one, _two, _three])
  );
}
```

### After Animation

If your UI has animations, you can start the showcase after they complete:

```dart
WidgetsBinding.instance.addPostFrameCallback((_) =>
  ShowCaseWidget.of(context).startShowCase(
    [_one, _two, _three], 
    delay: Duration(milliseconds: 500)
  )
);
```

## Example

Here's a complete basic example:

```dart
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShowCase Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ShowCaseWidget(
        builder: (context) => MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Start showcase after the screen is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) =>
      ShowCaseWidget.of(context).startShowCase([_one, _two])
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ShowCase Example'),
        leading: Showcase(
          key: _one,
          title: 'Menu',
          description: 'Click here to see menu options',
          child: Icon(Icons.menu),
        ),
      ),
      floatingActionButton: Showcase(
        key: _two,
        title: 'Add',
        description: 'Click here to add new items',
        child: FloatingActionButton(
          onPressed: () {},
          child: Icon(Icons.add),
        ),
      ),
      body: Center(
        child: Text('ShowCase Example'),
      ),
    );
  }
}
```
