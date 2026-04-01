import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
import 'card_stack_item.dart';

/// A fanned stack of cards with 3D perspective, spring physics, and swipe gestures.
class CardStackCarousel extends StatefulWidget {
  final List<CardStackItem> items;
  final int initialIndex;
  final int maxVisible;
  final double cardWidth;
  final double cardHeight;
  final double overlap;
  final double spreadDeg;
  final double perspectivePx;
  final double activeLiftPx;
  final double activeScale;
  final double inactiveScale;
  final int springStiffness;
  final int springDamping;
  final bool loop;
  final bool autoAdvance;
  final int intervalMs;
  final bool pauseOnHover;
  final bool showDots;
  final void Function(int index, CardStackItem item)? onChangeIndex;
  final Widget Function(CardStackItem item, bool active)? renderCard;

  const CardStackCarousel({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.maxVisible = 5,
    this.cardWidth = 280,
    this.cardHeight = 160,
    this.overlap = 0.48,
    this.spreadDeg = 48,
    this.perspectivePx = 0.001,
    this.activeLiftPx = 10,
    this.activeScale = 1.03,
    this.inactiveScale = 0.94,
    this.springStiffness = 280,
    this.springDamping = 28,
    this.loop = true,
    this.autoAdvance = true,
    this.intervalMs = 5000,
    this.pauseOnHover = true,
    this.showDots = true,
    this.onChangeIndex,
    this.renderCard,
  });

  @override
  State<CardStackCarousel> createState() => _CardStackCarouselState();
}

class _CardStackCarouselState extends State<CardStackCarousel>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _springController;
  late AnimationController _autoAdvanceController;
  late ValueNotifier<double> _dragOffsetNotifier;

  double _dragOffset = 0;
  bool _isDragging = false;
  bool _isPaused = false;

  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _dragOffsetNotifier = ValueNotifier<double>(0);

    _springController = AnimationController.unbounded(vsync: this);
    _autoAdvanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _springController.addListener(_onSpringUpdate);

    if (widget.autoAdvance) {
      _startAutoAdvance();
    }
  }

  @override
  void dispose() {
    _dragOffsetNotifier.dispose();
    _springController.dispose();
    _autoAdvanceController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(
      Duration(milliseconds: widget.intervalMs),
      (_) {
        if (!_isPaused && !_isDragging) {
          _goToNext();
        }
      },
    );
  }

  void _onSpringUpdate() {
    _dragOffsetNotifier.value = _springController.value;
  }

  void _goToNext() {
    final newIndex = widget.loop
        ? (_currentIndex + 1) % widget.items.length
        : math.min(_currentIndex + 1, widget.items.length - 1);

    if (newIndex != _currentIndex) {
      _animateToIndex(newIndex, -1);
    }
  }

  void _animateToIndex(int targetIndex, int direction) {
    final spring = SpringDescription(
      mass: 1,
      stiffness: widget.springStiffness.toDouble(),
      damping: widget.springDamping.toDouble(),
    );

    final simulation = SpringSimulation(
      spring,
      _dragOffsetNotifier.value,
      direction * widget.cardWidth * (1 - widget.overlap),
      0,
    );

    _springController.animateWith(simulation).then((_) {
      setState(() {
        _currentIndex = targetIndex;
      });
      _dragOffsetNotifier.value = 0;
      widget.onChangeIndex?.call(_currentIndex, widget.items[_currentIndex]);
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _isDragging = true;
    _springController.stop();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragOffsetNotifier.value += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = math.min(160.0, widget.cardWidth * 0.22);
    final currentOffset = _dragOffsetNotifier.value;

    if (currentOffset.abs() > threshold || velocity.abs() > 650) {
      if (currentOffset < 0 || velocity < -650) {
        _animateToIndex(
          widget.loop
              ? (_currentIndex + 1) % widget.items.length
              : math.min(_currentIndex + 1, widget.items.length - 1),
          -1,
        );
      } else {
        _animateToIndex(
          widget.loop
              ? (_currentIndex - 1 + widget.items.length) % widget.items.length
              : math.max(_currentIndex - 1, 0),
          1,
        );
      }
    } else {
      // Snap back
      final spring = SpringDescription(
        mass: 1,
        stiffness: widget.springStiffness.toDouble(),
        damping: widget.springDamping.toDouble(),
      );

      final simulation = SpringSimulation(spring, currentOffset, 0, velocity / 1000);
      _springController.animateWith(simulation).then((_) {
        _dragOffsetNotifier.value = 0;
      });
    }
  }

  void _onCardTap(int index) {
    if (index != _currentIndex) {
      final direction = index > _currentIndex ? -1 : 1;
      _animateToIndex(index, direction);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState();
    }

    return MouseRegion(
      onEnter: (_) {
        if (widget.pauseOnHover) setState(() => _isPaused = true);
      },
      onExit: (_) {
        if (widget.pauseOnHover) setState(() => _isPaused = false);
      },
      child: SizedBox(
        width: widget.cardWidth + 40,
        height: widget.cardHeight + 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cards
            ValueListenableBuilder<double>(
              valueListenable: _dragOffsetNotifier,
              builder: (context, dragOffset, child) {
                return Stack(children: _buildCardsWithOffset(dragOffset));
              },
            ),

            // Dot indicators
            if (widget.showDots) _buildDotIndicators(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardsWithOffset(double dragOffset) {
    final cards = <Widget>[];
    final totalCards = widget.items.length;
    final halfMax = widget.maxVisible ~/ 2;
    final stepDeg = widget.spreadDeg / widget.maxVisible;
    final cardSpacing = widget.cardWidth * (1 - widget.overlap);

    for (int offset = -halfMax; offset <= halfMax; offset++) {
      final int index = (_currentIndex + offset + totalCards) % totalCards;

      // Adjust for edge cases when not looping
      double effectiveOffset = offset.toDouble();
      if (!widget.loop) {
        if (_currentIndex < halfMax && offset > _currentIndex + halfMax - totalCards + 1) {
          continue;
        }
        if (_currentIndex >= totalCards - halfMax && offset < _currentIndex - (totalCards - halfMax - 1)) {
          effectiveOffset = offset - (_currentIndex - (totalCards - halfMax - 1));
        }
      }
      final xOffset = effectiveOffset * cardSpacing + dragOffset;
      final rotateZ = effectiveOffset * stepDeg * math.pi / 180;

      // Scale: active card is larger
      final isActive = offset == 0;
      final scale = isActive
          ? widget.activeScale
          : widget.inactiveScale + (widget.activeScale - widget.inactiveScale) * (1 - offset.abs() / widget.maxVisible);

      // Y offset: active card lifts up
      final yOffset = isActive ? -widget.activeLiftPx : widget.activeLiftPx * (offset.abs() / widget.maxVisible);

      cards.add(
        Positioned(
          left: (widget.cardWidth + 40) / 2 - widget.cardWidth / 2 + xOffset,
          top: 30 + yOffset + (isActive ? 0 : offset.sign * 10),
          child: GestureDetector(
            onTap: () => _onCardTap(index),
            onHorizontalDragStart: isActive ? _onHorizontalDragStart : null,
            onHorizontalDragUpdate: isActive ? _onHorizontalDragUpdate : null,
            onHorizontalDragEnd: isActive ? _onHorizontalDragEnd : null,
            child: Transform(
              alignment: Alignment.center,
              transform: (Matrix4.identity()
                ..setEntry(3, 2, widget.perspectivePx)
                ..rotateZ(rotateZ)
                ..rotateY(rotateZ * 0.5)) * Matrix4.diagonal3Values(scale, scale, 1.0),
              child: widget.renderCard?.call(widget.items[index], isActive) ??
                  _buildDefaultCard(widget.items[index], isActive),
            ),
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildDefaultCard(CardStackItem item, bool isActive) {
    return Container(
      width: widget.cardWidth,
      height: widget.cardHeight,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.12 : 0.05),
            blurRadius: isActive ? 20 : 10,
            offset: Offset(0, isActive ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.tag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (item.tagColor ?? const Color(0xFF6366F1)).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.tag!,
                    style: TextStyle(
                      color: item.tagColor ?? const Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
              ],
              if (item.dateTime != null)
                Text(
                  DateFormat('MMM d, h:mm a').format(item.dateTime!),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            item.description ?? 'No description',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Positioned(
      bottom: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.items.length.clamp(0, 5),
          (index) {
            final isActive = widget.loop
                ? index == _currentIndex % widget.items.length
                : index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF6366F1).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: widget.cardWidth,
      height: widget.cardHeight,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Center(
        child: Text(
          'No upcoming items!',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
