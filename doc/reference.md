# API References
# #
This document provides a reference for the main classes and properties of the ShowCaseView package.

## ShowCaseWidget Properties

| Property                      | Type                                       | Default Value              | Description                                                                    |
|-------------------------------|--------------------------------------------|-----------------------------|-------------------------------------------------------------------------------|
| builder                       | Builder                                    | -                           | Builder function for your app content                                          |
| blurValue                     | double                                     | 0                           | Provides blur effect on overlay                                                |
| autoPlay                      | bool                                       | false                       | Automatically display next showcase                                            |
| autoPlayDelay                 | Duration                                   | Duration(milliseconds: 2000) | Visibility time of showcase when `autoPlay` is enabled                         |
| enableAutoPlayLock            | bool                                       | false                       | Block user interaction when autoPlay is enabled                                |
| enableAutoScroll              | bool                                       | false                       | Auto scroll to make target visible                                             |
| scrollDuration                | Duration                                   | Duration(milliseconds: 300) | Time duration for auto scrolling                                               |
| disableBarrierInteraction     | bool                                       | false                       | Disable barrier interaction                                                    |
| disableScaleAnimation         | bool                                       | false                       | Disable scale transition for all showcases                                     |
| disableMovingAnimation        | bool                                       | false                       | Disable bouncing/moving transition for all showcases                           |
| onStart                       | Function(int?, GlobalKey)?                 | -                           | Triggered on start of each showcase                                            |
| onComplete                    | Function(int?, GlobalKey)?                 | -                           | Triggered on completion of each showcase                                       |
| onFinish                      | VoidCallback?                              | -                           | Triggered when all the showcases are completed                                 |
| onDismiss                     | OnDismissCallback?                         | -                           | Triggered when onDismiss is called                                             |
| enableShowcase                | bool                                       | true                        | Enable or disable showcase globally                                            |
| toolTipMargin                 | double                                     | 14                          | For tooltip margin                                                             |
| globalTooltipActionConfig     | TooltipActionConfig?                       | -                           | Global tooltip actionbar config                                                |
| globalTooltipActions          | List<TooltipActionButton>?                 | -                           | Global list of tooltip actions                                                 |
| scrollAlignment               | double                                     | 0.5                         | For auto scroll widget alignment                                               |
| globalFloatingActionWidget    | FloatingActionWidget Function(BuildContext)? | -                         | Global config for tooltip action                                               |
| hideFloatingActionWidgetForShowcase | List<GlobalKey>                      | []                          | Hides globalFloatingActionWidget for the provided showcase widget keys         |

## Showcase Properties

| Property                   | Type                 | Default Value                                      | Description                                                     |
|----------------------------|----------------------|----------------------------------------------------|------------------------------------------------------------------|
| key                        | GlobalKey            | -                                                  | Unique Global key for each showcase                              |
| child                      | Widget               | -                                                  | Target widget to be showcased                                    |
| title                      | String?              | -                                                  | Title of default tooltip                                         |
| description                | String?              | -                                                  | Description of default tooltip                                   |
| titleTextStyle             | TextStyle?           | -                                                  | Text Style of title                                              |
| descTextStyle              | TextStyle?           | -                                                  | Text Style of description                                        |
| titleTextAlign             | TextAlign            | TextAlign.start                                    | Alignment of title text                                          |
| descriptionTextAlign       | TextAlign            | TextAlign.start                                    | Alignment of description text                                    |
| titleAlignment             | AlignmentGeometry    | Alignment.center                                   | Alignment of title                                               |
| descriptionAlignment       | AlignmentGeometry    | Alignment.center                                   | Alignment of description                                         |
| targetShapeBorder          | ShapeBorder          | -                                                  | Shape border of target widget                                    |
| targetBorderRadius         | BorderRadius?        | -                                                  | Border radius of target widget                                   |
| tooltipBorderRadius        | BorderRadius?        | BorderRadius.circular(8.0)                         | Border radius of tooltip                                         |
| blurValue                  | double?              | `ShowCaseWidget.blurValue`                         | Gaussian blur effect on overlay                                  |
| tooltipPadding             | EdgeInsets           | EdgeInsets.symmetric(vertical: 8, horizontal: 8)   | Padding to tooltip content                                       |
| targetPadding              | EdgeInsets           | EdgeInsets.zero                                    | Padding to target widget                                         |
| overlayOpacity             | double               | 0.75                                               | Opacity of overlay layer                                         |
| overlayColor               | Color                | Colors.black45                                     | Color of overlay layer                                           |
| tooltipBackgroundColor     | Color                | Colors.white                                       | Background Color of default tooltip                              |
| textColor                  | Color                | Colors.black                                       | Color of tooltip text                                            |
| showArrow                  | bool                 | true                                               | Shows tooltip with arrow                                         |
| disposeOnTap               | bool?                | false                                              | Dismiss all showcases on target/tooltip tap                      |
| tooltipPosition            | TooltipPosition?     | -                                                  | Vertical position of tooltip respective to target                |
| disableDefaultTargetGestures | bool               | false                                              | Disable default gestures of target widget                        |

## Showcase.withWidget Properties

In addition to most of the properties from `Showcase`, `Showcase.withWidget` includes:

| Property   | Type     | Default Value | Description                          |
|------------|----------|---------------|--------------------------------------|
| container  | Widget?  | -             | Custom tooltip widget                |
| height     | double?  | -             | Height of custom tooltip widget      |
| width      | double?  | -             | Width of custom tooltip widget       |

## TooltipActionButton Properties

| Property                    | Type              | Default Value                                 | Description                                              |
|-----------------------------|--------------------|-----------------------------------------------|----------------------------------------------------------|
| type                        | TooltipButtonType  | -                                             | Type of action button (next, skip, previous)             |
| backgroundColor             | Color?             | -                                             | Background color of action button                         |
| borderRadius                | BorderRadius?      | BorderRadius.all(Radius.circular(50))         | Border radius of action button                            |
| textStyle                   | TextStyle?         | -                                             | Text style for button name                                |
| padding                     | EdgeInsets?        | EdgeInsets.symmetric(horizontal: 15,vertical: 4) | Padding to button content                            |
| leadIcon                    | ActionButtonIcon?  | -                                             | Icon before name in action button                         |
| tailIcon                    | ActionButtonIcon?  | -                                             | Icon after name in action button                          |
| name                        | String?            | -                                             | Action button name                                        |
| onTap                       | VoidCallback?      | -                                             | Callback when action button is tapped                     |
| hideActionWidgetForShowcase | List<GlobalKey>    | []                                            | Hide action widget for specified showcase keys            |

## TooltipActionConfig Properties

| Property                  | Type                  | Default Value                | Description                                       |
|---------------------------|------------------------|------------------------------|---------------------------------------------------|
| alignment                 | MainAxisAlignment      | MainAxisAlignment.spaceBetween | Horizontal alignment of tooltip action buttons   |
| crossAxisAlignment        | CrossAxisAlignment     | CrossAxisAlignment.start      | Vertical alignment of tooltip action buttons     |
| actionGap                 | double?                | 5                            | Gap between tooltip action buttons                |
| position                  | TooltipActionPosition? | TooltipActionPosition.inside  | Position of tooltip actionbar (inside, outside)   |
| gapBetweenContentAndAction | double?               | 10                           | Gap between tooltip content and actionbar         |

## ShowCaseWidget Methods

| Method                                    | Description                |
|-------------------------------------------|----------------------------|
| startShowCase(List<GlobalKey> widgetIds)  | Starts the showcase        |
| next()                                    | Go to next showcase        |
| previous()                                | Go to previous showcase    |
| dismiss()                                 | Dismiss all showcases      |

## Enums

### TooltipPosition
- `TooltipPosition.top`: Display tooltip above the target
- `TooltipPosition.bottom`: Display tooltip below the target

### TooltipActionPosition
- `TooltipActionPosition.inside`: Display action buttons inside the tooltip
- `TooltipActionPosition.outside`: Display action buttons outside the tooltip

### TooltipButtonType
- `TooltipButtonType.next`: Next button
- `TooltipButtonType.previous`: Previous button  
- `TooltipButtonType.skip`: Skip/finish button
