import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../habit_tracking/widgets/habit_suggestions_badge.dart';
import '../../data/models/habit_suggestion.dart';
import '../../data/services/habit_tracking_service.dart';
import '../../utils/constants.dart';
import '../../utils/habit_tracking_helper.dart';

/// Simple event model for demo purposes
class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? location;
  final String? description;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location,
    this.description,
  });

  String get formattedTime {
    String formatTime(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  DateTime get startDateTime => DateTime(
    date.year, date.month, date.day, startTime.hour, startTime.minute,
  );

  DateTime get endDateTime => DateTime(
    date.year, date.month, date.day, endTime.hour, endTime.minute,
  );
}

/// Main home screen with calendar and habit tracking integration
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Demo user ID - in a real app, this would come from authentication
  static const String _userId = 'demo_user_123';

  // Habit tracking helper and service
  late final HabitTrackingHelper _habitTrackingHelper;
  late final HabitTrackingService _habitTrackingService;

  // Store events by date
  final Map<DateTime, List<CalendarEvent>> _events = {};

  // Store habit suggestions
  List<HabitSuggestion> _habitSuggestions = [];

  @override
  void initState() {
    super.initState();
    _habitTrackingService = HabitTrackingService();
    _habitTrackingHelper = HabitTrackingHelper(_habitTrackingService);
    _selectedDay = DateTime.now();
    _addSampleEvents();
    _loadHabitSuggestions();
  }

  Future<void> _loadHabitSuggestions() async {
    try {
      final suggestions = await _habitTrackingService.getSuggestions(_userId);
      setState(() {
        _habitSuggestions = suggestions;
      });
    } catch (e) {
      print('Error loading habit suggestions: $e');
    }
  }

  /// Get habit suggestions that match the selected day's weekday
  List<HabitSuggestion> _getSuggestionsForDay(DateTime day) {
    final dayOfWeek = day.weekday % 7; // Convert to 0-6 (Sun-Sat)
    return _habitSuggestions.where((s) => s.dayOfWeek == dayOfWeek).toList();
  }

  void _addSampleEvents() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    _events[normalizedToday] = [
      CalendarEvent(
        id: '1',
        title: 'Team Meeting',
        date: normalizedToday,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        location: 'Conference Room A',
      ),
      CalendarEvent(
        id: '2',
        title: 'Lunch Break',
        date: normalizedToday,
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        location: 'Cafeteria',
      ),
    ];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  void _addEvent(CalendarEvent event) {
    final normalizedDate = _normalizeDate(event.date);
    setState(() {
      if (_events[normalizedDate] == null) {
        _events[normalizedDate] = [];
      }
      _events[normalizedDate]!.add(event);
    });

    // Record for habit tracking
    _habitTrackingHelper.recordEventForHabitTracking(
      userId: _userId,
      title: event.title,
      description: event.description,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      location: event.location,
    ).then((_) {
      // Reload suggestions after recording event
      _loadHabitSuggestions();
    });
  }

  void _deleteEvent(CalendarEvent event) {
    final normalizedDate = _normalizeDate(event.date);
    setState(() {
      _events[normalizedDate]?.removeWhere((e) => e.id == event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orbit Calendar'),
        actions: [
          // Habit suggestions button with badge
          HabitSuggestionsIconButton(userId: _userId),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar widget
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(Constants.radiusM),
              ),
            ),
          ),
          const Divider(),
          // Events list for selected day
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedDay == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: Constants.spacingM),
            Text(
              'Select a day to view events',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final events = _getEventsForDay(_selectedDay!);
    final suggestions = _getSuggestionsForDay(_selectedDay!);

    return ListView(
      padding: const EdgeInsets.all(Constants.spacingM),
      children: [
        _buildInfoCard(),
        const SizedBox(height: Constants.spacingM),
        Text(
          'Events for ${_formatDate(_selectedDay!)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Constants.spacingS),
        // Show habit suggestions first (pending events)
        if (suggestions.isNotEmpty) ...[
          ...suggestions.map((suggestion) => _buildPendingHabitCard(suggestion)),
        ],
        // Show regular events
        if (events.isEmpty && suggestions.isEmpty)
          _buildEmptyState()
        else
          ...events.map((event) => _buildEventCard(event)),
      ],
    );
  }

  /// Build a card for a pending habit suggestion
  Widget _buildPendingHabitCard(HabitSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: Constants.spacingS),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.radiusM),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Constants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with lightbulb icon
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber[700],
                  size: 20,
                ),
                const SizedBox(width: Constants.spacingS),
                Text(
                  'Suggested Recurring Event',
                  style: TextStyle(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Constants.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(Constants.radiusS),
                  ),
                  child: Text(
                    '${suggestion.frequency}x detected',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Constants.spacingS),
            // Event details
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Constants.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${suggestion.startTime} - ${suggestion.endTime}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (suggestion.location != null && suggestion.location!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              suggestion.location!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Constants.spacingM),
            // Description text
            Text(
              'Add this as a recurring event for the next 5 years?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: Constants.spacingS),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismissSuggestion(suggestion),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: Constants.spacingS),
                ElevatedButton.icon(
                  onPressed: () => _acceptSuggestion(suggestion),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Constants.spacingM,
                      vertical: Constants.spacingS,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptSuggestion(HabitSuggestion suggestion) async {
    try {
      // Mark suggestion as accepted in the service
      final response = await _habitTrackingService.acceptSuggestion(
        userId: _userId,
        habitId: suggestion.habitId,
      );

      // Create recurring events for the next 5 years
      final eventsCreated = _createRecurringEvents(suggestion);

      // Reload suggestions
      await _loadHabitSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created $eventsCreated recurring events for 5 years!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Create recurring events for 5 years based on the habit suggestion
  int _createRecurringEvents(HabitSuggestion suggestion) {
    // Parse start and end times
    final startTimeParts = suggestion.startTime.split(':');
    final endTimeParts = suggestion.endTime.split(':');
    final startTime = TimeOfDay(
      hour: int.parse(startTimeParts[0]),
      minute: int.parse(startTimeParts[1]),
    );
    final endTime = TimeOfDay(
      hour: int.parse(endTimeParts[0]),
      minute: int.parse(endTimeParts[1]),
    );

    // Find the next occurrence of this day of week
    DateTime nextDate = DateTime.now();
    while (nextDate.weekday % 7 != suggestion.dayOfWeek) {
      nextDate = nextDate.add(const Duration(days: 1));
    }

    // Create events for 5 years (260 weeks)
    int eventsCreated = 0;
    int eventsSkipped = 0;
    final endDate = nextDate.add(const Duration(days: 365 * 5));

    while (nextDate.isBefore(endDate)) {
      final normalizedDate = _normalizeDate(nextDate);

      // Check if an event with the same title already exists on this date
      final existingEvents = _events[normalizedDate] ?? [];
      final alreadyExists = existingEvents.any((e) =>
        e.title.toLowerCase().trim() == suggestion.title.toLowerCase().trim());

      if (alreadyExists) {
        // Skip this date - event already exists (likely one that triggered the habit tracking)
        eventsSkipped++;
        nextDate = nextDate.add(const Duration(days: 7));
        continue;
      }

      // Create the event
      final event = CalendarEvent(
        id: 'habit_${suggestion.habitId}_${nextDate.millisecondsSinceEpoch}',
        title: suggestion.title,
        date: normalizedDate,
        startTime: startTime,
        endTime: endTime,
        location: suggestion.location,
        description: suggestion.description,
      );

      // Add to events map
      if (_events[normalizedDate] == null) {
        _events[normalizedDate] = [];
      }
      _events[normalizedDate]!.add(event);
      eventsCreated++;

      // Move to next week
      nextDate = nextDate.add(const Duration(days: 7));
    }

    print('Skipped $eventsSkipped dates where event already exists');

    // Update UI
    setState(() {});

    print('Created $eventsCreated recurring events for habit "${suggestion.title}"');
    return eventsCreated;
  }

  Future<void> _dismissSuggestion(HabitSuggestion suggestion) async {
    try {
      await _habitTrackingService.dismissSuggestion(suggestion.habitId);

      // Reload suggestions
      await _loadHabitSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion dismissed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Constants.spacingL),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: Constants.spacingM),
            Text(
              'No events for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: Constants.spacingS),
            Text(
              'Tap the + button to add an event',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Constants.spacingM),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: Constants.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habit Tracking Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Events you create are tracked. Add the same event 3+ times to get habit suggestions!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: Constants.spacingS),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text(event.formattedTime, style: const TextStyle(fontSize: 12)),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14),
                  const SizedBox(width: 4),
                  Text(event.location!, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteEvent(event);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event deleted')),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(Constants.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add New Event',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: Constants.spacingS),
                  Text(
                    'Date: ${_formatDate(_selectedDay ?? DateTime.now())}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: Constants.spacingM),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Team Meeting, Gym Session',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: Constants.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setModalState(() {
                                startTime = time;
                                startTimeController.text = time.format(context);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: Constants.spacingM),
                      Expanded(
                        child: TextField(
                          controller: endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End Time *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setModalState(() {
                                endTime = time;
                                endTimeController.text = time.format(context);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Constants.spacingM),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'e.g., Office, Home, Gym',
                    ),
                  ),
                  const SizedBox(height: Constants.spacingM),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: Constants.spacingL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validation
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an event title'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (startTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a start time'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an end time'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Create and add event
                        final event = CalendarEvent(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                          date: _selectedDay ?? DateTime.now(),
                          startTime: startTime!,
                          endTime: endTime!,
                          location: locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );

                        _addEvent(event);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Event "${event.title}" created and recorded for habit tracking!',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: Constants.spacingM),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Save Event'),
                    ),
                  ),
                  const SizedBox(height: Constants.spacingS),
                  Center(
                    child: Text(
                      'Tip: Create the same event 3+ times for habit suggestions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: Constants.spacingS),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
