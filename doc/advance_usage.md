# Advanced Usage

This guide covers more advanced features and customizations of the ShowCaseView package.

## Custom Tooltip Widget

Use `Showcase.withWidget` to create a completely custom tooltip:

```dart
Showcase.withWidget(
  key: _customKey,
  height: 80,
  width: 140,
  targetShapeBorder: CircleBorder(),
  container: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text('Custom Tooltip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      SizedBox(height: 5),
      Text('This is a completely custom tooltip widget', style: TextStyle(color: Colors.white)),
    ],
  ),
  child: Icon(Icons.star),
)
```

## Multi-Showcase View

To show multiple showcases simultaneously, use the same key for multiple showcase widgets:

```dart
// Both will be displayed at the same time
Showcase(
  key: _multiKey,
  title: 'First Widget',
  description: 'This is the first widget',
  child: Icon(Icons.star),
),

Showcase(
  key: _multiKey,
  title: 'Second Widget',
  description: 'This is the second widget',
  child: Icon(Icons.favorite),
),
```

> Note: Auto-scroll does not work with multi-showcase, and properties of the first initialized showcase are used for common settings like barrier tap and colors.

## Advanced Styling

Customize the appearance of showcases:

```dart
Showcase(
  key: _styleKey,
  title: 'Styled Showcase',
  description: 'This showcase has custom styling',
  titleTextStyle: TextStyle(
    color: Colors.red,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
  descTextStyle: TextStyle(
    color: Colors.green,
    fontSize: 16,
    fontStyle: FontStyle.italic,
  ),
  tooltipBackgroundColor: Colors.black87,
  targetPadding: EdgeInsets.all(8),
  targetBorderRadius: BorderRadius.circular(8),
  tooltipBorderRadius: BorderRadius.circular(16),
  child: MyWidget(),
)
```

## Auto Play

Enable auto play to automatically advance through showcases:

```dart
ShowCaseWidget(
  autoPlay: true,
  autoPlayDelay: Duration(milliseconds: 3000),
  enableAutoPlayLock: true,
  builder: (context) => MyApp(),
)
```

## Auto Scrolling

Enable auto scrolling to automatically bring off-screen showcase widgets into view:

```dart
ShowCaseWidget(
  enableAutoScroll: true,
  scrollDuration: Duration(milliseconds: 500),
  scrollAlignment: 0.5, // Center the widget in the viewport
  builder: (context) => MyScrollableApp(),
)
```

## Custom Scroll Controller

For complex scroll views like `ListView` or `GridView`, you might need a custom scroll controller:

```dart
final _controller = ScrollController();

ShowCaseWidget(
  onStart: (index, key) {
    if(index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Scroll to approximate position of the showcase widget
        _controller.jumpTo(1000);
      });
    }
  },
  builder: (context) => MyApp(),
),

// In your ListView:
ListView.builder(
  controller: _controller,
  itemCount: 100,
  itemBuilder: (context, index) {
    // Your list items
  },
)
```

## Tooltip Actions

Add action buttons to tooltips:

```dart
Showcase(
  key: _actionKey,
  title: 'With Actions',
  description: 'This showcase has action buttons',
  tooltipActions: [
    TooltipActionButton(
      type: TooltipActionButtonType.previous,
      backgroundColor: Colors.blue,
      textStyle: TextStyle(color: Colors.white),
      name: 'Previous',
    ),
    TooltipActionButton(
      type: TooltipActionButtonType.next,
      backgroundColor: Colors.green,
      textStyle: TextStyle(color: Colors.white),
      name: 'Next',
    ),
    TooltipActionButton(
      type: TooltipActionButtonType.skip,
      backgroundColor: Colors.red,
      textStyle: TextStyle(color: Colors.white),
      name: 'Skip',
    ),
  ],
  tooltipActionConfig: TooltipActionConfig(
    alignment: MainAxisAlignment.spaceEvenly,
    position: TooltipActionPosition.outside,
  ),
  child: MyWidget(),
)
```

## Custom Floating Action Widget

Add a floating action widget that appears during showcases:

```dart
Showcase(
  key: _floatingKey,
  title: 'With Floating Widget',
  description: 'This showcase has a floating widget',
  floatingActionWidget: (_) => Positioned(
    bottom: 20,
    right: 20,
    child: ElevatedButton(
      onPressed: () {
        // Custom action
      },
      child: Text('Custom Action'),
    ),
  ),
  child: MyWidget(),
)
```

## Showcase Control Methods

Programmatically control the showcase flow:

```dart
// Navigate to next showcase
ShowCaseWidget.of(context).next();

// Navigate to previous showcase
ShowCaseWidget.of(context).previous();

// Dismiss all showcases
ShowCaseWidget.of(context).dismiss();
```

## Event Callbacks

Handle showcase events:

```dart
ShowCaseWidget(
  onStart: (index, key) {
    print('Started showcase $index');
  },
  onComplete: (index, key) {
    print('Completed showcase $index');
  },
  onFinish: () {
    print('All showcases completed');
  },
  onDismiss: (reason) {
    print('Showcase dismissed because: $reason');
  },
  builder: (context) => MyApp(),
)
```
