import 'package:flutter/material.dart';

import '../../../data/models/event_model.dart';
import 'event_location_cover_grid.dart';

/// Map overlay or sheet card: square image, thick white frame, optional pointer.
/// [onMagnifyMap] zooms the map camera (same as the map zoom-in control), not the thumbnail.
class EventMapCallout extends StatelessWidget {
  static const double width = 128;

  final double cardWidth;
  final List<EventModel> events;
  final VoidCallback? onTap;
  final bool showPointer;
  final VoidCallback? onMagnifyMap;

  const EventMapCallout({
    required this.events, super.key,
    this.cardWidth = width,
    this.onTap,
    this.showPointer = true,
    this.onMagnifyMap,
  });

  @override
  Widget build(BuildContext context) {
    const borderWidth = 4.0;
    const radius = 12.0;
    const innerRadius = 8.0;
    // Stack + only Positioned.fill gets 0 height when max height is unbounded
    // (Column parent). Fix: explicit square, same as former AspectRatio(1:1).
    final innerSide = cardWidth - 2 * borderWidth;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: cardWidth,
            padding: const EdgeInsets.all(borderWidth),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: SizedBox(
              width: innerSide,
              height: innerSide,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(innerRadius),
                        child: EventLocationCoverGrid(
                          events: events,
                          size: innerSide,
                          borderRadius: innerRadius,
                        ),
                      ),
                    ),
                  ),
                  if (onMagnifyMap != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onMagnifyMap,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showPointer)
            CustomPaint(
              size: const Size(18, 10),
              painter: _CalloutTrianglePainter(),
            ),
        ],
      ),
    );
  }
}

class _CalloutTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
