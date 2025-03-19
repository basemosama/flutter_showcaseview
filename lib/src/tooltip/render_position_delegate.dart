part of 'tooltip.dart';

/// Custom RenderObject that handles tooltip positioning and layout
/// Manages the positioning of tooltip content, action buttons, and arrow
/// while ensuring the tooltip stays within screen boundaries
class _RenderPositionDelegate extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  /// Creates a new RenderPositionDelegate for tooltip layout
  ///
  /// [targetPosition] - Position of the target widget that triggered the tooltip
  /// [targetSize] - Size of the target widget
  /// [position] - Optional preferred position for the tooltip
  /// [screenSize] - Current screen size to respect boundaries
  /// [hasSecondBox] - Whether an action box exists below the main tooltip
  /// [hasArrow] - Whether to show a directional arrow pointing to the target
  /// [toolTipSlideEndDistance] - Distance for slide animations
  /// [gapBetweenContentAndAction] - Spacing between tooltip content and action buttons
  /// [screenEdgePadding] - Minimum padding from screen edges
  /// [targetPadding] - Padding around the target
  _RenderPositionDelegate({
    required this.targetPosition,
    required this.targetSize,
    required this.position,
    required this.screenSize,
    required this.hasSecondBox,
    required this.hasArrow,
    required this.toolTipSlideEndDistance,
    required this.gapBetweenContentAndAction,
    required this.screenEdgePadding,
    required this.targetPadding,
    required this.showcaseOffset,
  });

  // Core positioning parameters
  Offset targetPosition;
  Size targetSize;
  TooltipPosition? position;
  Size screenSize;
  bool hasSecondBox;
  bool hasArrow;
  double toolTipSlideEndDistance;
  double gapBetweenContentAndAction;
  double screenEdgePadding;
  EdgeInsets targetPadding;

  /// This is used when there is some space around showcaseview as this widget
  /// implementation works in global coordinate system so because of that we
  /// need to manage local position by our self
  /// To check this usecase wrap material app in padding widget
  Offset showcaseOffset;

  /// Calculated tooltip position after layout
  late TooltipPosition tooltipPosition;

  @override
  void setupParentData(RenderBox child) {
    // Ensure all children have the correct parent data type
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Standard hit testing implementation for children
    return defaultHitTestChildren(result, position: position + showcaseOffset);
  }

  Size _toolTipBoxSize = Size.zero;
  double _xOffset = 0;
  double _yOffset = 0;

  @override
  void performLayout() {
    // Always set a size for this render object first to prevent layout errors
    size = constraints.biggest;

    // Initialize variables for child sizes
    _toolTipBoxSize = Size.zero;
    Size actionBoxSize = Size.zero;
    var minimumActionBoxSize = Size.zero;

    final availableScreenWidth = screenSize.width - (2 * screenEdgePadding);
    final availableScreenHeight = screenSize.height - (2 * screenEdgePadding);

    // References to child render objects
    RenderBox? toolTipBox;
    RenderBox? actionBox;
    RenderBox? arrowBox;

    // Find children by ID
    RenderBox? child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData =
          child.parentData! as MultiChildLayoutParentData;

      // Identify each child by its slot ID
      if (childParentData.id == TooltipLayoutSlot.tooltipBox) {
        toolTipBox = child;
      } else if (childParentData.id == TooltipLayoutSlot.actionBox) {
        actionBox = child;
      } else if (childParentData.id == TooltipLayoutSlot.arrow) {
        arrowBox = child;
      }

      child = childParentData.nextSibling;
    }

    // STEP 1: Initial layout of children to determine natural sizes

    // Layout arrow early to avoid RenderCustomPaint errors
    if (hasArrow && arrowBox != null) {
      arrowBox.layout(
          const BoxConstraints.tightFor(
            width: Constants.arrowWidth,
            height: Constants.arrowHeight,
          ),
          parentUsesSize: true);
    }

    // Layout main tooltip content with loose constraints
    if (toolTipBox != null) {
      toolTipBox.layout(
          const BoxConstraints.tightFor(width: null, height: null),
          parentUsesSize: true);
      _toolTipBoxSize = toolTipBox.size;
    }

    // Layout action box (if exists) with loose constraints
    if (hasSecondBox && actionBox != null) {
      actionBox.layout(
        const BoxConstraints.tightFor(width: null, height: null),
        parentUsesSize: true,
      );
      actionBoxSize = actionBox.size;
      minimumActionBoxSize = actionBox.size;
    }

    // STEP 2: Normalize widths between tooltip and action box for consistency

    // Make both boxes the same width (use the wider one)
    if (actionBoxSize.width > _toolTipBoxSize.width && toolTipBox != null) {
      // Action box is wider, make tooltip match
      toolTipBox.layout(
          BoxConstraints.tightFor(width: actionBoxSize.width, height: null),
          parentUsesSize: true);
      _toolTipBoxSize = toolTipBox.size;
    } else if (_toolTipBoxSize.width > actionBoxSize.width &&
        hasSecondBox &&
        actionBox != null) {
      // Tooltip is wider, make action box match
      actionBox.layout(
          BoxConstraints.tightFor(width: _toolTipBoxSize.width, height: null),
          parentUsesSize: true);
      actionBoxSize = actionBox.size;
    }

    // Calculate combined tooltip height including gap if needed
    double tooltipHeight = _toolTipBoxSize.height;
    if (hasSecondBox) {
      tooltipHeight += actionBoxSize.height + gapBetweenContentAndAction;
    }

    // STEP 3: Determine optimal tooltip position

    // If no position provided, find best automatic position
    if (position == null) {
      // Try positions in priority order: bottom, top, left, right
      if (_fitsInPosition(
          TooltipPosition.bottom, _toolTipBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.bottom;
      } else if (_fitsInPosition(
          TooltipPosition.top, _toolTipBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.top;
      } else if (_fitsInPosition(
          TooltipPosition.left, _toolTipBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.left;
      } else if (_fitsInPosition(
          TooltipPosition.right, _toolTipBoxSize, tooltipHeight)) {
        tooltipPosition = TooltipPosition.right;
      } else {
        // Default to bottom if nothing fits (will be adjusted later)
        tooltipPosition = TooltipPosition.bottom;
      }
    } else {
      // Use provided position
      tooltipPosition = position!;
    }

    // Initialize tooltip positioning variables
    _xOffset = 0;
    _yOffset = 0;

    // STEP 4: Position tooltip according to selected position

    // Helper function to calculate initial position based on selected direction

    // Calculate initial position
    positionToolTip();

    // STEP 5: Handle screen boundary constraints and adjustments

    // Flags to track if we need to make adjustments
    bool needToResize = false; // Whether to resize the tooltip
    bool needToFlip = false; // Whether to flip to opposite side

    // Maximum dimensions to use when resizing
    double maxWidth = _toolTipBoxSize.width;
    double maxHeight = tooltipHeight;

    // Horizontal boundary handling
    if (_xOffset < screenEdgePadding + showcaseOffset.dx) {
      // Tooltip extends beyond left edge
      if (tooltipPosition.isLeft) {
        // When positioned left, we have a few options:
        var minWidth = targetPosition.dx -
            showcaseOffset.dx -
            screenEdgePadding -
            Constants.tooltipOffset -
            targetPadding.left;
        if (hasArrow) {
          minWidth -= Constants.withArrowToolTipPadding;
        } else {
          minWidth -= Constants.withOutArrowToolTipPadding;
        }
        if (minWidth > Constants.minimumToolTipWidth &&
            minWidth > minimumActionBoxSize.width) {
          // Option 1: Resize tooltip to fit
          maxWidth = minWidth;
          // _xOffset = screenEdgePadding + showcaseOffset.dx;
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.right, _toolTipBoxSize, tooltipHeight)) {
          // Option 2: Flip to right side if it fits
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.bottom, _toolTipBoxSize, tooltipHeight)) {
          // Option 3: Switch to bottom position if it fits
          tooltipPosition = TooltipPosition.bottom;
          if (maxWidth > availableScreenWidth) {
            maxWidth = availableScreenWidth;
          }
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.top, _toolTipBoxSize, tooltipHeight)) {
          // Option 4: Switch to top position if it fits
          tooltipPosition = TooltipPosition.top;
          if (maxWidth > availableScreenWidth) {
            maxWidth = availableScreenWidth;
          }
          needToResize = true;
        } else {
          // Option 5: Last resort - resize and keep at left
          maxWidth -= screenEdgePadding - _xOffset;
          _xOffset = screenEdgePadding + showcaseOffset.dx;
          needToResize = true;
        }
      } else if (tooltipPosition.isVertical) {
        // For top/bottom positions, ensure width fits and align to left edge
        if (maxWidth > availableScreenWidth) {
          maxWidth = availableScreenWidth;
          needToResize = true;
        }
        _xOffset = screenEdgePadding + showcaseOffset.dx;
      }
    } else if (_xOffset + _toolTipBoxSize.width - showcaseOffset.dx >
        screenSize.width - screenEdgePadding) {
      // Tooltip extends beyond right edge
      if (tooltipPosition.isRight) {
        // When positioned right, similar options as with left position
        var minWidth = screenSize.width -
            screenEdgePadding -
            _xOffset -
            targetPadding.right;

        if (minWidth > Constants.minimumToolTipWidth &&
            minWidth > minimumActionBoxSize.width) {
          // Option 1: Resize tooltip to fit
          maxWidth = screenSize.width - _xOffset - screenEdgePadding;
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.left, _toolTipBoxSize, tooltipHeight)) {
          // Option 2: Flip to left side if it fits
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.bottom, _toolTipBoxSize, tooltipHeight)) {
          // Option 3: Switch to bottom position if it fits
          tooltipPosition = TooltipPosition.bottom;
          maxWidth = availableScreenWidth;
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.top, _toolTipBoxSize, tooltipHeight)) {
          // Option 4: Switch to top position if it fits
          tooltipPosition = TooltipPosition.top;
          maxWidth = availableScreenWidth;
          needToResize = true;
        } else {
          // Option 5: Last resort - resize and keep at right
          maxWidth = screenSize.width - _xOffset - screenEdgePadding;
          needToResize = true;
        }
      } else {
        // For top/bottom positions, ensure width fits and adjust alignment
        if (maxWidth > availableScreenWidth) {
          maxWidth = availableScreenWidth;
          needToResize = true;
          _xOffset = screenEdgePadding + showcaseOffset.dx;
        } else {
          // Align to right edge
          _xOffset = screenSize.width -
              screenEdgePadding -
              _toolTipBoxSize.width +
              showcaseOffset.dx;
        }
      }
    }

    // Recalculate max height based on new width constraints if resizing
    maxHeight = (toolTipBox
            ?.getDryLayout(
                BoxConstraints.tightFor(width: maxWidth, height: null))
            .height ??
        0);
    if (hasSecondBox) {
      maxHeight += (actionBoxSize.height + gapBetweenContentAndAction);
    }
    var extraVerticalComponentHeight = 0.0;
    if (tooltipPosition.isVertical) {
      extraVerticalComponentHeight += Constants.tooltipOffset;
      if (hasArrow) {
        extraVerticalComponentHeight += Constants.withArrowToolTipPadding;
      } else {
        extraVerticalComponentHeight += Constants.withOutArrowToolTipPadding;
      }
    }

    // Vertical boundary handling
    if (_yOffset < screenEdgePadding + showcaseOffset.dy) {
      // Tooltip extends beyond top edge
      if (tooltipPosition.isTop) {
        // When positioned at top, check options
        if (_fitsInPosition(
            TooltipPosition.bottom, _toolTipBoxSize, tooltipHeight)) {
          // Option 1: Flip to bottom side if it fits
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.left, _toolTipBoxSize, tooltipHeight)) {
          // Option 2: Switch to left position if it fits
          tooltipPosition = TooltipPosition.left;
          if (maxHeight > availableScreenHeight) {
            maxHeight = availableScreenHeight;
          }
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.right, _toolTipBoxSize, tooltipHeight)) {
          // Option 3: Switch to right position if it fits
          tooltipPosition = TooltipPosition.right;
          if (maxHeight > availableScreenHeight) {
            maxHeight = availableScreenHeight;
          }
          needToResize = true;
        } else {
          // Option 4: Last resort - resize and keep at top
          maxHeight -= screenEdgePadding - _xOffset;
          _yOffset = screenEdgePadding + showcaseOffset.dy;
          needToResize = true;
        }
      } else if (tooltipPosition.isHorizontal) {
        // For left/right positions, ensure height fits and align to top edge
        if (maxHeight > availableScreenHeight) {
          maxHeight = availableScreenHeight;
          needToResize = true;
        }
        _yOffset = screenEdgePadding + showcaseOffset.dy;
      }
    } else if (_yOffset +
            maxHeight +
            extraVerticalComponentHeight -
            showcaseOffset.dy >
        screenSize.height - screenEdgePadding) {
      // Tooltip extends beyond bottom edge
      if (tooltipPosition.isBottom) {
        // When positioned at bottom, check options
        if (_fitsInPosition(
            TooltipPosition.top, _toolTipBoxSize, tooltipHeight)) {
          // Option 1: Flip to top side if it fits
          needToFlip = true;
        } else if (_fitsInPosition(
            TooltipPosition.left, _toolTipBoxSize, tooltipHeight)) {
          // Option 2: Switch to left position if it fits
          tooltipPosition = TooltipPosition.left;
          if (maxHeight > availableScreenHeight) {
            maxHeight = availableScreenHeight;
          }
          needToResize = true;
        } else if (_fitsInPosition(
            TooltipPosition.right, _toolTipBoxSize, tooltipHeight)) {
          // Option 3: Switch to right position if it fits
          tooltipPosition = TooltipPosition.right;
          if (maxHeight > availableScreenHeight) {
            maxHeight = availableScreenHeight;
          }
          needToResize = true;
        } else {
          // Option 4: Last resort - resize and keep at bottom
          maxHeight += extraVerticalComponentHeight;
          needToResize = true;
          _yOffset = screenSize.height -
              showcaseOffset.dy -
              screenEdgePadding -
              maxHeight;
        }
      } else {
        // For left/right positions, ensure height fits and adjust alignment
        if (maxHeight > availableScreenHeight) {
          maxHeight = availableScreenHeight;
          needToResize = true;
          _yOffset = screenEdgePadding + showcaseOffset.dy;
        } else {
          // Align to bottom edge
          _yOffset = screenSize.height -
              screenEdgePadding -
              tooltipHeight +
              showcaseOffset.dy;
        }
      }
    }

    // STEP 6: Handle resizing if needed
    if (needToResize && toolTipBox != null) {
      // Resize tooltip box with new constraints
      var tooltipBoxHeight = maxHeight;
      if (hasSecondBox) {
        tooltipBoxHeight -= (actionBoxSize.height + gapBetweenContentAndAction);
      }
      toolTipBox.layout(
          BoxConstraints.tightFor(width: maxWidth, height: tooltipBoxHeight),
          parentUsesSize: true);
      _toolTipBoxSize = toolTipBox.size;

      // Resize action box if exists
      if (hasSecondBox && actionBox != null) {
        actionBox.layout(BoxConstraints.tightFor(width: maxWidth, height: null),
            parentUsesSize: true);
        actionBoxSize = actionBox.size;
      }

      // Recalculate tooltip height after resizing
      tooltipHeight = _toolTipBoxSize.height;
      if (hasSecondBox) {
        tooltipHeight += actionBoxSize.height + gapBetweenContentAndAction;
      }

      // Recalculate position if not flipping
      if (!needToFlip) {
        positionToolTip();
      }
    }

    // STEP 7: Handle flipping to opposite side if needed
    if (needToFlip) {
      switch (tooltipPosition) {
        case TooltipPosition.bottom:
          // Flip from bottom to top
          tooltipPosition = TooltipPosition.top;
          _yOffset = targetPosition.dy -
              _toolTipBoxSize.height -
              Constants.tooltipOffset;
          if (hasArrow) {
            _yOffset -= Constants.withArrowToolTipPadding;
          } else {
            _yOffset -= Constants.withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.top:
          // Flip from top to bottom
          tooltipPosition = TooltipPosition.bottom;
          _yOffset =
              targetPosition.dy + targetSize.height + Constants.tooltipOffset;
          if (hasArrow) {
            _yOffset += Constants.withArrowToolTipPadding;
          } else {
            _yOffset += Constants.withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.left:
          // Flip from left to right
          tooltipPosition = TooltipPosition.right;
          _xOffset =
              targetPosition.dx + targetSize.width + Constants.tooltipOffset;
          if (hasArrow) {
            _xOffset += Constants.withArrowToolTipPadding;
          } else {
            _xOffset += Constants.withOutArrowToolTipPadding;
          }
          break;

        case TooltipPosition.right:
          // Flip from right to left
          tooltipPosition = TooltipPosition.left;
          _xOffset = targetPosition.dx -
              _toolTipBoxSize.width -
              Constants.tooltipOffset;
          if (hasArrow) {
            _xOffset -= Constants.withArrowToolTipPadding;
          } else {
            _xOffset -= Constants.withOutArrowToolTipPadding;
          }
          break;
      }
    }

    // STEP 8: Final screen boundary check after all adjustments

    // Ensure tooltip stays within horizontal screen bounds
    _xOffset = _xOffset.clamp(
      screenEdgePadding + showcaseOffset.dx,
      screenSize.width -
          _toolTipBoxSize.width -
          screenEdgePadding +
          showcaseOffset.dx,
    );

    // Ensure tooltip stays within vertical screen bounds
    _yOffset = _yOffset.clamp(
      screenEdgePadding + showcaseOffset.dy,
      screenSize.height - tooltipHeight - screenEdgePadding + showcaseOffset.dy,
    );

    switch (tooltipPosition) {
      case TooltipPosition.top:
        _yOffset -= (targetPadding.top);
        break;
      case TooltipPosition.bottom:
        _yOffset += (targetPadding.bottom);
        break;
      case TooltipPosition.left:
        _xOffset -= (targetPadding.left);
        break;
      case TooltipPosition.right:
        _xOffset += targetPadding.right;
        break;
    }

    // STEP 9: Position all child elements

    // Position the tooltip content box
    if (toolTipBox != null) {
      final firstBoxParentData =
          toolTipBox.parentData! as MultiChildLayoutParentData;
      firstBoxParentData.offset = Offset(_xOffset, _yOffset);
    }

    // Position the action box (if exists)
    if (hasSecondBox && actionBox != null) {
      final secondBoxParentData =
          actionBox.parentData! as MultiChildLayoutParentData;

      // Position differently based on tooltip direction
      if (tooltipPosition.isTop) {
        // For top tooltips, action box goes above content
        secondBoxParentData.offset = Offset(_xOffset,
            _yOffset - actionBoxSize.height - gapBetweenContentAndAction);
      } else {
        // For other positions, action box goes below content
        secondBoxParentData.offset = Offset(_xOffset,
            _yOffset + _toolTipBoxSize.height + gapBetweenContentAndAction);
      }
    }

    const halfArrowWidth = Constants.arrowWidth * 0.5;
    const halfArrowHeight = Constants.arrowWidth * 0.5;
    final halfTargetHeight = targetSize.height * 0.5;
    final halfTargetWidth = targetSize.width * 0.5;

    // Position the arrow element (if exists)
    if (hasArrow && arrowBox != null) {
      final arrowBoxParentData =
          arrowBox.parentData! as MultiChildLayoutParentData;

      // Position arrow differently based on tooltip direction
      switch (tooltipPosition) {
        case TooltipPosition.top:
          // Arrow points down from bottom of tooltip
          arrowBoxParentData.offset = Offset(
            targetPosition.dx + halfTargetWidth - halfArrowWidth,
            _yOffset + _toolTipBoxSize.height - 2,
          );
          break;

        case TooltipPosition.bottom:
          // Arrow points up from top of tooltip
          arrowBoxParentData.offset = Offset(
            targetPosition.dx + halfTargetWidth - halfArrowWidth,
            _yOffset - Constants.arrowHeight + 2,
          );
          break;

        case TooltipPosition.left:
          // Arrow points right from right side of tooltip
          arrowBoxParentData.offset = Offset(
            _xOffset + _toolTipBoxSize.width - halfArrowHeight + 4,
            targetPosition.dy + halfTargetHeight - halfArrowWidth + 4,
          );
          break;

        case TooltipPosition.right:
          // Arrow points left from left side of tooltip
          arrowBoxParentData.offset = Offset(
            _xOffset - Constants.arrowHeight - 4,
            targetPosition.dy + halfTargetHeight - halfArrowHeight + 4,
          );
          break;
      }
    }
  }

  void positionToolTip() {
    final centerDxForTooltip = (targetSize.width - _toolTipBoxSize.width) * 0.5;
    final centerDyForTooltip =
        (targetSize.height - _toolTipBoxSize.height) * 0.5;

    switch (tooltipPosition) {
      case TooltipPosition.bottom:
        // Center horizontally below target
        _xOffset = targetPosition.dx + centerDxForTooltip;
        // Position below target with appropriate offset
        _yOffset =
            targetPosition.dy + targetSize.height + Constants.tooltipOffset;
        // Add additional padding if arrow is shown
        if (hasArrow) {
          _yOffset += Constants.withArrowToolTipPadding;
        } else {
          _yOffset += Constants.withOutArrowToolTipPadding;
        }
        break;

      case TooltipPosition.top:
        // Center horizontally above target
        _xOffset = targetPosition.dx + centerDxForTooltip;
        // Position above target with appropriate offset
        _yOffset = targetPosition.dy -
            _toolTipBoxSize.height -
            Constants.tooltipOffset;
        // Add additional padding if arrow is shown
        if (hasArrow) {
          _yOffset -= Constants.withArrowToolTipPadding;
        } else {
          _yOffset -= Constants.withOutArrowToolTipPadding;
        }
        break;

      case TooltipPosition.left:
        // Position to the left of target with appropriate offset
        _xOffset =
            targetPosition.dx - _toolTipBoxSize.width - Constants.tooltipOffset;
        // Add additional padding if arrow is shown
        if (hasArrow) {
          _xOffset -= Constants.withArrowToolTipPadding;
        } else {
          _xOffset -= Constants.withOutArrowToolTipPadding;
        }
        // Center vertically beside target
        _yOffset = targetPosition.dy + centerDyForTooltip;
        break;

      case TooltipPosition.right:
        // Position to the right of target with appropriate offset
        _xOffset =
            targetPosition.dx + targetSize.width + Constants.tooltipOffset;
        // Add additional padding if arrow is shown
        if (hasArrow) {
          _xOffset += Constants.withArrowToolTipPadding;
        } else {
          _xOffset += Constants.withOutArrowToolTipPadding;
        }
        // Center vertically beside target
        _yOffset = targetPosition.dy + centerDyForTooltip;
        break;
    }
  }

  /// Helper method to check if tooltip fits in a specific position
  ///
  /// Returns true if the tooltip fits in the given position without
  /// extending beyond screen boundaries
  bool _fitsInPosition(
      TooltipPosition pos, Size tooltipSize, double totalHeight) {
    switch (pos) {
      case TooltipPosition.bottom:
        // Check if tooltip fits below target
        return targetPosition.dy +
                targetSize.height +
                totalHeight +
                Constants.tooltipOffset +
                (hasArrow
                    ? Constants.withArrowToolTipPadding
                    : Constants.withOutArrowToolTipPadding) -
                showcaseOffset.dy <=
            screenSize.height - screenEdgePadding;

      case TooltipPosition.top:
        // Check if tooltip fits above target
        return targetPosition.dy -
                totalHeight -
                Constants.tooltipOffset -
                (hasArrow
                    ? Constants.withArrowToolTipPadding
                    : Constants.withOutArrowToolTipPadding) -
                showcaseOffset.dy >=
            screenEdgePadding;

      case TooltipPosition.left:
        // Check if tooltip fits to the left of target
        return targetPosition.dx -
                tooltipSize.width -
                Constants.tooltipOffset -
                (hasArrow
                    ? Constants.withArrowToolTipPadding
                    : Constants.withOutArrowToolTipPadding) -
                showcaseOffset.dx >=
            screenEdgePadding;

      case TooltipPosition.right:
        // Check if tooltip fits to the right of target
        return targetPosition.dx +
                targetSize.width +
                tooltipSize.width +
                Constants.tooltipOffset +
                (hasArrow
                    ? Constants.withArrowToolTipPadding
                    : Constants.withOutArrowToolTipPadding) -
                showcaseOffset.dx <=
            screenSize.width - screenEdgePadding;
    }
  }
}
