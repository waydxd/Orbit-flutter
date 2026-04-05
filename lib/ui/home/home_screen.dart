import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../habit_tracking/widgets/habit_suggestions_badge.dart';
import '../../utils/constants.dart';

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
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );

  DateTime get endDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
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

  // Store events by date
  final Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _addSampleEvents();
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
          const HabitSuggestionsIconButton(),
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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5),
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
                border:
                    Border.all(color: Theme.of(context).colorScheme.primary),
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
        // Show regular events
        if (events.isEmpty)
          _buildEmptyState()
        else
          ...events.map((event) => _buildEventCard(event)),
      ],
    );
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
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.8),
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
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
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

                        // Ensure end time is after start time
                        final startMinutes =
                            startTime!.hour * 60 + startTime!.minute;
                        final endMinutes =
                            endTime!.hour * 60 + endTime!.minute;
                        if (endMinutes <= startMinutes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('End time must be after start time'),
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
                              'Event "${event.title}" created!',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: Constants.spacingM),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
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
