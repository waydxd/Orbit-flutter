import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/hashtag_palette.dart';
import '../../../data/models/event_model.dart';
import '../../../data/utils/event_recurrence.dart';
import '../timetable_overlap_layout.dart';
import '../view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import 'event_detail_page.dart';

const double _kTimetableHourHeight = 80.0;
const double _kTimetableLaneGap = 2.0;

/// One calendar day row height in the infinite vertical timeline.
const double _kDayRowExtent = 24 * _kTimetableHourHeight;

/// Inclusive start of the scrollable timeline (local midnight).
final DateTime _kTimelineStart = DateTime(2018, 1, 1);

/// Exclusive end: last renderable day is the day before this.
final DateTime _kTimelineEndExclusive = DateTime(2036, 1, 1);

int _timelineDayCount() =>
    _kTimelineEndExclusive.difference(_kTimelineStart).inDays;

typedef _TimetableStripSegment = ({
  DateTime start,
  DateTime end,
  EventModel event,
});

/// Event segments clipped to `[day, day+1)` in local time.
List<_TimetableStripSegment> _segmentsForCalendarDay(
  List<EventModel> events,
  DateTime day,
) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final out = <_TimetableStripSegment>[];
  for (final e in events) {
    if (e.recurrenceRule.trim().isEmpty) {
      if (e.endTime.isAfter(dayStart) && e.startTime.isBefore(dayEnd)) {
        final s = e.startTime.isBefore(dayStart) ? dayStart : e.startTime;
        final t = e.endTime.isAfter(dayEnd) ? dayEnd : e.endTime;
        if (t.isAfter(s)) {
          out.add((start: s, end: t, event: e));
        }
      }
    } else {
      if (!EventRecurrence.occursOnDay(e, dayStart)) continue;
      final occStart = DateTime(
        dayStart.year,
        dayStart.month,
        dayStart.day,
        e.startTime.hour,
        e.startTime.minute,
        e.startTime.second,
      );
      final occEndDay = DateTime(
        dayStart.year,
        dayStart.month,
        dayStart.day,
        e.endTime.hour,
        e.endTime.minute,
        e.endTime.second,
      );
      final occEnd = occEndDay.isAfter(occStart)
          ? occEndDay
          : occEndDay.add(const Duration(days: 1));
      if (occEnd.isAfter(dayStart) && occStart.isBefore(dayEnd)) {
        final s = occStart.isBefore(dayStart) ? dayStart : occStart;
        final t = occEnd.isAfter(dayEnd) ? dayEnd : occEnd;
        if (t.isAfter(s)) {
          out.add((start: s, end: t, event: e));
        }
      }
    }
  }
  out.sort((a, b) => a.start.compareTo(b.start));
  return out;
}

Widget _calendarTaskCard(
  String title,
  String subtitle,
  String time,
  Color color,
) {
  final onAccent = onHashtagAccentColor(color);
  final onMuted = onHashtagAccentMutedColor(color);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: onAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: onMuted, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: TextStyle(
                color: onAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Dots under month/week/year cells — one color per event ([accentForEventDisplay]).
Widget? _calendarMarkerLayout(List<dynamic> events) {
  if (events.isEmpty) return null;
  return Positioned(
    bottom: 1,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: events.map((e) {
        final event = e as EventModel;
        final color = accentForEventDisplay(
          title: event.title,
          hashtags: event.hashtags,
        );
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    ),
  );
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Drag & Layout State
  double _currentHeight = 188.0; // Start with Week view height
  final double _weekHeight = 188.0;
  final double _monthHeight = 392.0;

  /// Reserve space so the timetable Column never collapses past this height.
  static const double _kMinTimetableHeight = 200.0;
  bool _isDragging = false;
  // Height will be calculated dynamically

  // View Mode
  CalendarViewMode _viewMode = CalendarViewMode.week;

  /// Vertical infinite day timeline (replaces PageView).
  late final ScrollController _timetableScrollController;
  Timer? _timetableFetchDebounce;
  bool _timetableInitialScrollApplied = false;

  /// Year view: scroll month list to [DateTime.now] month when viewing current year.
  late final ScrollController _yearMonthsScrollController;
  final List<GlobalKey> _yearMonthItemKeys =
      List<GlobalKey>.generate(12, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _timetableScrollController = ScrollController();
    _timetableScrollController.addListener(_onTimelineScroll);
    _yearMonthsScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyInitialTimelineScrollIfNeeded();
    });
  }

  @override
  void dispose() {
    _timetableFetchDebounce?.cancel();
    _timetableScrollController.removeListener(_onTimelineScroll);
    _timetableScrollController.dispose();
    _yearMonthsScrollController.dispose();
    super.dispose();
  }

  void _scrollYearViewToCurrentMonth() {
    if (_viewMode != CalendarViewMode.year) return;
    final nowY = DateTime.now().year;
    if (_focusedDay.year != nowY) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewMode != CalendarViewMode.year) return;
      if (_focusedDay.year != nowY) return;
      final idx = DateTime.now().month - 1;
      final ctx = _yearMonthItemKeys[idx].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.0,
          duration: Duration.zero,
        );
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewMode != CalendarViewMode.year) return;
        final ctx2 = _yearMonthItemKeys[idx].currentContext;
        if (ctx2 != null) {
          Scrollable.ensureVisible(
            ctx2,
            alignment: 0.0,
            duration: Duration.zero,
          );
        }
      });
    });
  }

  void _onYearChangedOnChevron() {
    final y = _focusedDay.year;
    final nowY = DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_viewMode != CalendarViewMode.year) return;
      if (y == nowY) {
        _scrollYearViewToCurrentMonth();
      } else if (_yearMonthsScrollController.hasClients) {
        _yearMonthsScrollController.jumpTo(0);
      }
    });
  }

  int _dayIndexForDate(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.difference(_kTimelineStart).inDays;
  }

  DateTime _dateForDayIndex(int index) {
    return _kTimelineStart.add(Duration(days: index));
  }

  void _applyInitialTimelineScrollIfNeeded() {
    if (_timetableInitialScrollApplied) return;
    if (!_timetableScrollController.hasClients) return;
    _timetableInitialScrollApplied = true;
    final day = _selectedDay ?? DateTime.now();
    _jumpTimelineToDay(day, animate: false);
  }

  /// Scroll offset so [day] row is at top, optionally offset by time within day.
  double _scrollOffsetForDay(DateTime day, {bool alignToNowIfToday = true}) {
    final count = _timelineDayCount();
    final idx = _dayIndexForDate(day).clamp(0, count - 1);
    var offset = idx * _kDayRowExtent;
    final now = DateTime.now();
    if (alignToNowIfToday && isSameDay(day, now)) {
      final within = (now.hour + now.minute / 60.0) * _kTimetableHourHeight;
      offset += within.clamp(0.0, _kDayRowExtent - 24);
    }
    final maxScroll = math.max(0.0, count * _kDayRowExtent - 1);
    return offset.clamp(0.0, maxScroll);
  }

  void _jumpTimelineToDay(DateTime day, {required bool animate}) {
    if (!_timetableScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jumpTimelineToDay(day, animate: animate);
      });
      return;
    }
    final target = _scrollOffsetForDay(day);
    if (animate) {
      _timetableScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _timetableScrollController.jumpTo(target);
    }
  }

  void _onTimelineScroll() {
    if (!_timetableScrollController.hasClients) return;
    final p = _timetableScrollController.position;
    final count = _timelineDayCount();
    final center = p.pixels + p.viewportDimension / 2.0;
    var idx = (center / _kDayRowExtent).floor();
    idx = idx.clamp(0, count - 1);
    final visible = _dateForDayIndex(idx);
    _onTimetableVisibleCalendarDay(visible);
    _scheduleTimetableDataFetch(visible);
  }

  void _onTimetableVisibleCalendarDay(DateTime visibleDay) {
    final selected = _selectedDay;
    if (selected != null && isSameDay(selected, visibleDay)) return;
    setState(() {
      _selectedDay = visibleDay;
      _focusedDay = visibleDay;
    });
  }

  void _scheduleTimetableDataFetch(DateTime visibleDay) {
    _timetableFetchDebounce?.cancel();
    _timetableFetchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId == null) return;
      final d = DateTime(visibleDay.year, visibleDay.month, visibleDay.day);
      final prev = d.subtract(const Duration(days: 1));
      final next = d.add(const Duration(days: 1));
      context.read<CalendarViewModel>().fetchAll(
            userId: userId,
            eventRangeAnchor: d,
            mergeEventAnchors: [prev, next],
            fullYearRange: _viewMode == CalendarViewMode.year,
            showLoading: false,
          );
    });
  }

  void _refetchEventsForCalendar({required bool fullYearRange}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId == null) return;
      final anchor = _focusedDay;
      final d = DateTime(anchor.year, anchor.month, anchor.day);
      context.read<CalendarViewModel>().fetchAll(
            userId: userId,
            eventRangeAnchor: d,
            mergeEventAnchors: [
              d.subtract(const Duration(days: 1)),
              d.add(const Duration(days: 1)),
            ],
            fullYearRange: fullYearRange,
            showLoading: false,
          );
    });
  }

  double _maxCalendarContentHeight(double screenHeight, double topPadding) {
    return math.max(
      _weekHeight,
      screenHeight - topPadding - _kMinTimetableHeight,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double maxCal = _maxCalendarContentHeight(screenHeight, topPadding);

    final prevMode = _viewMode;
    setState(() {
      _currentHeight += details.delta.dy;
      // Clamp height
      if (_currentHeight < _weekHeight) _currentHeight = _weekHeight;
      if (_currentHeight > maxCal) _currentHeight = maxCal;

      // Dynamic mode switching based on height thresholds
      // Use relative thresholds to make it feel responsive
      if (_currentHeight > _monthHeight + 100) {
        _viewMode = CalendarViewMode.year;
      } else if (_currentHeight > _weekHeight + 50) {
        _viewMode = CalendarViewMode.month;
        _calendarFormat = CalendarFormat.month;
      } else {
        _viewMode = CalendarViewMode.week;
        _calendarFormat = CalendarFormat.week;
      }
    });
    if (_viewMode == CalendarViewMode.year &&
        prevMode != CalendarViewMode.year) {
      _refetchEventsForCalendar(fullYearRange: true);
      _scrollYearViewToCurrentMonth();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double maxCal = _maxCalendarContentHeight(screenHeight, topPadding);

    // Improved snapping logic with velocity assistance
    double targetHeight;
    CalendarViewMode targetMode;

    final double velocity = details.velocity.pixelsPerSecond.dy;

    // If moving down fast, snap to next larger view
    if (velocity > 500) {
      if (_currentHeight < _monthHeight) {
        targetHeight = _monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = maxCal;
        targetMode = CalendarViewMode.year;
      }
    }
    // If moving up fast, snap to next smaller view
    else if (velocity < -500) {
      if (_currentHeight > _monthHeight) {
        targetHeight = _monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = _weekHeight;
        targetMode = CalendarViewMode.week;
      }
    }
    // Otherwise use position thresholds (unchanged)
    else {
      if (_currentHeight > (_monthHeight + maxCal) / 2) {
        targetHeight = maxCal;
        targetMode = CalendarViewMode.year;
      } else if (_currentHeight > (_weekHeight + _monthHeight) / 2) {
        targetHeight = _monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = _weekHeight;
        targetMode = CalendarViewMode.week;
      }
    }

    targetHeight = targetHeight.clamp(_weekHeight, maxCal);
    if (targetHeight > _monthHeight + 100) {
      targetMode = CalendarViewMode.year;
    } else if (targetHeight > _weekHeight + 50) {
      targetMode = CalendarViewMode.month;
    } else {
      targetMode = CalendarViewMode.week;
    }

    setState(() {
      _isDragging = false;
      _currentHeight = targetHeight;
      _viewMode = targetMode;
      if (targetMode == CalendarViewMode.week) {
        _calendarFormat = CalendarFormat.week;
      }
      if (targetMode == CalendarViewMode.month) {
        _calendarFormat = CalendarFormat.month;
      }
    });
    if (targetMode == CalendarViewMode.year) {
      _refetchEventsForCalendar(fullYearRange: true);
      _scrollYearViewToCurrentMonth();
    }
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handleDragCancel() {
    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double maxCal = _maxCalendarContentHeight(screenHeight, topPadding);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          const calendarDecoration = BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          );

          final calendarShellHeight = _currentHeight + topPadding;

          final dragHandle = GestureDetector(
            onVerticalDragStart: _handleDragStart,
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            onVerticalDragCancel: _handleDragCancel,
            child: Container(
              height: 24,
              width: double.infinity,
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );

          final calendarColumn = Column(
            children: [
              SizedBox(height: topPadding),
              Expanded(
                child: _viewMode == CalendarViewMode.year
                    ? _buildCalendarContent(viewModel)
                    : OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: _weekHeight,
                        maxHeight: maxCal,
                        child: _buildCalendarContent(viewModel),
                      ),
              ),
              dragHandle,
            ],
          );

          late final Widget bodyColumn;
          if (_viewMode == CalendarViewMode.year) {
            bodyColumn = Column(
              children: [
                Expanded(
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: calendarDecoration,
                    child: calendarColumn,
                  ),
                ),
              ],
            );
          } else {
            final calendarShell = _isDragging
                ? Container(
                    height: calendarShellHeight,
                    decoration: calendarDecoration,
                    child: calendarColumn,
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: calendarShellHeight,
                    decoration: calendarDecoration,
                    child: calendarColumn,
                  );
            bodyColumn = Column(
              children: [
                calendarShell,
                Expanded(child: _buildTaskList(viewModel)),
              ],
            );
          }

          return Stack(
            children: [
              bodyColumn,
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (viewModel.error != null)
                Positioned(
                  top: topPadding + 60,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Connection Error: ${viewModel.error}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            final userId =
                                context.read<AuthViewModel>().currentUser?.id;
                            if (userId != null) {
                              final d = DateTime(
                                _focusedDay.year,
                                _focusedDay.month,
                                _focusedDay.day,
                              );
                              viewModel.fetchAll(
                                userId: userId,
                                eventRangeAnchor: d,
                                mergeEventAnchors: [
                                  d.subtract(const Duration(days: 1)),
                                  d.add(const Duration(days: 1)),
                                ],
                                fullYearRange:
                                    _viewMode == CalendarViewMode.year,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarContent(CalendarViewModel viewModel) {
    if (_viewMode == CalendarViewMode.year) {
      return _buildYearView(viewModel);
    }

    final isWeek = _calendarFormat == CalendarFormat.week;
    final calendarStyle = CalendarStyle(
      selectedDecoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      markerDecoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      cellMargin: isWeek
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      cellPadding: isWeek
          ? const EdgeInsets.symmetric(vertical: 4)
          : EdgeInsets.zero,
      tablePadding: isWeek
          ? const EdgeInsets.fromLTRB(0, 8, 0, 10)
          : const EdgeInsets.symmetric(vertical: 2),
    );
    final headerStyle = HeaderStyle(
      titleCentered: true,
      formatButtonVisible: false,
      titleTextStyle: const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headerPadding: isWeek
          ? const EdgeInsets.symmetric(vertical: 14)
          : const EdgeInsets.symmetric(vertical: 5),
      leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
      rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
    );

    return TableCalendar(
      firstDay: DateTime.utc(2020, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        return viewModel.events
            .where((e) => EventRecurrence.occursOnDay(e, day))
            .toList();
      },
      // Disable scrolling in week view by locking the available gestures
      availableGestures: _calendarFormat == CalendarFormat.week
          ? AvailableGestures.none
          : AvailableGestures.all,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _jumpTimelineToDay(selectedDay, animate: true);
      },

      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        _refetchEventsForCalendar(fullYearRange: false);
      },
      headerStyle: headerStyle,
      calendarStyle: calendarStyle,
      // Custom builder for markers (dots)
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) =>
            _calendarMarkerLayout(events),
      ),
    );
  }

  Widget _buildYearView(CalendarViewModel viewModel) {
    // Rebuilt Year View as an extension of month view (scrolling list of months)
    return Stack(
      children: [
        Column(
          children: [
            // Year Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year - 1,
                          _focusedDay.month,
                        );
                      });
                      _refetchEventsForCalendar(fullYearRange: true);
                      _onYearChangedOnChevron();
                    },
                  ),
                  Text(
                    DateFormat('yyyy').format(_focusedDay),
                    style: const TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year + 1,
                          _focusedDay.month,
                        );
                      });
                      _refetchEventsForCalendar(fullYearRange: true);
                      _onYearChangedOnChevron();
                    },
                  ),
                ],
              ),
            ),
            // Days of week header (Only once at the top)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ), // Match TableCalendar padding
              child: Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: AppColors
                                  .textSecondary, // Or your preferred color
                              fontSize: 13, // Standard TableCalendar size
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Scrollable List of Months
            Expanded(
              child: ListView.builder(
                controller: _yearMonthsScrollController,
                itemCount: 12,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final monthDate = DateTime(_focusedDay.year, index + 1, 1);

                  return Padding(
                    key: _yearMonthItemKeys[index],
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            DateFormat('MMMM').format(monthDate),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                          // Wrap TableCalendar in SizedBox to constrain height if needed or ensure it fits
                          child: TableCalendar(
                            firstDay: DateTime(
                              monthDate.year,
                              monthDate.month,
                              1,
                            ),
                            lastDay: DateTime(
                              monthDate.year,
                              monthDate.month + 1,
                              0,
                            ),
                            focusedDay: monthDate,
                            calendarFormat: CalendarFormat.month,
                            eventLoader: (day) {
                              return viewModel.events
                                  .where((e) =>
                                      EventRecurrence.occursOnDay(e, day))
                                  .toList();
                            },
                            headerVisible: false,
                            daysOfWeekVisible:
                                false, // Hide repetitive days of week
                            pageJumpingEnabled: false,
                            availableGestures: AvailableGestures
                                .none, // Disable swiping in this view
                            calendarStyle: CalendarStyle(
                              selectedDecoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                              outsideDaysVisible: false,
                            ),
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _viewMode = CalendarViewMode.month;
                                _calendarFormat = CalendarFormat.month;
                                final maxCal = _maxCalendarContentHeight(
                                  MediaQuery.sizeOf(context).height,
                                  MediaQuery.paddingOf(context).top,
                                );
                                _currentHeight = math.min(_monthHeight, maxCal);
                              });
                              _jumpTimelineToDay(selectedDay, animate: true);
                            },
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) =>
                                  _calendarMarkerLayout(events),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Floating Back Button - Top Left
        Positioned(
          top: 16,
          left: 16,
          child: Material(
            color: Colors.white,
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _viewMode = CalendarViewMode.month;
                  _calendarFormat = CalendarFormat.month;
                  final maxCal = _maxCalendarContentHeight(
                    MediaQuery.sizeOf(context).height,
                    MediaQuery.paddingOf(context).top,
                  );
                  _currentHeight = math.min(_monthHeight, maxCal);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(CalendarViewModel viewModel) {
    return Container(
      color: AppColors.grey50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const desiredNavClearance = 100.0;
          final bottomInset = math.min(
            desiredNavClearance,
            math.max(16.0, constraints.maxHeight * 0.22),
          );

          final dayCount = _timelineDayCount();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ongoing',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_selectedDay != null)
                      Text(
                        DateFormat('EEE, MMM d').format(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: _timetableScrollController,
                  padding: EdgeInsets.only(bottom: bottomInset),
                  itemExtent: _kDayRowExtent,
                  cacheExtent: 2 * _kDayRowExtent,
                  itemCount: dayCount,
                  itemBuilder: (context, index) {
                    final day = _dateForDayIndex(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TimelineDayRow(
                        day: day,
                        events: viewModel.events,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineDayRow extends StatelessWidget {
  const _TimelineDayRow({
    required this.day,
    required this.events,
  });

  final DateTime day;
  final List<EventModel> events;

  @override
  Widget build(BuildContext context) {
    const double leftMargin = 60.0;
    final dayMidnight = DateTime(day.year, day.month, day.day);
    final segments = _segmentsForCalendarDay(events, dayMidnight);
    final intervals = segments
        .map((s) => (start: s.start, end: s.end))
        .toList(growable: false);
    final laneLayouts = layoutTimetableSegmentsForDay(intervals);
    final now = DateTime.now();
    final showNowLine = isSameDay(dayMidnight, now);

    return SizedBox(
      height: _kDayRowExtent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usableWidth = math.max(0.0, constraints.maxWidth - leftMargin);

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (int i = 0; i < 24; i++)
                Positioned(
                  top: i * _kTimetableHourHeight,
                  left: 0,
                  right: 0,
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${i.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomPaint(
                          painter: DottedLinePainter(),
                          size: const Size(double.infinity, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ...List.generate(segments.length, (i) {
                final seg = segments[i];
                final lay = laneLayouts[i];
                final gapTotal =
                    _kTimetableLaneGap * (lay.columnCount - 1);
                final slotWidth =
                    (usableWidth - gapTotal) / lay.columnCount;
                final leftPx = leftMargin +
                    lay.column * (slotWidth + _kTimetableLaneGap);
                final topPx =
                    (seg.start.difference(dayMidnight).inMinutes / 60.0) *
                            _kTimetableHourHeight +
                        10;
                final heightPx = math.max(
                  4.0,
                  (seg.end.difference(seg.start).inMinutes / 60.0) *
                          _kTimetableHourHeight -
                      20,
                );
                return Positioned(
                  top: topPx,
                  left: leftPx,
                  width: math.max(0.0, slotWidth),
                  height: heightPx,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventDetailPage(event: seg.event),
                        ),
                      );
                    },
                    child: _calendarTaskCard(
                      seg.event.title,
                      seg.event.location,
                      '${DateFormat('HH:mm').format(seg.start)} - ${DateFormat('HH:mm').format(seg.end)}',
                      accentForEventDisplay(
                        title: seg.event.title,
                        hashtags: seg.event.hashtags,
                      ),
                    ),
                  ),
                );
              }),
              if (showNowLine)
                Positioned(
                  top: (now.hour + now.minute / 60.0) * _kTimetableHourHeight,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          DateFormat('HH:mm').format(now),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Colors.redAccent,
                          thickness: 2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

enum CalendarViewMode { week, month, year }

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
