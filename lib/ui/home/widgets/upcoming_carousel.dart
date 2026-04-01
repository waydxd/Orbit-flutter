import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/widgets/card_stack_item.dart';

/// Horizontal [PageView] carousel for upcoming tasks/events.
/// Uses a real scrollable so gestures cooperate with a parent [ListView].
/// Each page is given a perspective [rotateY] and slight vertical arc so
/// swiping feels like cards move on an orbital path.
class UpcomingCarousel extends StatefulWidget {
  final List<CardStackItem> items;
  final double viewportFraction;

  const UpcomingCarousel({
    required this.items,
    super.key,
    this.viewportFraction = 0.88,
  });

  @override
  State<UpcomingCarousel> createState() => _UpcomingCarouselState();
}

class _UpcomingCarouselState extends State<UpcomingCarousel> {
  late final PageController _pageController;
  late final ValueNotifier<double> _orbitPage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    _orbitPage = ValueNotifier<double>(0);
  }

  @override
  void didUpdateWidget(covariant UpcomingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final len = widget.items.length;
    if (len == 0) return;
    if (_currentPage >= len) {
      final target = len - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(target);
        setState(() => _currentPage = target);
      });
    }
  }

  @override
  void dispose() {
    _orbitPage.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics is! PageMetrics) return false;
    final p = (n.metrics as PageMetrics).page;
    if (p == null) return false;
    _orbitPage.value = p;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    const cardHeight = 160.0;
    // Extra vertical space so perspective tilt, arc, and shadows are not clipped.
    const orbitViewportExtra = 72.0;
    const pageViewHeight = cardHeight + orbitViewportExtra;
    final dotCount = widget.items.length.clamp(0, 5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: pageViewHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: PageView.builder(
              controller: _pageController,
              clipBehavior: Clip.none,
              itemCount: widget.items.length,
              physics: const BouncingScrollPhysics(),
              padEnds: true,
              onPageChanged: (i) {
                setState(() => _currentPage = i);
                _orbitPage.value = i.toDouble();
              },
              itemBuilder: (context, index) {
                return ValueListenableBuilder<double>(
                  valueListenable: _orbitPage,
                  builder: (context, page, child) {
                    final delta = index - page;
                    return Align(
                      alignment: Alignment.center,
                      child: _OrbitCardShell(
                        orbitDelta: delta,
                        child: child!,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: _UpcomingCard(
                      item: widget.items[index],
                      height: cardHeight,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF6366F1).withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Scroll-linked perspective tilt and arc lift so pages feel like they orbit.
class _OrbitCardShell extends StatelessWidget {
  final double orbitDelta;
  final Widget child;

  const _OrbitCardShell({
    required this.orbitDelta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final d = orbitDelta.clamp(-1.35, 1.35);
    final absD = d.abs();

    // Y rotation: pages to the right tilt one way, to the left the other.
    final angleY = -d * (math.pi / 6.5);

    // Slight scale — center page is largest.
    final scale = 1.0 - 0.09 * absD.clamp(0.0, 1.0);

    // Arc: off-center pages sit slightly lower (circular path feel).
    final orbitLift =
        18.0 * (1.0 - math.cos(absD.clamp(0.0, 1.0) * math.pi / 2));

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.00135)
      ..translateByDouble(0.0, orbitLift, 0.0, 1)
      ..rotateY(angleY);

    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      filterQuality: FilterQuality.medium,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final CardStackItem item;
  final double height;

  const _UpcomingCard({
    required this.item,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 28,
              spreadRadius: -2,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (item.tagColor ?? const Color(0xFF6366F1))
                          .withValues(alpha: 0.2),
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
              item.description?.isNotEmpty == true
                  ? item.description!
                  : 'No description',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
