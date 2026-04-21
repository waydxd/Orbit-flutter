import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../data/services/suggestion_service.dart';
import '../../../generated/protos/suggestion.pbgrpc.dart';
import '../../core/themes/app_colors.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import 'dart:math' as math;

class DailySuggestionsWidget extends StatefulWidget {
  const DailySuggestionsWidget({super.key});

  @override
  State<DailySuggestionsWidget> createState() => _DailySuggestionsWidgetState();
}

class _DailySuggestionsWidgetState extends State<DailySuggestionsWidget> {
  // Store the last known future and events list to prevent flickering
  Future<List<Suggestion>>? _suggestionsFuture;
  List<EventModel>? _lastEvents;
  int? _lastEventsHash;
  List<Suggestion>? _cachedSuggestions;
  bool _isRegenerating = false;

  int _computeHash(List<EventModel> events) {
    if (events.isEmpty) return 0;
    return events
        .map((e) => e.updatedAt.millisecondsSinceEpoch)
        .reduce((a, b) => a ^ b);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<CalendarViewModel>(context);
    final currentHash = _computeHash(viewModel.events);
    // Only re-fetch if events list has changed (by hash or first time)
    if (_lastEventsHash == null || _lastEventsHash != currentHash) {
      _lastEvents = List.from(viewModel.events);
      _lastEventsHash = currentHash;
      _suggestionsFuture = _fetchSuggestions(viewModel.events)
        ..then((suggestions) {
          if (mounted) setState(() => _cachedSuggestions = suggestions);
        });
    }
  }

  void _regenerate() {
    if (_lastEvents == null) return;
    setState(() {
      _isRegenerating = true;
      _suggestionsFuture =
          _fetchSuggestions(_lastEvents!, forceRegenerate: true)
              .then((suggestions) {
        if (mounted) {
          setState(() {
            _cachedSuggestions = suggestions;
            _isRegenerating = false;
          });
        }
        return suggestions;
      }).catchError((e) {
        if (mounted) {
          setState(() => _isRegenerating = false);
        }
        return <Suggestion>[];
      });
    });
  }

  Future<List<Suggestion>> _fetchSuggestions(List<EventModel> allEvents,
      {bool forceRegenerate = false}) async {
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = DateFormat('yyyy-MM-dd').format(today);

    final todayEvents = allEvents.where((e) {
      final startLocal = e.startTime.toLocal();
      return startLocal.year == today.year &&
          startLocal.month == today.month &&
          startLocal.day == today.day;
    }).toList();

    final service = OrbitSuggestionService();

    if (todayEvents.isNotEmpty) {
      final List<List<Suggestion>> perEventResults = await Future.wait(
        todayEvents.map((evt) => service
            .getSuggestionsForEvent(evt,
                userId: user?.id ?? '', forceRegenerate: forceRegenerate)
            .catchError((_) => <Suggestion>[])),
      );
      final List<Suggestion> allEventSuggestions =
          perEventResults.expand((sugs) => sugs).toList();

      // Deduplicate event suggestions based on title
      final uniqueEventSuggestions = <Suggestion>[];
      final seenTitles = <String>{};
      for (var s in allEventSuggestions) {
        if (!seenTitles.contains(s.title)) {
          seenTitles.add(s.title);
          uniqueEventSuggestions.add(s);
        }
      }

      final results = uniqueEventSuggestions.take(3).toList();

      // Fetch daily suggestions and append 1
      final dailySugs = await service.getDailySuggestions(
          dateStr, user, allEvents,
          forceRegenerate: forceRegenerate);
      if (dailySugs.isNotEmpty) {
        results.add(dailySugs.first);
      }

      return results;
    } else {
      return await service.getDailySuggestions(dateStr, user, allEvents,
          forceRegenerate: forceRegenerate);
    }
  }

  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.SUGGESTION_TYPE_TRANSPORTATION:
        return Icons.directions_transit;
      case SuggestionType.SUGGESTION_TYPE_ATTIRE:
        return Icons.checkroom;
      case SuggestionType.SUGGESTION_TYPE_PREPARATION:
        return Icons.inventory_2;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _getLabelForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.SUGGESTION_TYPE_TRANSPORTATION:
        return 'Transit';
      case SuggestionType.SUGGESTION_TYPE_ATTIRE:
        return 'Attire';
      case SuggestionType.SUGGESTION_TYPE_PREPARATION:
        return 'Prep';
      default:
        return 'Tip';
    }
  }

  Widget _buildEmptyCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0047AB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0047AB),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Suggestion>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        Widget content;

        final activeSuggestions = snapshot.data ?? _cachedSuggestions;

        if (snapshot.connectionState == ConnectionState.waiting &&
            activeSuggestions == null) {
          content = _buildEmptyCard(
            'Generating Suggestions...',
            'Please wait a moment while AI builds your tips.',
            Icons.auto_awesome,
          );
        } else if (activeSuggestions == null || activeSuggestions.isEmpty) {
          content = _buildEmptyCard(
            'Try to generate your daily suggestions now!',
            'Click the button below to get personalized tips for today.',
            Icons.auto_awesome,
          );
        } else {
          final suggestions = activeSuggestions;
          content = SuggestionCarousel(
            items: suggestions,
            iconBuilder: _getIconForType,
            labelBuilder: _getLabelForType,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _isRegenerating ? null : _regenerate,
                icon: _isRegenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, size: 20),
                label: Text(_isRegenerating
                    ? 'Regenerating...'
                    : 'Regenerate Suggestions'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SuggestionCarousel extends StatefulWidget {
  final List<Suggestion> items;
  final double viewportFraction;
  final IconData Function(SuggestionType) iconBuilder;
  final String Function(SuggestionType) labelBuilder;

  const SuggestionCarousel({
    required this.items,
    required this.iconBuilder,
    required this.labelBuilder,
    super.key,
    this.viewportFraction = 0.95, // Increased from 0.88 to make the card wider
  });

  @override
  State<SuggestionCarousel> createState() => _SuggestionCarouselState();
}

class _SuggestionCarouselState extends State<SuggestionCarousel> {
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
  void didUpdateWidget(covariant SuggestionCarousel oldWidget) {
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

    const cardHeight = 200.0;
    const pageViewHeight = cardHeight + 48.0 // Gap
        ;

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
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 16.0), // Slightly increased top padding
                        child: _OrbitCardShell(
                          orbitDelta: delta,
                          child: child!,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _SuggestionCard(
                      suggestion: widget.items[index],
                      height: cardHeight,
                      icon: widget.iconBuilder(widget.items[index].type),
                      label: widget.labelBuilder(widget.items[index].type),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Dots slider directly underneath the box
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
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

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
    final angleY = -d * (math.pi / 6.5);
    final scale = 1.0 - 0.09 * absD.clamp(0.0, 1.0);
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

class _SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final double height;
  final IconData icon;
  final String label;

  const _SuggestionCard({
    required this.suggestion,
    required this.height,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(
              alpha: 0.8), // Match Today's Statistics cards background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0047AB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: const Color(0xFF0047AB)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF0047AB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                suggestion.title,
                style: const TextStyle(
                  fontSize: 21.2,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    suggestion.description.isNotEmpty
                        ? suggestion.description
                        : 'No description',
                    style: const TextStyle(
                      fontSize: 14.8,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
