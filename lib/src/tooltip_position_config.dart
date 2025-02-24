import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'enum.dart';
import 'tooltip_widget.dart';

class TooltipPositionConfig {
  TooltipPositionConfig({
    required this.position,
    required this.size,
    required this.screenSize,
    required this.actionSize,
    required this.widgetRect,
    required this.tooltipMargin,
    required this.tooltipPadding,
    required this.toolTipSlideEndDistance,
  });

  final TooltipPosition position;
  final Size size;
  final Size screenSize;
  final Size? actionSize;
  final Rect? widgetRect;
  final double tooltipMargin;
  final EdgeInsets? tooltipPadding;
  final double toolTipSlideEndDistance;

  double? leftPosition;
  double? rightPosition;
  double? topPosition;
  double? arrowLeft;
  double? arrowRight;

  Alignment alignment = Alignment.center;
  Alignment scaleAnimAlign = Alignment.center;
  EdgeInsets padding = EdgeInsets.zero;
  EdgeInsets arrowPadding = EdgeInsets.zero;
  double offsetFactor = 0;
  Offset fractionalTranslation = Offset.zero;
  Tween<Offset> slideTween = Tween();

  void initialize() {
    leftPosition = _getLeft();
    rightPosition = _getRight(leftPosition);
    topPosition = _getTop();

    arrowLeft = _arrowLeft();
    arrowRight = _arrowRight();
    alignment = _getAlignment();
    scaleAnimAlign = _getScaleAlignment();

    padding = _contentPadding();
    arrowPadding = _arrowPadding();
    offsetFactor = _getOffsetFactor;
    fractionalTranslation = _getFractionalTranslation;
    slideTween = _getSlideTween;
  }

  double get _getOffsetFactor {
    switch (position) {
      case TooltipPosition.top:
        return -1;
      case TooltipPosition.left:
      case TooltipPosition.right:
      case TooltipPosition.bottom:
        return 1;
    }
  }

  Offset get _getFractionalTranslation {
    final offset = offsetFactor.clamp(-1, 0).toDouble();
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        return Offset(0, offset);
      case TooltipPosition.left:
      case TooltipPosition.right:
        return Offset(offset, 0);
    }
  }

  Tween<Offset> get _getSlideTween {
    final offset = offsetFactor * toolTipSlideEndDistance;
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        return Tween<Offset>(
          begin: Offset.zero,
          end: Offset(0, offset),
        );
      case TooltipPosition.right:
      case TooltipPosition.left:
        return Tween<Offset>(
          begin: Offset.zero,
          end: Offset(offset, 0),
        );
    }
  }

  Alignment _getScaleAlignment() {
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        if (widgetRect == null) return Alignment.center;
        final widgetCenter = (widgetRect!.left + widgetRect!.right) * 0.5;
        final left = leftPosition == null ? 0 : widgetCenter - leftPosition!;
        var right = leftPosition == null
            ? (screenSize.width - widgetCenter) - (rightPosition ?? 0)
            : 0;

        final x = left == 0
            ? 1 - (2 * (right / size.width))
            : -1 + (2 * (left / size.width));

        final y = position.isBottom ||
                (screenSize.height * 0.5) < (widgetRect?.top ?? 0)
            ? -1.0
            : 1.0;

        return Alignment(x, y);
      case TooltipPosition.left:
        return Alignment.centerRight;
      case TooltipPosition.right:
        return Alignment.centerLeft;
    }
  }

  Alignment _getAlignment() {
    switch (position) {
      case TooltipPosition.top:
        return leftPosition == null
            ? Alignment.bottomRight
            : Alignment.bottomLeft;
      case TooltipPosition.bottom:
        return Alignment.topLeft;
      case TooltipPosition.left:
        return Alignment.centerRight;
      case TooltipPosition.right:
        return Alignment.centerLeft;
    }
  }

  EdgeInsets _arrowPadding() {
    const padding = kWithArrowToolTipPadding - kDefaultArrowHeight;
    switch (position) {
      case TooltipPosition.left:
        return const EdgeInsets.only(right: padding);
      case TooltipPosition.top:
        return const EdgeInsets.only(bottom: padding);
      case TooltipPosition.right:
        return const EdgeInsets.only(left: padding);
      case TooltipPosition.bottom:
        return const EdgeInsets.only(top: padding);
    }
  }

  EdgeInsets _contentPadding() {
    const padding = kDefaultArrowHeight - 1;
    switch (position) {
      case TooltipPosition.left:
      case TooltipPosition.right:
        return EdgeInsets.zero;
      case TooltipPosition.top:
        return const EdgeInsets.only(bottom: padding);
      case TooltipPosition.bottom:
        return const EdgeInsets.only(top: padding);
    }
  }

  double? _arrowLeft() {
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        if (widgetRect == null || leftPosition == null) return null;
        final widgetCenter = (widgetRect!.left + widgetRect!.right) * 0.5;
        return widgetCenter - (kDefaultArrowWidth * 0.5) - leftPosition!;
      case TooltipPosition.left:
      case TooltipPosition.right:
        return leftPosition == null ? null : -kDefaultArrowHeight * 0.88;
    }
  }

  double? _arrowRight() {
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        if (widgetRect == null || leftPosition != null) return null;
        final widgetCenter = (widgetRect!.left + widgetRect!.right) * 0.5;
        return (screenSize.width - widgetCenter) -
            (rightPosition ?? 0) -
            (kDefaultArrowWidth * 0.5);
      case TooltipPosition.left:
      case TooltipPosition.right:
        return leftPosition == null ? -kDefaultArrowWidth * 0.48 : null;
    }
  }

  double? _getLeft() {
    if (widgetRect == null) return null;
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        final widgetCenter = (widgetRect!.left + widgetRect!.right) * 0.5;
        final leftPos = widgetCenter - (size.width * 0.5);
        return (leftPos + size.width) > screenSize.width
            ? null
            : max(tooltipMargin, leftPos);
      case TooltipPosition.left:
      case TooltipPosition.right:
        final space = widgetRect!.right + tooltipMargin;
        return (space + size.width) >= screenSize.width ? null : space;
    }
  }

  double? _getTop() {
    if (widgetRect == null) return null;
    switch (position) {
      case TooltipPosition.top:
        return widgetRect!.top + (offsetFactor * 3);
      case TooltipPosition.bottom:
        final bottomPos = widgetRect!.bottom + (offsetFactor * 3);
        // if tooltip is going beyond the bottom part of the screen then this
        // will adjust for the visibility.
        if ((bottomPos + size.height) >= screenSize.height) {
          return screenSize.height - size.height;
        } else {
          return bottomPos;
        }
      case TooltipPosition.left:
      case TooltipPosition.right:
        final widgetCenterVertical =
            widgetRect!.top + ((widgetRect!.bottom - widgetRect!.top) * 0.5);
        print('inside size:$size action:$actionSize');
        // TODO: subtract action padding if it is outside
        final topPos = widgetCenterVertical -
            ((size.height
                // -
                // (tooltipPadding?.vertical ?? 0) -
                // 50 -
                // (actionSize?.height ?? 0))
                ) *
                0.5);
        // ((size.height * 0.5) - (tooltipPadding?.vertical ?? 0));
        print('$topPos padding: ${tooltipPadding?.vertical}');
        return topPos.isNegative ? null : topPos;
    }
  }

  double? _getRight(double? left) {
    if (widgetRect == null) return null;
    switch (position) {
      case TooltipPosition.top:
      case TooltipPosition.bottom:
        if (left == null || (left + size.width) > screenSize.width) {
          final widgetCenter = (widgetRect!.left + widgetRect!.right) * 0.5;
          final rightPosition = widgetCenter + (size.width * 0.5);
          return (rightPosition + size.width) > screenSize.width
              ? tooltipMargin
              : null;
        } else {
          return null;
        }
      case TooltipPosition.left:
      case TooltipPosition.right:
        if (left != null) return null;
        final widgetLeft = widgetRect!.left - tooltipMargin;
        return (widgetLeft - size.width).isNegative
            ? null
            : screenSize.width - widgetLeft;
    }
  }
}
