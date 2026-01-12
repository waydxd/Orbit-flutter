import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/themes/app_colors.dart';
import '../widgets/floating_nav_bar.dart';
import '../../tasks/view/task_list_page.dart';
import '../../tasks/view/create_item_page.dart';
import '../../ai_chat/view/ai_chat_page.dart';
import '../view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';

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
  double _currentHeight = 140.0; // Start with Week view height
  final double _weekHeight = 140.0;
  final double _monthHeight = 420.0;
  // Height will be calculated dynamically

  // View Mode
  CalendarViewMode _viewMode = CalendarViewMode.week;

  // PageView Controller for Timetable
  late PageController _pageController;
  final int _initialPage = 10000;
  late DateTime _referenceDate;

  static const double _hourHeight = 80.0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    final now = DateTime.now();
    _referenceDate = DateTime(now.year, now.month, now.day);
    _pageController = PageController(initialPage: _initialPage);

    // Fetch data from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final userId = authViewModel.currentUser?.id;
      if (userId != null) {
        context.read<CalendarViewModel>().fetchAll(userId: userId);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    // Use screenHeight - topPadding as the max height to avoid overflow within SafeArea
    final double yearHeight = screenHeight - topPadding;

    setState(() {
      _currentHeight += details.delta.dy;
      // Clamp height
      if (_currentHeight < _weekHeight) _currentHeight = _weekHeight;
      if (_currentHeight > yearHeight) _currentHeight = yearHeight;

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
  }

  void _handleDragEnd(DragEndDetails details) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double yearHeight = screenHeight - topPadding;

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
        targetHeight = yearHeight;
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
      if (_currentHeight > (_monthHeight + yearHeight) / 2) {
        targetHeight = yearHeight;
        targetMode = CalendarViewMode.year;
      } else if (_currentHeight > (_weekHeight + _monthHeight) / 2) {
        targetHeight = _monthHeight;
        targetMode = CalendarViewMode.month;
      } else {
        targetHeight = _weekHeight;
        targetMode = CalendarViewMode.week;
      }
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
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double yearHeight = screenHeight - topPadding;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Column(
                children: [
                  // Animated Calendar Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _currentHeight + topPadding,
                    decoration: const BoxDecoration(
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
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topPadding), // Safe Area padding
                        // Calendar Content
                        Expanded(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: _weekHeight,
                            maxHeight: yearHeight,
                            child: _buildCalendarContent(viewModel),
                          ),
                        ),
                        // Drag Handle
                        GestureDetector(
                          onVerticalDragUpdate: _handleDragUpdate,
                          onVerticalDragEnd: _handleDragEnd,
                          child: Container(
                            height: 24,
                            width: double.infinity,
                            color: Colors.transparent, // Hit test area
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

                  // Task List (Occupies remaining space)
                  Expanded(child: _buildTaskList(viewModel)),
                ],
              ),

              // Floating Navigation Bar
              FloatingNavBar(
                currentIndex: 0,
                onCalendarTap: () {
                  // Already on calendar page
                  debugPrint('Calendar tapped');
                },
                onCreateTaskTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateItemPage(),
                    ),
                  );
                  debugPrint('Create task tapped');
                },
                onCreateTaskLongPress: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiChatPage()),
                  );
                  debugPrint('AI Chat long press');
                },
                onTodoListTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListPage(),
                    ),
                  );
                  debugPrint('Todo list tapped');
                },
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
                            final userId = context
                                .read<AuthViewModel>()
                                .currentUser
                                ?.id;
                            if (userId != null) {
                              viewModel.fetchAll(userId: userId);
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

    return TableCalendar(
      firstDay: DateTime.utc(2020, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        return viewModel.events
            .where((e) => isSameDay(e.startTime, day))
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

        // Sync PageView
        final difference = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        ).difference(_referenceDate).inDays;
        _pageController.animateToPage(
          _initialPage + difference,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      // Styling to match the aesthetic
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
      ),
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
      ),
      // Custom builder for markers (dots)
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;
          return Positioned(
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: events
                  .map(
                    (_) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
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
                itemCount: 12,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final monthDate = DateTime(_focusedDay.year, index + 1, 1);

                  return Padding(
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
                                  .where((e) => isSameDay(e.startTime, day))
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
                                // Transition back to month view for the selected month
                                _viewMode = CalendarViewMode.month;
                                _calendarFormat = CalendarFormat.month;
                                _currentHeight = _monthHeight;
                              });
                            },
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
                  // Return to Month View
                  _viewMode = CalendarViewMode.month;
                  _calendarFormat = CalendarFormat.month;
                  _currentHeight = _monthHeight;
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
      child: Column(
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
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                final newDate = _referenceDate.add(
                  Duration(days: index - _initialPage),
                );
                setState(() {
                  _selectedDay = newDate;
                  _focusedDay = newDate;
                });
              },
              itemBuilder: (context, index) {
                final date = _referenceDate.add(
                  Duration(days: index - _initialPage),
                );
                return _buildDayTimetable(viewModel, date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTimetable(CalendarViewModel viewModel, DateTime date) {
    // Filter events for this specific date
    final dayEvents = viewModel.events
        .where((e) => isSameDay(e.startTime, date))
        .toList();

    // Sort events by start time
    dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    const int startHour = 0;
    const int endHour = 23;
    const double leftMargin = 60.0;

    final now = DateTime.now();
    final bool isToday = isSameDay(date, now);

    return SingleChildScrollView(
      controller: ScrollController(
        initialScrollOffset: _getInitialScrollOffset(),
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: (endHour - startHour + 1) * _hourHeight,
          child: Stack(
            children: [
              // Grid Lines & Times
              for (int i = 0; i <= endHour - startHour; i++)
                Positioned(
                  top: i * _hourHeight,
                  left: 0,
                  right: 0,
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          _formatHour(startHour + i),
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

              // Task Cards (from backend events)
              ...dayEvents.map((event) {
                final double startH =
                    event.startTime.hour + (event.startTime.minute / 60.0);
                final double endH =
                    event.endTime.hour + (event.endTime.minute / 60.0);
                final double duration = endH - startH;

                return Positioned(
                  top: (startH - startHour) * _hourHeight + 10,
                  left: leftMargin,
                  right: 0,
                  height: duration * _hourHeight - 20,
                  child: _buildTaskCard(
                    event.title,
                    event.location,
                    '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                    _getEventColor(event.title),
                  ),
                );
              }),

              // Current Time Line (Rendered last to be on top)
              if (isToday)
                Positioned(
                  top: (now.hour + now.minute / 60.0) * _hourHeight,
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
                        child: Divider(color: Colors.redAccent, thickness: 2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventColor(String title) {
    // Map titles to colors for visual consistency
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('math')) return const Color(0xFF50C8AA);
    if (lowerTitle.contains('english')) return const Color(0xFF8B80F0);
    if (lowerTitle.contains('history')) return const Color(0xFF0096FF);
    return AppColors.primary;
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  // Helper to get initial scroll offset for all days
  double _getInitialScrollOffset() {
    final now = DateTime.now();
    return (now.hour + now.minute / 60.0) * _hourHeight;
  }

  Widget _buildTaskCard(
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
