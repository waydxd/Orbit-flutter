import 'package:flutter/material.dart';

import '../../../data/models/event_model.dart';
import 'event_preview_cover_loader.dart';

class EventLocationCoverGrid extends StatelessWidget {
  final List<EventModel> events;
  final double size;
  final double borderRadius;

  const EventLocationCoverGrid({
    required this.events, required this.size, super.key,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = events.length > 4 ? 4 : events.length;
    final tiles = List<Widget>.generate(4, (index) {
      if (index >= visibleCount) {
        return _placeholder();
      }

      final event = events[index];
      final shouldShowOverflow = events.length > 4 && index == 3;
      return Stack(
        fit: StackFit.expand,
        children: [
          EventPreviewCoverLoader(event: event, fit: BoxFit.cover),
          if (shouldShowOverflow)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: const Text(
                '...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      );
    });

    if (events.length <= 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: size,
          height: size,
          child: events.isEmpty
              ? _placeholder()
              : EventPreviewCoverLoader(event: events.first, fit: BoxFit.cover),
        ),
      );
    }

    final cellSize = size / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: Wrap(
          spacing: 0,
          runSpacing: 0,
          children: List<Widget>.generate(4, (index) {
            final isLeft = index % 2 == 0;
            final isTop = index < 2;
            return Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                border: Border(
                  right: isLeft
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 1,
                        )
                      : BorderSide.none,
                  bottom: isTop
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
              ),
              child: tiles[index],
            );
          }),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8E8F0),
      child: const Icon(
        Icons.image_outlined,
        size: 24,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}
