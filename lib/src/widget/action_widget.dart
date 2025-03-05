import 'package:flutter/material.dart';

import '../../showcaseview.dart';

class ActionWidget extends StatelessWidget {
  const ActionWidget({
    super.key,
    required this.children,
    required this.tooltipActionConfig,
    required this.alignment,
    required this.crossAxisAlignment,
    required this.isArrowUp,
    this.outSidePadding = EdgeInsets.zero,
    this.width,
    this.isHidden = false,
  });

  final TooltipActionConfig tooltipActionConfig;
  final List<Widget> children;
  final double? width;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets outSidePadding;
  final bool isArrowUp;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final getWidgetPadding = EdgeInsets.only(
            // top: isArrowUp ? tooltipActionConfig.gapBetweenContentAndAction : 0.0,
            // bottom: !isArrowUp ? tooltipActionConfig.gapBetweenContentAndAction : 0.0,
            )
        .add(outSidePadding);

    return SizedBox(
      // width: width,
      child: Padding(
        padding: getWidgetPadding,
        child: Row(
          mainAxisSize:
              width == null || isHidden ? MainAxisSize.max : MainAxisSize.max,
          mainAxisAlignment: width == null || isHidden ? alignment : alignment,
          crossAxisAlignment: crossAxisAlignment,
          textBaseline: tooltipActionConfig.textBaseline,
          children: children,
        ),
      ),
    );
  }
}
