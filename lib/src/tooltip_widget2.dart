import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'enum.dart';
import 'get_position.dart';
import 'models/tooltip_action_config.dart';
import 'widget/action_widget.dart';
import 'widget/floating_action_widget.dart';

const arrowWidth = 18.0;
const arrowHeight = 9.0;

class TooltipLayoutSlot {
  static const String firstBox = 'firstBox';
  static const String secondBox = 'secondBox';
  static const String arrow = 'arrow';
}

// Custom RenderObject for tooltip multi-child layout
class RenderTooltipMultiChildLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  RenderTooltipMultiChildLayoutBox({
    required this.targetPosition,
    required this.targetSize,
    required this.position,
    required this.screenSize,
    required this.hasSecondBox,
    required this.hasArrow,
    required this.toolTipSlideEndDistance,
    required this.gapBetweenContentAndAction,
    required this.screenEdgePadding,
  });

  Offset targetPosition;
  Size targetSize;
  TooltipPosition? position;
  Size screenSize;
  bool hasSecondBox;
  bool hasArrow;
  double toolTipSlideEndDistance;
  double gapBetweenContentAndAction;
  double screenEdgePadding;

  // Constants for padding
  final _withArrowToolTipPadding = 7.0;
  final _withOutArrowToolTipPadding = 7.0;

  final _tooltipOffset = 10.0;
  final arrowWidth = 14.0;
  final arrowHeight = 7.0;

  late TooltipPosition tooltipPosition;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void performLayout() {
    // Always set a size for this render object first to prevent layout errors
    size = constraints.biggest;

    // Initialize variables for child sizes
    Size firstBoxSize = Size.zero;
    Size secondBoxSize = Size.zero;

    // Find children by ID
    RenderBox? firstBox;
    RenderBox? secondBox;
    RenderBox? arrowBox;

    // Find children by ID
    RenderBox? child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData =
          child.parentData! as MultiChildLayoutParentData;

      if (childParentData.id == TooltipLayoutSlot.firstBox) {
        firstBox = child;
      } else if (childParentData.id == TooltipLayoutSlot.secondBox) {
        secondBox = child;
      } else if (childParentData.id == TooltipLayoutSlot.arrow) {
        arrowBox = child;
      }

      child = childParentData.nextSibling;
    }

    // Layout first box with loose constraints initially
    if (firstBox != null) {
      firstBox.layout(const BoxConstraints.tightFor(width: null, height: null),
          parentUsesSize: true);
      firstBoxSize = firstBox.size;
    }

    // Layout second box (if exists) with loose constraints initially
    if (hasSecondBox && secondBox != null) {
      secondBox.layout(
        const BoxConstraints.tightFor(width: null, height: null),
        parentUsesSize: true,
      );
      secondBoxSize = secondBox.size;
    }

    // Layout arrow (if exists) early to avoid RenderCustomPaint errors
    if (hasArrow && arrowBox != null) {
      arrowBox.layout(
          BoxConstraints.tightFor(width: arrowWidth, height: arrowHeight),
          parentUsesSize: true);
    }

    // Make sure boxes have consistent width
    if (secondBoxSize.width > firstBoxSize.width && firstBox != null) {
      firstBox.layout(
          BoxConstraints.tightFor(width: secondBoxSize.width, height: null),
          parentUsesSize: true);
      firstBoxSize = firstBox.size;
    } else if (firstBoxSize.width > secondBoxSize.width &&
        hasSecondBox &&
        secondBox != null) {
      secondBox.layout(
          BoxConstraints.tightFor(width: firstBoxSize.width, height: null),
          parentUsesSize: true);
      secondBoxSize = secondBox.size;
    }

    // Get combined tooltip height
    double tooltipHeight = firstBoxSize.height;
    if (hasSecondBox) {
      tooltipHeight += secondBoxSize.height + gapBetweenContentAndAction;
    }

    // Determine tooltip position if not provided

    if (position == null) {
      // Try positions in priority order: bottom, top, left, right
      if (_fitsInPosition(
          TooltipPosition.bottom, firstBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.bottom;
      } else if (_fitsInPosition(
          TooltipPosition.top, firstBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.top;
      } else if (_fitsInPosition(
          TooltipPosition.left, firstBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.left;
      } else if (_fitsInPosition(
          TooltipPosition.right, firstBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.right;
      } else {
        // Default to bottom if nothing fits (will be adjusted later)
        tooltipPosition = TooltipPosition.bottom;
      }
    } else {
      tooltipPosition = position!;
    }

    // Calculate initial tooltip position
    double xOffset = 0;
    double yOffset = 0;

    // Position tooltip according to selected position

    void positionToolTip() {
      switch (tooltipPosition) {
        case TooltipPosition.bottom:
          xOffset =
              targetPosition.dx + (targetSize.width - firstBoxSize.width) / 2;
          yOffset = targetPosition.dy + targetSize.height + _tooltipOffset;
          if (hasArrow) {
            yOffset += _withArrowToolTipPadding;
          } else {
            yOffset += _withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.top:
          xOffset =
              targetPosition.dx + (targetSize.width - firstBoxSize.width) / 2;
          yOffset = targetPosition.dy - firstBoxSize.height - _tooltipOffset;
          if (hasArrow) {
            yOffset -= _withArrowToolTipPadding;
          } else {
            yOffset -= _withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.left:
          xOffset = targetPosition.dx - firstBoxSize.width - _tooltipOffset;
          if (hasArrow) {
            xOffset -= _withArrowToolTipPadding;
          } else {
            xOffset -= _withOutArrowToolTipPadding;
          }
          yOffset =
              targetPosition.dy + (targetSize.height - firstBoxSize.height) / 2;
          break;

        case TooltipPosition.right:
          xOffset = targetPosition.dx + targetSize.width + _tooltipOffset;
          if (hasArrow) {
            xOffset += _withArrowToolTipPadding;
          } else {
            xOffset += _withOutArrowToolTipPadding;
          }
          yOffset =
              targetPosition.dy + (targetSize.height - firstBoxSize.height) / 2;
          break;
      }
    }

    positionToolTip();

    // Check if tooltip exceeds screen boundaries and adjust accordingly
    bool needToResize = false;
    bool needToFlip = false;
    double maxWidth = firstBoxSize.width;
    double maxHeight = tooltipHeight;

    // Horizontal adjustments

    if (xOffset < screenEdgePadding) {
      if (tooltipPosition == TooltipPosition.left) {
        if (_fitsInPosition(
            TooltipPosition.right, firstBoxSize, tooltipHeight)) {
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.bottom, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.bottom;
          if (maxWidth > screenSize.width - (2 * screenEdgePadding)) {
            maxWidth = screenSize.width - (2 * screenEdgePadding);
          }
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.top, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.top;
          if (maxWidth > screenSize.width - (2 * screenEdgePadding)) {
            maxWidth = screenSize.width - (2 * screenEdgePadding);
          }
          needToResize = true;
        } else {
          maxWidth -= screenEdgePadding - xOffset;
          xOffset = screenEdgePadding;
          needToResize = true;
        }
      } else if (tooltipPosition.isVertical) {
        if (maxWidth > screenSize.width - (2 * screenEdgePadding)) {
          maxWidth = screenSize.width - (2 * screenEdgePadding);
          needToResize = true;
        }
        xOffset = screenEdgePadding;
      }
    } else if (xOffset + firstBoxSize.width >
        screenSize.width - screenEdgePadding) {
      if (tooltipPosition == TooltipPosition.right) {
        // Just align with screen edge
        if (_fitsInPosition(
            TooltipPosition.left, firstBoxSize, tooltipHeight)) {
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.bottom, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.bottom;
          maxWidth = screenSize.width - (2 * screenEdgePadding);
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.top, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.top;
          maxWidth = screenSize.width - (2 * screenEdgePadding);
          needToResize = true;
        } else {
          maxWidth = screenSize.width - xOffset - screenEdgePadding;
          needToResize = true;
        }
      } else {
        if (maxWidth > screenSize.width - (2 * screenEdgePadding)) {
          maxWidth = screenSize.width - (2 * screenEdgePadding);
          needToResize = true;
          xOffset = screenEdgePadding;
        } else {
          xOffset = screenSize.width - screenEdgePadding - firstBoxSize.width;
        }
      }
    }

    // Vertical adjustments
    if (yOffset < screenEdgePadding) {
      if (tooltipPosition == TooltipPosition.top) {
        if (_fitsInPosition(
            TooltipPosition.bottom, firstBoxSize, tooltipHeight)) {
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.left, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.left;
          if (maxHeight > screenSize.height - (2 * screenEdgePadding)) {
            maxHeight = screenSize.height - (2 * screenEdgePadding);
          }
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.right, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.right;
          if (maxHeight > screenSize.height - (2 * screenEdgePadding)) {
            maxHeight = screenSize.height - (2 * screenEdgePadding);
          }
          needToResize = true;
        } else {
          maxHeight -= screenEdgePadding - xOffset;
          yOffset = screenEdgePadding;
          needToResize = true;
        }
      } else if (tooltipPosition.isHorizontal) {
        if (maxHeight > screenSize.height - (2 * screenEdgePadding)) {
          maxHeight = screenSize.height - (2 * screenEdgePadding);
          needToResize = true;
        }
        yOffset = screenEdgePadding;
      }
    } else if (yOffset + tooltipHeight >
        screenSize.height - screenEdgePadding) {
      if (tooltipPosition == TooltipPosition.bottom) {
        // Just align with screen edge
        if (_fitsInPosition(TooltipPosition.top, firstBoxSize, tooltipHeight)) {
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.left, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.left;
          if (maxHeight > screenSize.height - (2 * screenEdgePadding)) {
            maxHeight = screenSize.height - (2 * screenEdgePadding);
          }
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.right, firstBoxSize, tooltipHeight)) {
          tooltipPosition = TooltipPosition.right;
          if (maxHeight > screenSize.height - (2 * screenEdgePadding)) {
            maxHeight = screenSize.height - (2 * screenEdgePadding);
          }
          needToResize = true;
        } else {
          maxHeight = screenSize.height - yOffset - screenEdgePadding;
          needToResize = true;
        }
      } else {
        if (maxHeight > screenSize.height - (2 * screenEdgePadding)) {
          maxHeight = screenSize.height - (2 * screenEdgePadding);
          needToResize = true;
          yOffset = screenEdgePadding;
        } else {
          yOffset = screenSize.height - screenEdgePadding - tooltipHeight;
        }
      }
    }

    // Handle resizing if needed
    if (needToResize && firstBox != null) {
      firstBox.layout(BoxConstraints.tightFor(width: maxWidth, height: null),
          parentUsesSize: true);
      firstBoxSize = firstBox.size;

      if (hasSecondBox && secondBox != null) {
        secondBox.layout(BoxConstraints.tightFor(width: maxWidth, height: null),
            parentUsesSize: true);
        secondBoxSize = secondBox.size;
      }

      // Recalculate tooltip height
      tooltipHeight = firstBoxSize.height;
      if (hasSecondBox) {
        tooltipHeight += secondBoxSize.height + gapBetweenContentAndAction;
      }
      if (!needToFlip) {
        positionToolTip();
      }
    }

    // Handle flipping to opposite side if needed
    if (needToFlip) {
      switch (tooltipPosition) {
        case TooltipPosition.bottom:
          tooltipPosition = TooltipPosition.top;
          yOffset = targetPosition.dy - firstBoxSize.height - _tooltipOffset;
          if (hasArrow) {
            yOffset -= _withArrowToolTipPadding;
          } else {
            yOffset -= _withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.top:
          tooltipPosition = TooltipPosition.bottom;
          yOffset = targetPosition.dy + targetSize.height + _tooltipOffset;
          if (hasArrow) {
            yOffset += _withArrowToolTipPadding;
          } else {
            yOffset += _withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.left:
          tooltipPosition = TooltipPosition.right;
          xOffset = targetPosition.dx + targetSize.width + _tooltipOffset;
          if (hasArrow) {
            xOffset += _withArrowToolTipPadding;
          } else {
            xOffset += _withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.right:
          tooltipPosition = TooltipPosition.left;
          xOffset = targetPosition.dx - firstBoxSize.width - _tooltipOffset;
          if (hasArrow) {
            xOffset -= _withArrowToolTipPadding;
          } else {
            xOffset -= _withOutArrowToolTipPadding;
          }
          break;
      }
    }

    // Final screen boundary check after all adjustments
    xOffset = xOffset.clamp(screenEdgePadding,
        screenSize.width - firstBoxSize.width - screenEdgePadding);
    yOffset = yOffset.clamp(screenEdgePadding,
        screenSize.height - tooltipHeight - screenEdgePadding);

    // Position the first box
    if (firstBox != null) {
      final firstBoxParentData =
          firstBox.parentData! as MultiChildLayoutParentData;
      firstBoxParentData.offset = Offset(xOffset, yOffset);
    }

    // Position the second box (if exists)
    if (hasSecondBox && secondBox != null) {
      final secondBoxParentData =
          secondBox.parentData! as MultiChildLayoutParentData;
      if (tooltipPosition == TooltipPosition.top) {
        secondBoxParentData.offset = Offset(xOffset,
            yOffset - secondBoxSize.height - gapBetweenContentAndAction);
      } else {
        secondBoxParentData.offset = Offset(xOffset,
            yOffset + firstBoxSize.height + gapBetweenContentAndAction);
      }
    }

    // Position the arrow (if exists)
    if (hasArrow && arrowBox != null) {
      // Arrow has already been laid out earlier
      final arrowBoxParentData =
          arrowBox.parentData! as MultiChildLayoutParentData;

      switch (tooltipPosition) {
        case TooltipPosition.top:
          arrowBoxParentData.offset = Offset(
            targetPosition.dx + (targetSize.width / 2) - (arrowWidth / 2),
            yOffset + firstBoxSize.height + (arrowHeight / 2) - 2,
          );
          break;

        case TooltipPosition.bottom:
          arrowBoxParentData.offset = Offset(
            targetPosition.dx + (targetSize.width / 2) - (arrowWidth / 2),
            yOffset - arrowHeight,
          );
          break;

        case TooltipPosition.left:
          arrowBoxParentData.offset = Offset(
            xOffset + firstBoxSize.height - 1,
            targetPosition.dy + (targetSize.height / 2) - (arrowWidth / 2),
          );
          break;

        case TooltipPosition.right:
          arrowBoxParentData.offset = Offset(
            xOffset - arrowWidth + 2,
            targetPosition.dy + (targetSize.height / 2) - (arrowHeight / 2),
          );
          break;
      }
    }
  }

  // Helper method to check if tooltip fits in a specific position
  bool _fitsInPosition(
      TooltipPosition pos, Size tooltipSize, double totalHeight) {
    switch (pos) {
      case TooltipPosition.bottom:
        return targetPosition.dy +
                targetSize.height +
                totalHeight +
                _tooltipOffset +
                (hasArrow
                    ? _withArrowToolTipPadding
                    : _withOutArrowToolTipPadding) <=
            screenSize.height - screenEdgePadding;

      case TooltipPosition.top:
        return targetPosition.dy -
                totalHeight -
                _tooltipOffset -
                (hasArrow
                    ? _withArrowToolTipPadding
                    : _withOutArrowToolTipPadding) >=
            screenEdgePadding;

      case TooltipPosition.left:
        return targetPosition.dx -
                tooltipSize.width -
                _tooltipOffset -
                (hasArrow
                    ? _withArrowToolTipPadding
                    : _withOutArrowToolTipPadding) >=
            screenEdgePadding;

      case TooltipPosition.right:
        return targetPosition.dx +
                targetSize.width +
                tooltipSize.width +
                _tooltipOffset +
                (hasArrow
                    ? _withArrowToolTipPadding
                    : _withOutArrowToolTipPadding) <=
            screenSize.width - screenEdgePadding;
    }
  }
}

class AnimatedTooltipMultiChildLayout extends MultiChildRenderObjectWidget {
  final AnimationController scaleController;
  final AnimationController moveController;
  final Animation<double> scaleAnimation;
  final Animation<double> moveAnimation;
  final Offset targetPosition;
  final Size targetSize;
  final TooltipPosition? position;
  final Size screenSize;
  final bool hasSecondBox;
  final bool hasArrow;
  final double gapBetweenContentAndAction;
  final double toolTipSlideEndDistance;
  final Alignment? scaleAlignment;
  final double screenEdgePadding;

  const AnimatedTooltipMultiChildLayout({
    super.key,
    required this.scaleController,
    required this.moveController,
    required this.scaleAnimation,
    required this.moveAnimation,
    required this.targetPosition,
    required this.targetSize,
    required this.screenSize,
    required this.hasSecondBox,
    required this.hasArrow,
    required this.gapBetweenContentAndAction,
    required this.toolTipSlideEndDistance,
    required super.children,
    required this.position,
    required this.scaleAlignment,
    required this.screenEdgePadding,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAnimatedTooltipMultiChildLayoutBox(
      scaleController: scaleController,
      moveController: moveController,
      scaleAnimation: scaleAnimation,
      moveAnimation: moveAnimation,
      targetPosition: targetPosition,
      targetSize: targetSize,
      position: position,
      screenSize: screenSize,
      hasSecondBox: hasSecondBox,
      hasArrow: hasArrow,
      scaleAlignment: scaleAlignment,
      gapBetweenContentAndAction: gapBetweenContentAndAction,
      toolTipSlideEndDistance: toolTipSlideEndDistance,
      screenEdgePadding: screenEdgePadding,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      RenderAnimatedTooltipMultiChildLayoutBox renderObject) {
    renderObject
      ..scaleController = scaleController
      ..moveController = moveController
      ..scaleAnimation = scaleAnimation
      ..moveAnimation = moveAnimation
      ..targetPosition = targetPosition
      ..targetSize = targetSize
      ..position = position
      ..screenSize = screenSize
      ..hasSecondBox = hasSecondBox
      ..hasArrow = hasArrow
      ..screenEdgePadding = screenEdgePadding
      ..toolTipSlideEndDistance = toolTipSlideEndDistance
      ..gapBetweenContentAndAction = gapBetweenContentAndAction;
  }
}

class RenderAnimatedTooltipMultiChildLayoutBox
    extends RenderTooltipMultiChildLayoutBox {
  AnimationController _scaleController;
  AnimationController _moveController;
  Animation<double> _scaleAnimation;
  Animation<double> _moveAnimation;
  Alignment? scaleAlignment;

  RenderAnimatedTooltipMultiChildLayoutBox({
    required AnimationController scaleController,
    required AnimationController moveController,
    required Animation<double> scaleAnimation,
    required Animation<double> moveAnimation,
    required this.scaleAlignment,
    required super.targetPosition,
    required super.targetSize,
    required super.position,
    required super.screenSize,
    required super.hasSecondBox,
    required super.hasArrow,
    required super.gapBetweenContentAndAction,
    required super.toolTipSlideEndDistance,
    required super.screenEdgePadding,
  })  : _scaleController = scaleController,
        _moveController = moveController,
        _scaleAnimation = scaleAnimation,
        _moveAnimation = moveAnimation {
    // Add listeners to animations
    _scaleAnimation.addListener(markNeedsPaint);
    _moveAnimation.addListener(markNeedsPaint);
  }

  // Setters for animation controllers and animations
  set scaleController(AnimationController value) {
    if (_scaleController != value) {
      _scaleController = value;
    }
  }

  set moveController(AnimationController value) {
    if (_moveController != value) {
      _moveController = value;
    }
  }

  set scaleAnimation(Animation<double> value) {
    if (_scaleAnimation != value) {
      _scaleAnimation.removeListener(markNeedsPaint);
      _scaleAnimation = value;
      _scaleAnimation.addListener(markNeedsPaint);
      markNeedsPaint();
    }
  }

  set moveAnimation(Animation<double> value) {
    if (_moveAnimation != value) {
      _moveAnimation.removeListener(markNeedsPaint);
      _moveAnimation = value;
      _moveAnimation.addListener(markNeedsPaint);
      markNeedsPaint();
    }
  }

  // Method to update alignment
  void setScaleAlignment(Alignment alignment) {
    scaleAlignment = alignment;
    markNeedsPaint();
  }

  // TooltipPosition? oldToolTipPosition = null;

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;

    // This should be a class field
    // For example: Alignment scaleAlignment = Alignment.topLeft;

    while (child != null) {
      final childParentData = child.parentData! as MultiChildLayoutParentData;

      context.canvas.save();

      // Calculate scale origin based on target widget and alignment
      // This uses the target widget's bounds and the alignment parameter
      final Rect targetRect = Rect.fromLTWH(targetPosition.dx,
          targetPosition.dy, targetSize.width, targetSize.height);

      // Convert alignment to actual pixel position within the target rect

      if (scaleAlignment == null) {
        switch (tooltipPosition) {
          case TooltipPosition.top:
            scaleAlignment = Alignment.topCenter;
            break;
          case TooltipPosition.bottom:
            scaleAlignment = Alignment.bottomCenter;
            break;
          case TooltipPosition.left:
            scaleAlignment = Alignment.centerLeft;
            break;
          case TooltipPosition.right:
            scaleAlignment = Alignment.centerRight;
            break;
        }
      }
      final Offset scaleOrigin = Offset(
          targetRect.left +
              (targetRect.width / 2) +
              (scaleAlignment!.x * targetRect.width / 2),
          targetRect.top +
              (targetRect.height / 2) +
              (scaleAlignment!.y * targetRect.height / 2));

      // Apply move animation
      late Offset moveOffset;

      switch (tooltipPosition) {
        case TooltipPosition.top:
          moveOffset = Offset(
            0,
            (1 - _moveAnimation.value) * -toolTipSlideEndDistance,
          );
          break;
        case TooltipPosition.bottom:
          moveOffset = Offset(
            0,
            (1 - _moveAnimation.value) * toolTipSlideEndDistance,
          );
          break;
        case TooltipPosition.left:
          moveOffset = Offset(
            (1 - _moveAnimation.value) * -toolTipSlideEndDistance,
            0,
          );
          break;
        case TooltipPosition.right:
          moveOffset = Offset(
            (1 - _moveAnimation.value) * toolTipSlideEndDistance,
            0,
          );
          break;
      }

      context.canvas.translate(scaleOrigin.dx, scaleOrigin.dy);

      // Apply scale around this origin
      context.canvas.scale(_scaleAnimation.value);

      // Translate back and paint each child
      if (childParentData.id == TooltipLayoutSlot.arrow) {
        // Special handling for arrow
        context.canvas.translate(
            -scaleOrigin.dx + childParentData.offset.dx + child.size.width / 2,
            -scaleOrigin.dy +
                childParentData.offset.dy +
                child.size.height / 2);

        // Add move offset
        context.canvas.translate(moveOffset.dx, moveOffset.dy);

        // Rotate arrow if needed
        context.canvas.rotate(tooltipPosition.rotationAngle);

        // Paint the arrow
        context.paintChild(
            child, Offset(-child.size.width / 2, -child.size.height / 2));
      } else {
        // Normal children
        context.canvas.translate(-scaleOrigin.dx + childParentData.offset.dx,
            -scaleOrigin.dy + childParentData.offset.dy);

        // Add move offset
        context.canvas.translate(moveOffset.dx, moveOffset.dy);

        // Paint the child
        context.paintChild(child, Offset.zero);
      }

      context.canvas.restore();

      child = childParentData.nextSibling;
    }
  }
}

class TooltipLayoutId extends ParentDataWidget<MultiChildLayoutParentData> {
  final Object id;

  const TooltipLayoutId({
    super.key,
    required this.id,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is MultiChildLayoutParentData);
    final parentData = renderObject.parentData! as MultiChildLayoutParentData;
    if (parentData.id != id) {
      parentData.id = id;
      final targetObject = renderObject.parent;
      if (targetObject is RenderObject) {
        targetObject.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => AnimatedTooltipMultiChildLayout;
}

class ToolTipWidgetV2 extends StatefulWidget {
  final GetPosition? position;
  final Offset? offset; // This is not needed
  final Size screenSize; // This is also not needed
  final String? title;
  final TextAlign? titleTextAlign;
  final String? description;
  final TextAlign? descriptionTextAlign;
  final AlignmentGeometry titleAlignment;
  final AlignmentGeometry descriptionAlignment;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final Widget? container;
  final FloatingActionWidget?
      floatingActionWidget; // This is not needed as we have shifted them to showcase
  final Color? tooltipBackgroundColor;
  final Color? textColor;
  final bool showArrow;
  final double? contentHeight; // Not needed
  final double? contentWidth; // Not needed
  final VoidCallback? onTooltipTap;
  final EdgeInsets? tooltipPadding;
  final Duration movingAnimationDuration;
  final bool disableMovingAnimation;
  final bool disableScaleAnimation;
  final BorderRadius? tooltipBorderRadius;
  final Duration scaleAnimationDuration;
  final Curve scaleAnimationCurve;
  final Alignment? scaleAnimationAlignment;
  final bool isTooltipDismissed;
  final TooltipPosition? tooltipPosition;
  final EdgeInsets? titlePadding;
  final EdgeInsets? descriptionPadding;
  final TextDirection? titleTextDirection;
  final TextDirection? descriptionTextDirection;
  final double toolTipSlideEndDistance;
  final double toolTipMargin;
  final TooltipActionConfig tooltipActionConfig;
  final List<Widget> tooltipActions;

  const ToolTipWidgetV2({
    super.key,
    required this.position,
    required this.offset,
    required this.screenSize,
    required this.title,
    required this.description,
    required this.titleTextStyle,
    required this.descTextStyle,
    required this.container,
    required this.floatingActionWidget,
    required this.tooltipBackgroundColor,
    required this.textColor,
    required this.showArrow,
    required this.contentHeight,
    required this.contentWidth,
    required this.onTooltipTap,
    required this.movingAnimationDuration,
    required this.titleTextAlign,
    required this.descriptionTextAlign,
    required this.titleAlignment,
    required this.descriptionAlignment,
    this.tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
    required this.disableMovingAnimation,
    required this.disableScaleAnimation,
    required this.tooltipBorderRadius,
    required this.scaleAnimationDuration,
    required this.scaleAnimationCurve,
    required this.toolTipMargin,
    this.scaleAnimationAlignment,
    this.isTooltipDismissed = false,
    this.tooltipPosition,
    this.titlePadding,
    this.descriptionPadding,
    this.titleTextDirection,
    this.descriptionTextDirection,
    this.toolTipSlideEndDistance = 7,
    required this.tooltipActionConfig,
    required this.tooltipActions,
  });

  @override
  State<ToolTipWidgetV2> createState() => _ToolTipWidgetV2State();
}

class _ToolTipWidgetV2State extends State<ToolTipWidgetV2>
    with TickerProviderStateMixin {
  late final AnimationController _movingAnimationController;
  late final Animation<double> _movingAnimation;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _scaleAnimation;

  Offset parentCenter = Offset(0, 0);

  @override
  void initState() {
    super.initState();
    _movingAnimationController = AnimationController(
      duration: widget.movingAnimationDuration,
      vsync: this,
    );
    _movingAnimation = CurvedAnimation(
      parent: _movingAnimationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimationController = AnimationController(
      duration: widget.scaleAnimationDuration,
      vsync: this,
      lowerBound: widget.disableScaleAnimation ? 1 : 0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: widget.scaleAnimationCurve,
    );
    if (widget.disableScaleAnimation) {
      movingAnimationListener();
    } else {
      _scaleAnimationController
        ..addStatusListener((scaleAnimationStatus) {
          if (scaleAnimationStatus == AnimationStatus.completed) {
            movingAnimationListener();
          }
        })
        ..forward();
    }
    if (!widget.disableMovingAnimation) {
      _movingAnimationController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          _scaleAnimationController.reverse();
        },
      );
    }
  }

  @override
  void didUpdateWidget(covariant ToolTipWidgetV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) {
          _scaleAnimationController.reverse();
        },
      );
    }
  }

  void movingAnimationListener() {
    _movingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _movingAnimationController.reverse();
      }
      if (_movingAnimationController.isDismissed) {
        if (!widget.disableMovingAnimation) {
          _movingAnimationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _movingAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  final zeroPadding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final defaultToolTipWidget = widget.container == null
        ? Padding(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius:
                    widget.tooltipBorderRadius ?? BorderRadius.circular(8.0),
                child: MouseRegion(
                  cursor: widget.onTooltipTap == null
                      ? MouseCursor.defer
                      : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onTooltipTap,
                    child: Container(
                      padding: widget.tooltipPadding?.copyWith(
                        left: 0,
                        right: 0,
                      ),
                      color: widget.tooltipBackgroundColor,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (widget.title != null)
                            Align(
                              alignment: widget.titleAlignment,
                              child: Padding(
                                padding:
                                    (widget.titlePadding ?? zeroPadding).add(
                                  EdgeInsets.only(
                                    left: widget.tooltipPadding?.left ?? 0,
                                    right: widget.tooltipPadding?.right ?? 0,
                                  ),
                                ),
                                child: Text(
                                  widget.title!,
                                  textAlign: widget.titleTextAlign,
                                  textDirection: widget.titleTextDirection,
                                  style: widget.titleTextStyle ??
                                      Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .merge(
                                            TextStyle(
                                              color: widget.textColor,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          if (widget.description != null)
                            Align(
                              alignment: widget.descriptionAlignment,
                              child: Padding(
                                padding:
                                    (widget.descriptionPadding ?? zeroPadding)
                                        .add(
                                  EdgeInsets.only(
                                    left: widget.tooltipPadding?.left ?? 0,
                                    right: widget.tooltipPadding?.right ?? 0,
                                  ),
                                ),
                                child: Text(
                                  widget.description!,
                                  textAlign: widget.descriptionTextAlign,
                                  textDirection:
                                      widget.descriptionTextDirection,
                                  style: widget.descTextStyle ??
                                      Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .merge(
                                            TextStyle(
                                              color: widget.textColor,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          if (widget.tooltipActions.isNotEmpty &&
                              widget.tooltipActionConfig.position.isInside)
                            _getActionWidget(insideWidget: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        : MouseRegion(
            cursor: widget.onTooltipTap == null
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTooltipTap,
              child: Container(
                padding: zeroPadding,
                color: Colors.transparent,
                child: Center(
                  child: widget.container ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );

    // Calculate the target position and size
    final targetPosition = widget.position!.box!.localToGlobal(Offset.zero);
    final targetSize = widget.position!.box!.size;

    return Material(
      type: MaterialType.transparency,
      child: AnimatedTooltipMultiChildLayout(
        scaleController: _scaleAnimationController,
        moveController: _movingAnimationController,
        scaleAnimation: _scaleAnimation,
        moveAnimation: _movingAnimation,
        targetPosition: targetPosition,
        targetSize: targetSize,
        position: widget.tooltipPosition,
        screenSize: MediaQuery.of(context).size,
        hasArrow: widget.showArrow,
        scaleAlignment: widget.scaleAnimationAlignment,
        hasSecondBox: widget.tooltipActions.isNotEmpty &&
            (widget.tooltipActionConfig.position.isOutside ||
                widget.container != null),
        toolTipSlideEndDistance: widget.toolTipSlideEndDistance,
        gapBetweenContentAndAction:
            widget.tooltipActionConfig.gapBetweenContentAndAction,
        screenEdgePadding: widget.toolTipMargin,
        children: [
          TooltipLayoutId(
            id: TooltipLayoutSlot.firstBox,
            child: defaultToolTipWidget,
          ),
          if (widget.tooltipActions.isNotEmpty &&
              (widget.tooltipActionConfig.position.isOutside ||
                  widget.container != null))
            TooltipLayoutId(
              id: TooltipLayoutSlot.secondBox,
              child: _getActionWidget(),
            ),
          if (widget.showArrow)
            TooltipLayoutId(
              id: TooltipLayoutSlot.arrow,
              child: CustomPaint(
                painter: _Arrow(
                  strokeColor: widget.tooltipBackgroundColor!,
                  strokeWidth: 10,
                  paintingStyle: PaintingStyle.fill,
                ),
                size: const Size(10, 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getActionWidget({
    bool insideWidget = false,
  }) {
    return Material(
      type: MaterialType.transparency,
      child: ActionWidget(
        tooltipActionConfig: widget.tooltipActionConfig,
        outSidePadding: (insideWidget)
            ? EdgeInsets.only(
                left: widget.tooltipPadding?.left ?? 0,
                right: widget.tooltipPadding?.right ?? 0,
              )
            : zeroPadding,
        alignment: widget.tooltipActionConfig.alignment,
        crossAxisAlignment: widget.tooltipActionConfig.crossAxisAlignment,
        width: 1004,
        isArrowUp: insideWidget,
        children: widget.tooltipActions,
      ),
    );
  }
}

class _Arrow extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final Paint _paint;

  _Arrow({
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
    this.paintingStyle = PaintingStyle.stroke,
  }) : _paint = Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = paintingStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(getTrianglePath(), _paint);
  }

  Path getTrianglePath() {
    // Fixed width & height

    return Path()
      ..moveTo(0, arrowHeight)
      ..lineTo(arrowWidth / 2, 0)
      ..lineTo(arrowWidth, arrowHeight)
      ..lineTo(0, arrowHeight);

    // switch (direction) {
    //   case TooltipPosition.bottom:
    //     print("bottom");
    //
    //   case TooltipPosition.top:
    //     print("top");
    //     return Path()
    //       ..moveTo(0, 0)
    //       ..lineTo(arrowSize, 0)
    //       ..lineTo(arrowSize / 2, arrowSize)
    //       ..close();
    //   case TooltipPosition.right:
    //     print("right");
    //     return Path()
    //       ..moveTo(arrowSize, 0)
    //       ..lineTo(0, arrowSize / 2)
    //       ..lineTo(arrowSize, arrowSize)
    //       ..close();
    //   case TooltipPosition.left:
    //     print("left");
    //     return Path()
    //       ..moveTo(0, 0)
    //       ..lineTo(arrowSize, arrowSize / 2)
    //       ..lineTo(0, arrowSize)
    //       ..close();
    // }
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
