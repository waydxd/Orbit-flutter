import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/hashtag_palette.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/habit_suggestion.dart';
import '../../../data/utils/event_recurrence.dart';
import '../timetable_overlap_layout.dart';
import '../widgets/habit_suggestion_timetable_card.dart';
import '../view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import 'event_detail_page.dart';

const double _kTimetableHourHeight = 80.0;
const double _kTimetableLaneGap = 2.0;

/// Pushes timeline blocks down so they line up with the hour-label row (see
/// [HabitSuggestion] cards, which use the same offset).
const double _kTimelineVerticalOffset = 10.0;
const double _kNowLineCenterOffset = 8.0;

double _timelineYForHourFraction(double hourFraction) =>
    hourFraction * _kTimetableHourHeight + _kTimelineVerticalOffset;

/// One calendar day row height in the infinite vertical timeline.
const double _kDayRowExtent = 24 * _kTimetableHourHeight;

/// Inclusive start of the scrollable timeline (local midnight).
final DateTime _kTimelineStart = DateTime(2010, 1, 1);

/// Exclusive end: last renderable day is the day before this.
final DateTime _kTimelineEndExclusive = DateTime(2041, 1, 1);

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
            time,
            style: TextStyle(
              color: onAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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

  // Drag & Layout State (aligned with legacy calendar shell)
  /// Week mode: calendar shell (`_currentHeight` + safe padding) occupies this fraction of
  /// screen height from the top; i.e. `_currentHeight ≈ screenHeight * fraction - topPadding`.
  static const double _kWeekViewScreenFraction = 0.25;

  /// Snap / min height for week view (updated from [MediaQuery] in [didChangeDependencies]).
  double _weekHeight = 200.0;
  double _currentHeight = 200.0;
  static const double _kMonthHeightForFourRows = 300.0;
  static const double _kMonthHeightForFiveRows = 350.0;
  static const double _kMonthHeightForSixRows = 400.0;

  /// Minimum height for the Ongoing timeline panel (scales with screen so it is not a hard 220px).
  static const double _kMinOngoingHeightFloor = 152.0;
  static const double _kMinOngoingHeightScreenFraction = 0.26;

  /// Minimum height reserved for Ongoing when the calendar is in week or month mode.
  double _minOngoingPanelHeight(double screenHeight) => math.max(
      _kMinOngoingHeightFloor, screenHeight * _kMinOngoingHeightScreenFraction);

  int _weekRowCountForMonth(DateTime monthDay) {
    final firstDayOfMonth = DateTime(monthDay.year, monthDay.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(monthDay.year, monthDay.month);
    final leadingOffset = firstDayOfMonth.weekday % 7; // Sunday-start grid
    return ((leadingOffset + daysInMonth) / 7).ceil();
  }

  double _monthHeightForFocusedDay() {
    final rowCount = _weekRowCountForMonth(_focusedDay);
    switch (rowCount) {
      case 4:
        return _kMonthHeightForFourRows;
      case 6:
        return _kMonthHeightForSixRows;
      case 5:
      default:
        return _kMonthHeightForFiveRows;
    }
  }

  /// Max calendar strip height (`_currentHeight`) while week/month so Ongoing keeps at least [_minOngoingPanelHeight].
  double _maxCalendarStripHeightNonYear(
    double screenHeight,
    double topPadding,
  ) {
    final yearH = screenHeight - topPadding;
    final cap =
        screenHeight - topPadding - _minOngoingPanelHeight(screenHeight);
    return cap.clamp(_weekHeight, yearH);
  }

  // View Mode
  CalendarViewMode _viewMode = CalendarViewMode.week;

  /// Vertical infinite day timeline (replaces PageView).
  late final ScrollController _timetableScrollController;
  Timer? _timetableFetchDebounce;
  bool _timetableInitialScrollApplied = false;
  bool _timelineApplyScheduled = false;

  /// Year list: recreated when entering year so the list starts near [focusedDay]'s month.
  ScrollController _yearScrollController = ScrollController();
  final List<GlobalKey> _yearMonthItemKeys =
      List<GlobalKey>.generate(12, (_) => GlobalKey());
  bool _isYearScrollScheduled = false;

  /// Approximate height of one month block in the year list (for initial scroll offset).
  static const double _approxMonthHeight = 324.0;

  /// Second tap on the same date in year grid exits to week view (legacy behavior).
  DateTime? _yearViewLastTapDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedDay == null) return;
      context.read<CalendarViewModel>().setSelectedCalendarDay(_selectedDay!);
    });
    _timetableScrollController = ScrollController();
    _timetableScrollController.addListener(_onTimelineScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _applyInitialTimelineScrollIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenH = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final weekH = (screenH * _kWeekViewScreenFraction - topPadding)
        .clamp(80.0, screenH * 0.9);
    final sizeChanged = (_weekHeight - weekH).abs() > 0.5;
    _weekHeight = weekH;
    if (_viewMode == CalendarViewMode.week && sizeChanged) {
      setState(() {
        _currentHeight = weekH;
      });
    } else if (sizeChanged) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timetableFetchDebounce?.cancel();
    _timetableScrollController.removeListener(_onTimelineScroll);
    _timetableScrollController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  void _resetYearScrollControllerForMonth(
    int monthIndex, {
    bool keepScrollOffset = true,
  }) {
    _yearScrollController.dispose();
    final initialOffset =
        (monthIndex * _approxMonthHeight).clamp(0.0, 11.0 * _approxMonthHeight);
    _yearScrollController = ScrollController(
      initialScrollOffset: initialOffset,
      keepScrollOffset: keepScrollOffset,
    );
  }

  void _resetYearScrollControllerForYear({
    required int year,
    required int month,
  }) {
    final nowYear = DateTime.now().year;
    final monthIndex = year == nowYear ? (month - 1).clamp(0, 11) : 0;
    _resetYearScrollControllerForMonth(monthIndex);
  }

  void _resetYearScrollControllerForFocusedYear() {
    _resetYearScrollControllerForYear(
      year: _focusedDay.year,
      month: _focusedDay.month,
    );
  }

  void _scheduleYearViewScrollToFocusedMonth() {
    final nowYear = DateTime.now().year;
    if (_focusedDay.year != nowYear) return;
    if (_isYearScrollScheduled) return;
    _isYearScrollScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isYearScrollScheduled = false;
      final monthIndex = (_focusedDay.month - 1).clamp(0, 11);
      final monthContext = _yearMonthItemKeys[monthIndex].currentContext;
      if (monthContext == null) return;
      Scrollable.ensureVisible(
        monthContext,
        duration: Duration.zero,
        alignment: 0.0,
      );
    });
  }

  void _onYearChangedOnChevron() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_viewMode != CalendarViewMode.year) return;
      if (_yearScrollController.hasClients) {
        _yearScrollController.jumpTo(0);
      }
    });
  }

  void _handleYearViewDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final lastDay = _yearViewLastTapDay;
    final isSecondTapOnSameDate =
        lastDay != null && isSameDay(lastDay, selectedDay);

    if (isSecondTapOnSameDate) {
      _yearViewLastTapDay = null;
      final normalized = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      setState(() {
        _selectedDay = normalized;
        _focusedDay = focusedDay;
        _viewMode = CalendarViewMode.week;
        _calendarFormat = CalendarFormat.week;
        _currentHeight = _weekHeight;
      });
      context.read<CalendarViewModel>().setSelectedCalendarDay(normalized);
      _timetableInitialScrollApplied = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpTimelineToDay(normalized, animate: false);
        _refetchEventsForCalendar(fullYearRange: false);
      });
      return;
    }

    _yearViewLastTapDay =
        DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    context.read<CalendarViewModel>().setSelectedCalendarDay(selectedDay);
  }

  void _maybeInvalidateTimelineScrollFlag(
      double screenHeight, double topPadding) {
    final remaining = screenHeight - (_currentHeight + topPadding);
    if (_viewMode != CalendarViewMode.year &&
        remaining < _minOngoingPanelHeight(screenHeight)) {
      _timetableInitialScrollApplied = false;
    }
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
    context.read<CalendarViewModel>().setSelectedCalendarDay(visibleDay);
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
      final mergeEventAnchors = <DateTime>[
        d.subtract(const Duration(days: 1)),
        d.add(const Duration(days: 1)),
      ];
      final selected = _selectedDay;
      if (selected != null) {
        final s = DateTime(selected.year, selected.month, selected.day);
        if (!isSameDay(s, d)) {
          mergeEventAnchors.add(s);
        }
      }
      context.read<CalendarViewModel>().fetchAll(
            userId: userId,
            eventRangeAnchor: d,
            mergeEventAnchors: mergeEventAnchors,
            fullYearRange: fullYearRange,
            showLoading: false,
          );
    });
  }

  double _maxCalendarContentHeight(double screenHeight, double topPadding) {
    return math.max(
      _weekHeight,
      screenHeight - topPadding - _minOngoingPanelHeight(screenHeight),
    );
  }

  double _clampStripHeightForMode(
    double height,
    CalendarViewMode mode,
    double screenHeight,
    double topPadding,
  ) {
    final yearH = screenHeight - topPadding;
    if (mode == CalendarViewMode.year) {
      return height.clamp(_weekHeight, yearH);
    }
    return height.clamp(
      _weekHeight,
      _maxCalendarStripHeightNonYear(screenHeight, topPadding),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final previousMode = _viewMode;
    final monthHeight = _monthHeightForFocusedDay();

    final double raw = _currentHeight + details.delta.dy;

    CalendarViewMode newMode;
    if (raw > monthHeight + 100) {
      newMode = CalendarViewMode.year;
    } else if (raw > _weekHeight + 50) {
      newMode = CalendarViewMode.month;
    } else {
      newMode = CalendarViewMode.week;
    }

    final double newHeight =
        _clampStripHeightForMode(raw, newMode, screenHeight, topPadding);

    if (previousMode != CalendarViewMode.year &&
        newMode == CalendarViewMode.year) {
      _resetYearScrollControllerForFocusedYear();
    }

    setState(() {
      _currentHeight = newHeight;
      _viewMode = newMode;
      if (newMode == CalendarViewMode.month) {
        _calendarFormat = CalendarFormat.month;
      } else if (newMode == CalendarViewMode.week) {
        _calendarFormat = CalendarFormat.week;
      }
    });

    _maybeInvalidateTimelineScrollFlag(screenHeight, topPadding);

    if (previousMode != CalendarViewMode.year &&
        newMode == CalendarViewMode.year) {
      _refetchEventsForCalendar(fullYearRange: true);
      _scheduleYearViewScrollToFocusedMonth();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double yearHeight = screenHeight - topPadding;
    final monthHeight = _monthHeightForFocusedDay();

    double targetHeight;
    CalendarViewMode targetMode;

    final double velocity = details.velocity.pixelsPerSecond.dy;

    if (velocity > 500) {
      if (_currentHeight < monthHeight) {
        targetHeight = monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = yearHeight;
        targetMode = CalendarViewMode.year;
      }
    } else if (velocity < -500) {
      if (_currentHeight > monthHeight) {
        targetHeight = monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = _weekHeight;
        targetMode = CalendarViewMode.week;
      }
    } else {
      if (_currentHeight > (monthHeight + yearHeight) / 2) {
        targetHeight = yearHeight;
        targetMode = CalendarViewMode.year;
      } else if (_currentHeight > (_weekHeight + monthHeight) / 2) {
        targetHeight = monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = _weekHeight;
        targetMode = CalendarViewMode.week;
      }
    }

    targetHeight = _clampStripHeightForMode(
        targetHeight, targetMode, screenHeight, topPadding);

    final bool isTransitioningToYear = _viewMode != CalendarViewMode.year &&
        targetMode == CalendarViewMode.year;

    if (isTransitioningToYear) {
      _resetYearScrollControllerForFocusedYear();
    }

    setState(() {
      _currentHeight = targetHeight;
      _viewMode = targetMode;
      if (targetMode == CalendarViewMode.week) {
        _calendarFormat = CalendarFormat.week;
      }
      if (targetMode == CalendarViewMode.month) {
        _calendarFormat = CalendarFormat.month;
      }
    });

    _maybeInvalidateTimelineScrollFlag(screenHeight, topPadding);

    if (isTransitioningToYear) {
      _refetchEventsForCalendar(fullYearRange: true);
      _scheduleYearViewScrollToFocusedMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double yearHeight = screenHeight - topPadding;
    final double calendarOccupiedHeight = _currentHeight + topPadding;
    final double remainingHeight = screenHeight - calendarOccupiedHeight;
    final double minOngoing = _minOngoingPanelHeight(screenHeight);
    final bool shouldShowTaskList =
        _viewMode != CalendarViewMode.year && remainingHeight >= minOngoing;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _currentHeight + topPadding,
                    decoration: const BoxDecoration(
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
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: topPadding),
                            Expanded(
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: _weekHeight,
                                maxHeight: yearHeight,
                                child: _buildCalendarContent(viewModel),
                              ),
                            ),
                            GestureDetector(
                              onVerticalDragUpdate: _handleDragUpdate,
                              onVerticalDragEnd: _handleDragEnd,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (shouldShowTaskList)
                    Expanded(child: _buildTaskList(viewModel)),
                ],
              ),
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
      defaultTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      weekendTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      outsideTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      todayTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      selectedTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
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
      cellPadding:
          isWeek ? const EdgeInsets.symmetric(vertical: 4) : EdgeInsets.zero,
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
      rightChevronIcon:
          const Icon(Icons.chevron_right, color: AppColors.primary),
    );

    return TableCalendar(
      key: ValueKey(
        'wm-${_calendarFormat.name}-${_focusedDay.year}-${_focusedDay.month}',
      ),
      firstDay: DateTime.utc(2010, 1, 1),
      lastDay: DateTime.utc(2040, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        return viewModel.events
            .where((e) => EventRecurrence.occursOnDay(e, day))
            .toList();
      },
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        context.read<CalendarViewModel>().setSelectedCalendarDay(selectedDay);
        _jumpTimelineToDay(selectedDay, animate: false);
      },
      onFormatChanged: (format) {
        if (format == CalendarFormat.twoWeeks) return;
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          if (_viewMode == CalendarViewMode.month) {
            _currentHeight = _clampStripHeightForMode(
              _monthHeightForFocusedDay(),
              CalendarViewMode.month,
              MediaQuery.sizeOf(context).height,
              MediaQuery.paddingOf(context).top,
            );
          }
        });
        _refetchEventsForCalendar(fullYearRange: false);
      },
      headerStyle: headerStyle,
      calendarStyle: calendarStyle,
      calendarBuilders: CalendarBuilders(
        selectedBuilder: (context, day, focusedDay) {
          const selectedColor = AppColors.primary;
          return Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: selectedColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          final isSelected = isSameDay(_selectedDay, day);
          return Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFF5B91F0).withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        },
        markerBuilder: (context, date, events) => _calendarMarkerLayout(events),
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
                      final targetYear = _focusedDay.year - 1;
                      final targetMonth = _focusedDay.month;
                      _resetYearScrollControllerForMonth(
                        0,
                        keepScrollOffset: false,
                      );
                      setState(() {
                        _focusedDay = DateTime(
                          targetYear,
                          targetMonth,
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
                      final targetYear = _focusedDay.year + 1;
                      final targetMonth = _focusedDay.month;
                      _resetYearScrollControllerForMonth(
                        0,
                        keepScrollOffset: false,
                      );
                      setState(() {
                        _focusedDay = DateTime(
                          targetYear,
                          targetMonth,
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
                key: ValueKey('yv-list-${_focusedDay.year}'),
                controller: _yearScrollController,
                itemCount: 12,
                padding: const EdgeInsets.only(bottom: 120),
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
                          child: TableCalendar(
                            key: ValueKey(
                              'yv-${_focusedDay.year}-${monthDate.month}',
                            ),
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
                            daysOfWeekVisible: false,
                            pageJumpingEnabled: false,
                            availableGestures: AvailableGestures.none,
                            calendarStyle: CalendarStyle(
                              defaultTextStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              weekendTextStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              outsideTextStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              todayTextStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              selectedTextStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
                            onDaySelected: _handleYearViewDaySelected,
                            calendarBuilders: CalendarBuilders(
                              selectedBuilder: (context, day, focusedDay) {
                                const selectedColor = AppColors.primary;
                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: selectedColor,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              todayBuilder: (context, day, focusedDay) {
                                final isSelected = isSameDay(_selectedDay, day);
                                return Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFF5B91F0)
                                            .withValues(alpha: 0.75),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
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
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF6366F1),
              size: 32,
            ),
            onPressed: () {
              setState(() {
                _viewMode = CalendarViewMode.month;
                _calendarFormat = CalendarFormat.month;
                _currentHeight = math.min(
                  _monthHeightForFocusedDay(),
                  _maxCalendarContentHeight(
                    MediaQuery.sizeOf(context).height,
                    MediaQuery.paddingOf(context).top,
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleAcceptHabitSuggestion(
    CalendarViewModel viewModel,
    String suggestionId,
    int years,
    int weeks,
  ) async {
    final userId = context.read<AuthViewModel>().currentUser?.id;
    final response = await viewModel.acceptHabitSuggestion(
      suggestionId,
      userId: userId,
      years: years,
      weeks: weeks,
    );
    if (!mounted) return;
    if (response != null && response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDismissHabitSuggestion(
    CalendarViewModel viewModel,
    String suggestionId,
  ) async {
    final success = await viewModel.dismissHabitSuggestion(suggestionId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suggestion dismissed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTaskList(CalendarViewModel viewModel) {
    return Container(
      color: AppColors.grey50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minOngoingH =
              _minOngoingPanelHeight(MediaQuery.sizeOf(context).height);
          if (constraints.maxHeight < minOngoingH) {
            return const SizedBox.shrink();
          }

          if (!_timetableInitialScrollApplied && !_timelineApplyScheduled) {
            _timelineApplyScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _timelineApplyScheduled = false;
              if (!mounted) return;
              _applyInitialTimelineScrollIfNeeded();
            });
          }

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
                        habitSuggestions: viewModel.suggestionsForDay(day),
                        onAcceptHabitSuggestion: (id, years, weeks) =>
                            _handleAcceptHabitSuggestion(
                                viewModel, id, years, weeks),
                        onDismissHabitSuggestion: (id) =>
                            _handleDismissHabitSuggestion(viewModel, id),
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
    required this.habitSuggestions,
    required this.onAcceptHabitSuggestion,
    required this.onDismissHabitSuggestion,
  });

  final DateTime day;
  final List<EventModel> events;
  final List<HabitSuggestion> habitSuggestions;
  final void Function(String suggestionId, int years, int weeks)
      onAcceptHabitSuggestion;
  final void Function(String suggestionId) onDismissHabitSuggestion;

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
    final nowLabel = DateFormat('HH:mm').format(now);
    final nowLineY = _timelineYForHourFraction(now.hour + now.minute / 60.0);

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
                        child: Builder(
                          builder: (context) {
                            final hourLabel =
                                '${i.toString().padLeft(2, '0')}:00';
                            final hourTop = i * _kTimetableHourHeight;
                            final hideHourLabel = showNowLine &&
                                (nowLineY - hourTop).abs() < 16.0;
                            if (hideHourLabel) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              hourLabel,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
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
                final gapTotal = _kTimetableLaneGap * (lay.columnCount - 1);
                final slotWidth = (usableWidth - gapTotal) / lay.columnCount;
                final leftPx =
                    leftMargin + lay.column * (slotWidth + _kTimetableLaneGap);
                // Full hour scale (80px/hour): height matches start→end duration.
                final startMin = seg.start.difference(dayMidnight).inMinutes;
                final endMin = seg.end.difference(dayMidnight).inMinutes;
                final topPx = _timelineYForHourFraction(startMin / 60.0);
                final heightPx = math.max(
                  4.0,
                  ((endMin - startMin) / 60.0) * _kTimetableHourHeight,
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
              ...habitSuggestions.map((suggestion) {
                final startH = suggestion.startHour;
                final duration = suggestion.endHour - startH;
                final cardHeight =
                    (duration > 0 ? duration : 0.5) * _kTimetableHourHeight -
                        20;
                return Positioned(
                  top: _timelineYForHourFraction(startH),
                  left: leftMargin,
                  right: 0,
                  height: cardHeight.clamp(120.0, double.infinity),
                  child: HabitSuggestionTimetableCard(
                    suggestion: suggestion,
                    onAccept: (years, weeks) => onAcceptHabitSuggestion(
                      suggestion.id,
                      years,
                      weeks,
                    ),
                    onDismiss: () => onDismissHabitSuggestion(suggestion.id),
                  ),
                );
              }),
              if (showNowLine)
                Positioned(
                  // The indicator line is vertically centered in this row.
                  top: nowLineY - _kNowLineCenterOffset,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          nowLabel,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
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
                      Container(
                        width: 6,
                        height: 2,
                        color: Colors.redAccent,
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
