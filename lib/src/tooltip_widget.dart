/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:math';

import 'package:flutter/material.dart';

import 'enum.dart';
import 'get_position.dart';
import 'measure_size.dart';
import 'models/tooltip_action_config.dart';
import 'tooltip_position_config.dart';
import 'widget/action_widget.dart';
import 'widget/floating_action_widget.dart';
import 'widget/tooltip_slide_transition.dart';

const kDefaultArrowWidth = 18.0;
const kDefaultArrowHeight = 9.0;
const kWithArrowToolTipPadding = 16.0;
const kWithOutArrowToolTipPadding = 10.0;

class ToolTipWidget extends StatefulWidget {
  final GetPosition? position;
  final Offset? offset;
  final Size screenSize;
  final String? title;
  final TextAlign? titleTextAlign;
  final String? description;
  final TextAlign? descriptionTextAlign;
  final AlignmentGeometry titleAlignment;
  final AlignmentGeometry descriptionAlignment;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final Widget? container;
  final FloatingActionWidget? floatingActionWidget;
  final Color? tooltipBackgroundColor;
  final Color? textColor;
  final bool showArrow;
  final double? contentHeight;
  final double? contentWidth;
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

  const ToolTipWidget({
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
  State<ToolTipWidget> createState() => _ToolTipWidgetState();
}

class _ToolTipWidgetState extends State<ToolTipWidget>
    with TickerProviderStateMixin {
  Offset? position;

  bool get shouldShowActionsOutside =>
      widget.tooltipActions.isNotEmpty &&
      widget.tooltipActionConfig.position.isOutside;

  late final AnimationController _movingAnimationController;
  late final Animation<double> _movingAnimation;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _scaleAnimation;

  late TooltipPositionConfig config;

  // This is Default height considered at the start of this package
  var tooltipSize = const Size(0, 120);

  // To store Tooltip action size
  Size? _tooltipActionSize;

  final zeroPadding = EdgeInsets.zero;
  // This is used when [_tooltipActionSize] is already calculated and
  // on change of something we are recalculating the size of the widget
  bool isSizeRecalculating = false;

  TooltipPosition findPositionForContent(Offset position) {
    if (widget.tooltipPosition != null) return widget.tooltipPosition!;

    final widgetPosition = widget.position;
    final screenSize = widget.screenSize ?? MediaQuery.of(context).size;
    final verticalPositionCenter = (widget.position?.getHeight() ?? 0) * 0.5;

    final arrowHeight = widget.showArrow
        ? kWithArrowToolTipPadding
        : kWithOutArrowToolTipPadding;
    var height =
        tooltipSize.height + arrowHeight + widget.toolTipSlideEndDistance;

    // TODO: need to update for flutter version > 3.8.X
    // ignore: deprecated_member_use
    final EdgeInsets viewInsets = EdgeInsets.fromWindowPadding(
      // ignore: deprecated_member_use
      WidgetsBinding.instance.window.viewInsets,
      // ignore: deprecated_member_use
      WidgetsBinding.instance.window.devicePixelRatio,
    );
    final actualVisibleScreenHeight = screenSize.height - viewInsets.bottom;

    final bottomPosition = position.dy + verticalPositionCenter;
    final hasSpaceInBottom =
        (actualVisibleScreenHeight - bottomPosition) >= height;

    if (hasSpaceInBottom) return TooltipPosition.bottom;

    final topPosition = position.dy - verticalPositionCenter;
    final hasSpaceInTop = topPosition >= height;

    if (hasSpaceInTop) return TooltipPosition.top;

    if (widgetPosition == null) return TooltipPosition.bottom;

    // TODO: consider arrow and it's padding in the calculation as well.
    final tooltipWidth = widget.container == null
        ? tooltipSize.width
        : widget.contentWidth ?? _customContainerSize.value.width;

    final leftPosition = widgetPosition.getLeft();
    final hasSpaceInLeft = !((leftPosition - tooltipWidth).isNegative);
    if (hasSpaceInLeft) return TooltipPosition.left;

    final rightPosition = widgetPosition.getRight();
    final hasSpaceInRight = (rightPosition + tooltipWidth) < screenSize.width;
    if (hasSpaceInRight) return TooltipPosition.right;

    return TooltipPosition.bottom;
  }

  /// This will calculate the width and height of the tooltip
  void _getTooltipSize() {
    Size? toolTipActionSize;
    // if tooltip action is there this will calculate the height of that
    if (widget.tooltipActions.isNotEmpty) {
      final renderBox =
          _actionWidgetKey.currentContext?.findRenderObject() as RenderBox?;

      // if first frame is drawn then only we will be able to calculate the
      // size of the action widget
      if (renderBox != null && renderBox.hasSize) {
        toolTipActionSize = _tooltipActionSize = renderBox.size;
        isSizeRecalculating = false;
      } else if (_tooltipActionSize == null || renderBox == null) {
        // If first frame is not drawn then we will schedule the rebuild after
        // the first frame is drawn
        isSizeRecalculating = true;
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) setState(_getTooltipSize);
        });
        // If size is calculated once then we will wait for first frame
        // to draw before calculating anything as that may cause a flicker
        // in the tooltip
        if (_tooltipActionSize != null) {
          return;
        }
      }
    }

    final textTheme = Theme.of(context).textTheme;
    final titleStyle = widget.titleTextStyle ??
        textTheme.titleLarge!.merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        textTheme.titleSmall!.merge(TextStyle(color: widget.textColor));

    // This is to calculate the size of the title text
    // We have passed padding so we get the accurate width of the Title
    final titleSize = _textSize(
      widget.title,
      titleStyle,
      widget.titlePadding,
    );

    // This is to calculate the size of the description text
    // We have passed padding so we get the accurate width of the description
    final descriptionSize = _textSize(
      widget.description,
      descriptionStyle,
      widget.descriptionPadding,
    );

    final titleLength = titleSize?.width ?? 0;
    final descriptionLength = descriptionSize?.width ?? 0;
    // This is padding we will have around the tooltip text
    final textPadding = (widget.tooltipPadding ?? zeroPadding).horizontal +
        max((widget.titlePadding ?? zeroPadding).horizontal,
            (widget.descriptionPadding ?? zeroPadding).horizontal);

    final maxTextWidth = max(titleLength, descriptionLength) + textPadding;
    var maxToolTipWidth = max(toolTipActionSize?.width ?? 0, maxTextWidth);

    final availableSpaceForToolTip =
        widget.screenSize.width - (2 * widget.toolTipMargin);

    var tooltipWidth = 0.0;
    // if Width is greater than available size which won't happen we will
    // adjust it to stay in available size
    if (maxToolTipWidth > availableSpaceForToolTip) {
      tooltipWidth = availableSpaceForToolTip;
    } else {
      // Final tooltip width will be text width + padding around the tool tip
      // Here we have not considered the margin around the tooltip as that
      // doesn't count in width of the tooltip
      if ((toolTipActionSize?.width ?? 0) >= maxTextWidth) {
        tooltipWidth = toolTipActionSize?.width ?? 0;
      } else {
        tooltipWidth = maxToolTipWidth;
      }
    }

    // If user has provided the width then we will use the maximum of action
    // width and user provided width
    if (widget.contentWidth != null) {
      tooltipWidth = max(toolTipActionSize?.width ?? 0, widget.contentWidth!);
    }

    // To calculate the tooltip height
    // Text height + padding above and below of text  + arrow height + extra
    // space provided between target widget and tooltip widget  +
    // tooltip slide end distance + toolTip action Size
    var tooltipHeight = (widget.tooltipPadding ?? zeroPadding).vertical +
        (titleSize?.height ?? 0) +
        (descriptionSize?.height ?? 0) +
        (toolTipActionSize?.height ??
            widget.tooltipActionConfig.gapBetweenContentAndAction) +
        (widget.contentHeight ?? 0);

    tooltipSize = Size(tooltipWidth, tooltipHeight);
  }

  double _getSpace() {
    final tooltipWidth = tooltipSize.width;
    var space = widget.position!.getCenter() - (tooltipWidth * 0.5);
    if (space + tooltipWidth > widget.screenSize.width) {
      space = widget.screenSize.width - tooltipWidth - 8;
    } else if (space < (tooltipWidth * 0.5)) {
      space = 16;
    }
    return space;
  }

  final GlobalKey _customContainerKey = GlobalKey();
  final GlobalKey _actionWidgetKey = GlobalKey();
  final ValueNotifier<Size> _customContainerSize = ValueNotifier(Size.zero);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.container != null &&
          _customContainerKey.currentContext?.size != null) {
        // TODO: Is it wise to call setState here? All it is doing is setting
        // a value in ValueNotifier which does not require a setState to refresh anyway.
        setState(() {
          _customContainerSize.value =
              _customContainerKey.currentContext!.size!;
        });
      }
    });
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If tooltip is dismissing then no need to recalculate the size and widgets
    if (!widget.isTooltipDismissed) {
      _getTooltipSize();
    }
  }

  @override
  void didUpdateWidget(covariant ToolTipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If tooltip is dismissing then no need to recalculate the size and widgets
    // If widget is same as before then also no need to calculate
    if (!widget.isTooltipDismissed && oldWidget.hashCode != hashCode) {
      _getTooltipSize();
    }
  }

  @override
  void dispose() {
    _movingAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: maybe all this calculation doesn't need to run here. Maybe all or some of it can be moved outside?
    position = widget.offset;
    config = getConfiguration(findPositionForContent(position!))..initialize();

    // final contentOrientation = findPositionForContent(position!);
    // final contentOffsetMultiplier = config.position.isBottom ? 1.0 : -1.0;
    // isArrowUp = contentOffsetMultiplier == 1.0;
    //
    // final screenSize = MediaQuery.of(context).size;
    //
    // var contentY = isArrowUp
    //     ? widget.position!.getBottom() + (contentOffsetMultiplier * 3)
    //     : widget.position!.getTop() + (contentOffsetMultiplier * 3);
    //
    // // if tooltip is going out of screen in bottom this will ensure it is
    // // visible above the widget
    // if (contentY + tooltipSize.height >= screenSize.height && isArrowUp) {
    //   contentY = screenSize.height - tooltipSize.height;
    // }
    //
    // final num contentFractionalOffset =
    //     contentOffsetMultiplier.clamp(-1.0, 0.0);
    //
    // var paddingTop = isArrowUp ? _withArrowToolTipPadding : 0.0;
    // var paddingBottom = isArrowUp ? 0.0 : _withArrowToolTipPadding;
    //
    // if (!widget.showArrow) {
    //   paddingTop = _withOutArrowToolTipPadding;
    //   paddingBottom = _withOutArrowToolTipPadding;
    // }

    if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
      _scaleAnimationController.reverse();
    }

    if (widget.container == null) {
      final defaultToolTipWidget = Positioned(
        top: config.topPosition,
        left: config.leftPosition,
        right: config.rightPosition,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: widget.scaleAnimationAlignment ?? config.scaleAnimAlign,
          child: FractionalTranslation(
            translation: config.fractionalTranslation,
            child: ToolTipSlideTransition(
              position: config.slideTween.animate(_movingAnimation),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    if (shouldShowActionsOutside && config.position.isTop)
                      _getActionWidget(),
                    Padding(
                      padding:
                          widget.showArrow ? config.arrowPadding : zeroPadding,
                      child: Stack(
                        alignment: config.alignment,
                        clipBehavior: Clip.none,
                        children: [
                          // This widget is used for calculation of the action
                          // widget size and it will be removed once the size
                          // is calculated
                          if (isSizeRecalculating) _getOffstageActionWidget,
                          if (widget.showArrow)
                            Positioned(
                              left: config.arrowLeft,
                              right: config.arrowRight,
                              child: CustomPaint(
                                painter: _Arrow(
                                  strokeColor: widget.tooltipBackgroundColor!,
                                  strokeWidth: 10,
                                  paintingStyle: PaintingStyle.fill,
                                  position: config.position,
                                ),
                                child: config.position.isVertical
                                    ? const SizedBox(
                                        height: kDefaultArrowHeight,
                                        width: kDefaultArrowWidth,
                                      )
                                    : const SizedBox(
                                        height: kDefaultArrowWidth,
                                        width: kDefaultArrowHeight,
                                      ),
                              ),
                            ),
                          Padding(
                            padding: widget.showArrow
                                ? config.padding
                                : EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: widget.tooltipBorderRadius ??
                                  BorderRadius.circular(8.0),
                              child: GestureDetector(
                                onTap: widget.onTooltipTap,
                                child: Container(
                                  width: tooltipSize.width,
                                  padding: widget.tooltipPadding?.copyWith(
                                    left: 0,
                                    right: 0,
                                  ),
                                  color: widget.tooltipBackgroundColor,
                                  child: Column(
                                    children: <Widget>[
                                      if (widget.title != null)
                                        Align(
                                          alignment: widget.titleAlignment,
                                          child: Padding(
                                            padding: (widget.titlePadding ??
                                                    zeroPadding)
                                                .add(
                                              EdgeInsets.only(
                                                left: widget
                                                        .tooltipPadding?.left ??
                                                    0,
                                                right: widget.tooltipPadding
                                                        ?.right ??
                                                    0,
                                              ),
                                            ),
                                            child: Text(
                                              widget.title!,
                                              textAlign: widget.titleTextAlign,
                                              textDirection:
                                                  widget.titleTextDirection,
                                              style: widget.titleTextStyle ??
                                                  Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .merge(
                                                        TextStyle(
                                                          color:
                                                              widget.textColor,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                        ),
                                      if (widget.description != null)
                                        Align(
                                          alignment:
                                              widget.descriptionAlignment,
                                          child: Padding(
                                            padding:
                                                (widget.descriptionPadding ??
                                                        zeroPadding)
                                                    .add(
                                              EdgeInsets.only(
                                                left: widget
                                                        .tooltipPadding?.left ??
                                                    0,
                                                right: widget.tooltipPadding
                                                        ?.right ??
                                                    0,
                                              ),
                                            ),
                                            child: Text(
                                              widget.description!,
                                              textAlign:
                                                  widget.descriptionTextAlign,
                                              textDirection: widget
                                                  .descriptionTextDirection,
                                              style: widget.descTextStyle ??
                                                  Theme.of(context)
                                                      .textTheme
                                                      .titleSmall!
                                                      .merge(
                                                        TextStyle(
                                                          color:
                                                              widget.textColor,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                        ),
                                      if (widget.tooltipActions.isNotEmpty &&
                                          widget.tooltipActionConfig.position
                                              .isInside &&
                                          _tooltipActionSize != null)
                                        _getActionWidget(insideWidget: true),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (shouldShowActionsOutside &&
                        (_tooltipActionSize == null ||
                            config.position.isHorizontal ||
                            config.position.isBottom))
                      _getActionWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      if (widget.floatingActionWidget == null) {
        return defaultToolTipWidget;
      } else {
        return Stack(
          fit: StackFit.expand,
          children: [
            defaultToolTipWidget,
            widget.floatingActionWidget!,
          ],
        );
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          top: (config.topPosition ?? 10) -
              (config.position.isVertical ? 10 : 0),
          left: config.position.isVertical ? _getSpace() : config.leftPosition,
          right: config.position.isVertical ? null : config.rightPosition,
          child: FractionalTranslation(
            translation: config.fractionalTranslation,
            child: ToolTipSlideTransition(
              position: config.slideTween.animate(_movingAnimation),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTooltipTap,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: config.position.isTop ? 0 : kWithArrowToolTipPadding,
                      bottom: config.position.isBottom
                          ? 0
                          : kWithArrowToolTipPadding,
                    ),
                    color: Colors.transparent,
                    child: Center(
                      child: Stack(
                        children: [
                          // This widget is used for calculation of the action
                          // widget size and it will be removed once the size
                          // is calculated
                          // We have kept it in colum because if we put is
                          // outside in the stack then it will take whole
                          // screen size and width calculation will fail
                          if (isSizeRecalculating)
                            _getOffstageActionWidget
                          else
                            // This offset is used to make animation smoother
                            // when there is big action widget which make
                            // the tool tip to change it's position
                            SizedBox(
                              width: tooltipSize.width,
                              child: Column(
                                children: [
                                  if (widget.tooltipActions.isNotEmpty &&
                                      config.position.isTop)
                                    _getActionWidget(),
                                  MeasureSize(
                                    key: _customContainerKey,
                                    onSizeChange: onSizeChange,
                                    child: widget.container,
                                  ),
                                  if (widget.tooltipActions.isNotEmpty &&
                                      (config.position.isHorizontal ||
                                          config.position.isBottom))
                                    _getActionWidget(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.floatingActionWidget != null) widget.floatingActionWidget!,
      ],
    );
  }

  Widget get _getOffstageActionWidget => Offstage(
        child: ActionWidget(
          key: _actionWidgetKey,
          outSidePadding: widget.tooltipActionConfig.position.isInside &&
                  widget.container == null
              ? EdgeInsets.only(
                  left: widget.tooltipPadding?.left ?? 0,
                  right: widget.tooltipPadding?.right ?? 0,
                )
              : zeroPadding,
          tooltipActionConfig: widget.tooltipActionConfig,
          alignment: widget.tooltipActionConfig.alignment,
          width: null,
          crossAxisAlignment: widget.tooltipActionConfig.crossAxisAlignment,
          tooltipPosition: TooltipPosition.top,
          children: widget.tooltipActions,
        ),
      );

  Widget _getActionWidget({
    bool insideWidget = false,
  }) {
    return ActionWidget(
      tooltipActionConfig: widget.tooltipActionConfig,
      outSidePadding: insideWidget
          ? EdgeInsets.only(
              left: widget.tooltipPadding?.left ?? 0,
              right: widget.tooltipPadding?.right ?? 0,
            )
          : zeroPadding,
      alignment: widget.tooltipActionConfig.alignment,
      crossAxisAlignment: widget.tooltipActionConfig.crossAxisAlignment,
      width: _tooltipActionSize == null ? null : tooltipSize.width,
      tooltipPosition: insideWidget || config.position.isHorizontal
          ? TooltipPosition.bottom
          : config.position,
      children: widget.tooltipActions,
    );
  }

  void onSizeChange(Size? size) {
    var tempPos = position;
    tempPos = Offset(
      position?.dx ?? 0,
      position?.dy ?? 0 + (size ?? Size.zero).height,
    );
    if (mounted) {
      setState(() => position = tempPos);
    }
  }

  Size? _textSize(String? text, TextStyle style, EdgeInsets? padding) {
    if (text == null) {
      return null;
    }

    /// Available space for text will be calculated like this:
    /// screen size - padding around the Text - padding around tooltip widget
    /// - 2(margin provided to tooltip from the end of the screen)
    /// We have calculated this to get the exact amount of width this text can
    /// take so height can be calculated precisely for text
    final availableSpaceForText =
        (widget.position?.screenWidth ?? MediaQuery.of(context).size.width) -
            (padding ?? zeroPadding).horizontal -
            (widget.tooltipPadding ?? zeroPadding).horizontal -
            (2 * widget.toolTipMargin);

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),

      // TODO: replace this once we support sdk v3.12.
      // ignore: deprecated_member_use
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout(
        // This is used to make maintain the text in available space so height
        // and width calculation will be accurate
        maxWidth: availableSpaceForText,
      );
    return textPainter.size;
  }

  TooltipPositionConfig getConfiguration(TooltipPosition location) {
    return TooltipPositionConfig(
      position: location,
      size: widget.container == null ? tooltipSize : _customContainerSize.value,
      screenSize: widget.screenSize ?? MediaQuery.of(context).size,
      actionSize: _tooltipActionSize,
      widgetRect: widget.position?.getRect(),
      tooltipMargin: widget.toolTipMargin,
      tooltipPadding: widget.tooltipPadding,
      toolTipSlideEndDistance: widget.toolTipSlideEndDistance,
    );
  }
}

class _Arrow extends CustomPainter {
  /// Paints an Arrow to point towards the showcased widget.
  ///
  /// The pointed head of the arrow would be in the opposite direction of the
  /// tooltip [position].
  _Arrow({
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
    this.paintingStyle = PaintingStyle.stroke,
    this.position = TooltipPosition.bottom,
  }) : _paint = Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = paintingStyle;

  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final TooltipPosition position;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
        getTrianglePath(size.width, size.height),
        _paint,
      );

  Path getTrianglePath(double x, double y) {
    switch (position) {
      case TooltipPosition.bottom:
        return Path()
          ..moveTo(0, y)
          ..lineTo(x * 0.5, 0)
          ..lineTo(x, y)
          ..lineTo(0, y);
      case TooltipPosition.top:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(x, 0)
          ..lineTo(x * 0.5, y)
          ..lineTo(0, 0);
      case TooltipPosition.left:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(x, y * 0.5)
          ..lineTo(0, y)
          ..lineTo(0, 0);
      case TooltipPosition.right:
        return Path()
          ..moveTo(x, 0)
          ..lineTo(0, y * 0.5)
          ..lineTo(x, y)
          ..lineTo(x, 0);
    }
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.position != position;
  }
}
