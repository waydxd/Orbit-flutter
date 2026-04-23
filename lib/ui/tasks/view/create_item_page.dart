import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../core/widgets/hashtag_chip.dart';
import '../../../data/models/event_model.dart';
import '../../../data/utils/event_recurrence.dart';
import '../../../data/utils/event_recurrence_materialize.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/nlp_parse_result.dart';
import '../../../data/models/hashtag_prediction.dart';
import '../../../data/services/hashtag_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/travel_time_service.dart';
import '../../../data/services/txt2img_service.dart';
import '../../../data/utils/buffer_time_prior_event.dart';
import '../../../config/environment.dart';
import '../../../utils/logger.dart';

class _DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateTimeChanged;
  final bool dateOnly;

  const _DateTimePickerSheet({
    required this.initialDate,
    required this.onDateTimeChanged,
    this.dateOnly = false,
  });

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _selectedDate;
  int _selectedTab = 0; // 0 for Date, 1 for Time

  DateTime _clampDateTime(
    DateTime value, {
    required DateTime min,
    DateTime? max,
  }) {
    if (value.isBefore(min)) return min;
    if (max != null && value.isAfter(max)) return max;
    return value;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final minDate = todayStart.subtract(const Duration(days: 1));
    final maxDate =
        DateTime(todayStart.year + 5, todayStart.month, todayStart.day);
    final safeInitialDate = _clampDateTime(
      _selectedDate,
      min: minDate,
      max: maxDate,
    );

    return Container(
      height: 380,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ),
                if (widget.dateOnly)
                  Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  )
                else
                  CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedTab,
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Date'),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Time'),
                      ),
                    },
                    onValueChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _selectedTab = value;
                        });
                      }
                    },
                  ),
                TextButton(
                  onPressed: () {
                    widget.onDateTimeChanged(_selectedDate);
                    Navigator.pop(context);
                  },
                  child: const Text('Done',
                      style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.dateOnly || _selectedTab == 0
                ? CupertinoDatePicker(
                    key: const ValueKey('date_picker'),
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: safeInitialDate,
                    minimumDate: minDate,
                    maximumDate: maxDate,
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        final merged = DateTime(
                          newDate.year,
                          newDate.month,
                          newDate.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                        _selectedDate = _clampDateTime(
                          merged,
                          min: minDate,
                          max: maxDate,
                        );
                      });
                    },
                  )
                : CupertinoDatePicker(
                    key: const ValueKey('time_picker'),
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _selectedDate,
                    onDateTimeChanged: (DateTime newTime) {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CreateItemPage extends StatefulWidget {
  final bool initialIsEvent;
  final EventModel? editEvent;
  final TaskModel? editTask;
  final NlpParseResult? parsedResult;
  final DateTime? initialDateTime;

  const CreateItemPage({
    this.initialIsEvent = true,
    this.editEvent,
    this.editTask,
    this.parsedResult,
    this.initialDateTime,
    super.key,
  }) : assert(
          editEvent == null || editTask == null,
          'editEvent and editTask are mutually exclusive',
        );

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  late bool isEvent;

  // Form controllers and state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _eventDetailsFocusNode = FocusNode();
  bool _suppressLocationSuggestions = false;
  String? _lastSelectedLocationSuggestion;

  DateTime _nextWholeHour(DateTime from) {
    final local = from.toLocal();
    return DateTime(local.year, local.month, local.day, local.hour + 1);
  }

  void _applyCreateDefaults() {
    final seedDate = widget.initialDateTime ?? DateTime.now();
    final normalizedDate = DateTime(seedDate.year, seedDate.month, seedDate.day);
    final nextHour = _nextWholeHour(DateTime.now());
    final defaultStart = DateTime(
      normalizedDate.year,
      normalizedDate.month,
      normalizedDate.day,
      nextHour.hour,
      nextHour.minute,
    );
    final defaultEnd = defaultStart.add(const Duration(hours: 1));
    _startDate = defaultStart;
    _startTime = TimeOfDay.fromDateTime(defaultStart);
    _endDate = defaultEnd;
    _endTime = TimeOfDay.fromDateTime(defaultEnd);
    _deadlineDate = null;
    _deadlineTime = null;
  }

  @override
  void initState() {
    super.initState();
    _eventDetailsFocusNode.addListener(_onEventDetailsFocusChanged);
    _applyCreateDefaults();
    if (widget.editEvent != null) {
      isEvent = true;
      _prefillFromEditEvent();
    } else if (widget.editTask != null) {
      isEvent = false;
      _prefillFromEditTask();
    } else if (widget.parsedResult != null) {
      isEvent = widget.parsedResult!.type == 'event';
      _prefillFromParsedResult();
    } else {
      isEvent = widget.initialIsEvent;
    }

    // Auto-predict hashtags when text changes (event + task)
    _nameController.addListener(_onTextChanged);
    _detailsController.addListener(_onTextChanged);

    if (widget.parsedResult != null) {
      // Parsed text is assigned before listeners are attached, so trigger once.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onTextChanged();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && isEvent) _scheduleBufferCheck();
    });
  }

  void _onEventDetailsFocusChanged() {
    if (mounted) setState(() {});
  }

  void _prefillFromEditEvent() {
    final event = widget.editEvent!;
    _nameController.text = event.title;
    _detailsController.text = event.description;
    _locationController.text = event.location;
    _startDate = event.startTime;
    _endDate = event.endTime;
    _isAllDay = _inferAllDayFromStoredRange(event.startTime, event.endTime);
    if (_isAllDay) {
      _startTime = const TimeOfDay(hour: 0, minute: 0);
      _endTime = const TimeOfDay(hour: 23, minute: 59);
    } else {
      _startTime = TimeOfDay.fromDateTime(event.startTime);
      _endTime = TimeOfDay.fromDateTime(event.endTime);
    }
    _selectedTags = List<String>.from(event.hashtags);
    final pre = EventRecurrence.prefillFromEvent(event);
    _repeatFrequencyLabel = pre.frequencyLabel;
    _repeatUntilDate = pre.untilLocalDate;
  }

  void _prefillFromEditTask() {
    final task = widget.editTask!;
    _nameController.text = task.title;
    _detailsController.text = task.description;
    if (task.dueDate != null) {
      _deadlineDate = task.dueDate;
      _deadlineTime = TimeOfDay.fromDateTime(task.dueDate!);
    }
    _selectedPriority = task.priority.isNotEmpty ? task.priority : 'medium';
    _selectedTags = List<String>.from(task.hashtags);
  }

  /// Heuristic: stored as local midnight → end-of-day (23:59).
  bool _inferAllDayFromStoredRange(DateTime start, DateTime end) {
    final startOfDay =
        start.hour == 0 && start.minute == 0 && start.second == 0;
    final endOfDay = end.hour == 23 && end.minute == 59;
    return startOfDay && endOfDay && !end.isBefore(start);
  }

  void _prefillFromParsedResult() {
    final result = widget.parsedResult!;

    _nameController.text = result.title;
    _detailsController.text = result.description ?? '';
    if (result.location != null) {
      _locationController.text = result.location!;
    }

    if (result.isEvent) {
      if (result.startTime != null) {
        _startDate = result.startTime!;
        _startTime = TimeOfDay.fromDateTime(result.startTime!);
      }
      if (result.endTime != null) {
        _endDate = result.endTime!;
        _endTime = TimeOfDay.fromDateTime(result.endTime!);
      }

      final recurrence = result.recurrence;
      if (recurrence == null || recurrence.isEmpty) {
        _repeatFrequencyLabel = 'Never';
        _repeatUntilDate = null;
      } else {
        final parts = EventRecurrence.tryParseRule(recurrence);
        if (parts != null) {
          _repeatFrequencyLabel =
              EventRecurrence.labelFromFrequency(parts.frequency);
          if (parts.untilUtc != null) {
            final ul = parts.untilUtc!.toLocal();
            _repeatUntilDate = DateTime(ul.year, ul.month, ul.day);
          } else {
            _repeatUntilDate = null;
          }
        } else {
          _repeatFrequencyLabel = _mapNlpRecurrenceToLabel(recurrence);
          _repeatUntilDate = null;
        }
      }
    } else {
      if (result.dueDate != null) {
        _deadlineDate = result.dueDate;
        _deadlineTime = TimeOfDay.fromDateTime(result.dueDate!);
      }
      _selectedPriority =
          (result.priority.isNotEmpty) ? result.priority : 'medium';
    }
  }

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 1, minute: 0);

  bool _isAllDay = false;
  TimeOfDay? _savedStartTimeBeforeAllDay;
  TimeOfDay? _savedEndTimeBeforeAllDay;

  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;

  String _repeatFrequencyLabel = 'Never';
  DateTime? _repeatUntilDate;

  String _selectedPriority = 'medium';

  // Hashtag state (used for events)
  List<String> _selectedTags = [];
  final HashtagService _hashtagService = HashtagService();
  final TextEditingController _tagInputController = TextEditingController();
  List<HashtagScore> _predictedTags = [];
  bool _isPredicting = false;
  Timer? _debounceTimer;

  static const Duration _bufferMargin = Duration(minutes: 10);
  String? _bufferWarningText;
  bool _bufferCheckLoading = false;
  Timer? _bufferDebounceTimer;
  int _bufferCheckSeq = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _bufferDebounceTimer?.cancel();
    _nameController.removeListener(_onTextChanged);
    _detailsController.removeListener(_onTextChanged);
    _nameController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
    _eventDetailsFocusNode.removeListener(_onEventDetailsFocusChanged);
    _eventDetailsFocusNode.dispose();
    _tagInputController.dispose();
    _hashtagService.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _predictHashtags();
    });
  }

  DateTime? _computeProposedEventStart() {
    if (_isAllDay) return null;
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  void _scheduleBufferCheck() {
    if (!isEvent || !mounted) return;
    _bufferDebounceTimer?.cancel();
    _bufferDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _runBufferTimeCheck();
    });
  }

  Future<void> _runBufferTimeCheck() async {
    if (!mounted || !isEvent) return;
    final seq = ++_bufferCheckSeq;

    void clearWarning() {
      if (!mounted) return;
      setState(() {
        _bufferWarningText = null;
        _bufferCheckLoading = false;
      });
    }

    if (_isAllDay) {
      clearWarning();
      return;
    }

    final loc = _locationController.text.trim();
    if (loc.isEmpty) {
      clearWarning();
      return;
    }

    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) {
      clearWarning();
      return;
    }

    final proposedStart = _computeProposedEventStart();
    if (proposedStart == null) {
      clearWarning();
      return;
    }

    final vm = Provider.of<CalendarViewModel>(context, listen: false);
    final prior = findPriorConsecutiveEvent(
      events: vm.events,
      currentUserId: userId,
      proposedStart: proposedStart,
      excludeEventId: widget.editEvent?.id,
    );

    if (prior == null || prior.location.trim().isEmpty) {
      clearWarning();
      return;
    }

    if (!mounted) return;
    setState(() => _bufferCheckLoading = true);

    final travelSec = await TravelTimeService.drivingDurationSeconds(
      originAddress: prior.location.trim(),
      destinationAddress: loc,
    );

    if (!mounted || seq != _bufferCheckSeq) return;
    setState(() => _bufferCheckLoading = false);

    if (travelSec == null) {
      if (mounted && seq == _bufferCheckSeq) {
        setState(() => _bufferWarningText = null);
      }
      return;
    }

    final available = proposedStart.difference(prior.endTime);
    final required = Duration(seconds: travelSec) + _bufferMargin;

    if (!mounted || seq != _bufferCheckSeq) return;

    if (available < required) {
      final availMin = available.inMinutes;
      final needMin = (required.inSeconds / 60).ceil();
      setState(() {
        _bufferWarningText =
            'Only $availMin minutes after "${prior.title}" end. '
            '$needMin minutes is needed.';
      });
    } else {
      setState(() => _bufferWarningText = null);
    }
  }

  Future<void> _showDateTimePicker(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateTimeChanged,
    bool dateOnly = false,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return _DateTimePickerSheet(
          initialDate: initialDate,
          dateOnly: dateOnly,
          onDateTimeChanged: onDateTimeChanged,
        );
      },
    );
  }

  Future<void> _selectStartDateTime() async {
    final initial = DateTime(_startDate.year, _startDate.month, _startDate.day,
        _startTime.hour, _startTime.minute);
    await _showDateTimePicker(
      context,
      initialDate: initial,
      dateOnly: _isAllDay,
      onDateTimeChanged: (DateTime newDateTime) {
        setState(() {
          if (_isAllDay) {
            _startDate = newDateTime;
            _startTime = const TimeOfDay(hour: 0, minute: 0);
            final endDay =
                DateTime(_endDate.year, _endDate.month, _endDate.day);
            final startDay =
                DateTime(_startDate.year, _startDate.month, _startDate.day);
            if (endDay.isBefore(startDay)) {
              _endDate = _startDate;
            }
          } else {
            _startDate = newDateTime;
            _startTime = TimeOfDay.fromDateTime(newDateTime);
            final newEnd = newDateTime.add(const Duration(hours: 1));
            _endDate = newEnd;
            _endTime = TimeOfDay.fromDateTime(newEnd);
          }
        });
      },
    );
    _scheduleBufferCheck();
  }

  Future<void> _selectEndDateTime() async {
    final initial = DateTime(_endDate.year, _endDate.month, _endDate.day,
        _endTime.hour, _endTime.minute);
    await _showDateTimePicker(
      context,
      initialDate: initial,
      dateOnly: _isAllDay,
      onDateTimeChanged: (DateTime newDateTime) {
        setState(() {
          if (_isAllDay) {
            _endDate = newDateTime;
            _endTime = const TimeOfDay(hour: 23, minute: 59);
            final endDay =
                DateTime(_endDate.year, _endDate.month, _endDate.day);
            final startDay =
                DateTime(_startDate.year, _startDate.month, _startDate.day);
            if (endDay.isBefore(startDay)) {
              _startDate = _endDate;
            }
          } else {
            _endDate = newDateTime;
            _endTime = TimeOfDay.fromDateTime(newDateTime);
            final startDt = DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              _startTime.hour,
              _startTime.minute,
            );
            var endDt = DateTime(
              _endDate.year,
              _endDate.month,
              _endDate.day,
              _endTime.hour,
              _endTime.minute,
            );
            if (!endDt.isAfter(startDt)) {
              endDt = startDt.add(const Duration(hours: 1));
              _endDate = endDt;
              _endTime = TimeOfDay.fromDateTime(endDt);
            }
          }
        });
      },
    );
    _scheduleBufferCheck();
  }

  void _onAllDayChanged(bool value) {
    setState(() {
      if (value) {
        _savedStartTimeBeforeAllDay = _startTime;
        _savedEndTimeBeforeAllDay = _endTime;
        _isAllDay = true;
        _startTime = const TimeOfDay(hour: 0, minute: 0);
        _endTime = const TimeOfDay(hour: 23, minute: 59);
        final startDay =
            DateTime(_startDate.year, _startDate.month, _startDate.day);
        final endDay = DateTime(_endDate.year, _endDate.month, _endDate.day);
        if (endDay.isBefore(startDay)) {
          _endDate = _startDate;
        }
      } else {
        _isAllDay = false;
        _startTime =
            _savedStartTimeBeforeAllDay ?? const TimeOfDay(hour: 9, minute: 0);
        _endTime =
            _savedEndTimeBeforeAllDay ?? const TimeOfDay(hour: 10, minute: 0);
        _savedStartTimeBeforeAllDay = null;
        _savedEndTimeBeforeAllDay = null;
        final startDt = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        var endDt = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          _endTime.hour,
          _endTime.minute,
        );
        if (!endDt.isAfter(startDt)) {
          endDt = startDt.add(const Duration(hours: 1));
          _endDate = endDt;
          _endTime = TimeOfDay.fromDateTime(endDt);
        }
      }
    });
    _scheduleBufferCheck();
  }

  String _formatEventStartLabel() {
    final dt = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    if (_isAllDay) {
      return DateFormat('MMM d, y').format(dt);
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  String _mapNlpRecurrenceToLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Never';
    final x = trimmed.toLowerCase();
    if (x.contains('year')) return 'Yearly';
    if (x.contains('month')) return 'Monthly';
    if (x.contains('week')) return 'Weekly';
    if (x.contains('day') || x == 'daily') return 'Daily';
    return 'Never';
  }

  String _formatEventEndLabel() {
    final dt = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    if (_isAllDay) {
      return DateFormat('MMM d, y').format(dt);
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Widget _buildEventDateTimeSection() {
    return Container(
      decoration: _fieldDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Text(
                  'All-day',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Switch.adaptive(
                    value: _isAllDay,
                    onChanged: _onAllDayChanged,
                    activeThumbColor: const Color(0xFF6366F1),
                    activeTrackColor:
                        const Color(0xFF6366F1).withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade200),
          GestureDetector(
            onTap: _selectStartDateTime,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Starts',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatEventStartLabel(),
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 22),
                ],
              ),
            ),
          ),
          Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade200),
          GestureDetector(
            onTap: _selectEndDateTime,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Ends',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatEventEndLabel(),
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generates and uploads the cover after the event is saved; does not block the UI.
  void _scheduleEventCoverGenerationBackground({
    required CalendarViewModel viewModel,
    required EventModel created,
    required String currentUserId,
    UserModel? currentUser,
  }) {
    unawaited((() async {
      try {
        final t2i = Txt2ImgService();
        final cover = await t2i.requestCoverUrl(created, user: currentUser);
        if (cover.isSuccess && cover.url != null) {
          await viewModel.attachEventCoverUrl(
            eventId: created.id,
            imageUrl: cover.url!,
            userId: currentUserId,
            declaredContentType: cover.contentType,
          );
        } else if (!cover.skipped && cover.errorMessage != null) {
          Logger.warningWithTag(
            'CreateItem',
            'Background cover generation failed: ${cover.errorMessage}',
          );
        }
      } catch (e, st) {
        Logger.errorWithTag(
          'CreateItem',
          'Background cover attach failed: $e\n$st',
        );
      }
    })());
  }

  Future<void> _selectRepeatUntilDate() async {
    final startDay =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final initial = _repeatUntilDate ?? startDay.add(const Duration(days: 30));
    await _showDateTimePicker(
      context,
      initialDate: initial,
      dateOnly: true,
      onDateTimeChanged: (DateTime d) {
        setState(() {
          _repeatUntilDate = DateTime(d.year, d.month, d.day);
        });
      },
    );
  }

  Widget _buildRecurrenceSection() {
    final showRepeatUntil = _repeatFrequencyLabel != 'Never';
    return Container(
      decoration: _fieldDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernDropdownField<String>(
            label: 'Repeat',
            icon: Icons.repeat_rounded,
            value: _repeatFrequencyLabel,
            displayStringForValue: (val) => val,
            items: const [
              'Never',
              'Daily',
              'Weekly',
              'Monthly',
              'Yearly',
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _repeatFrequencyLabel = val;
                if (val == 'Never') {
                  _repeatUntilDate = null;
                }
              });
            },
          ),
          if (showRepeatUntil) ...[
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade200,
            ),
            Material(
              color: Colors.white,
              child: InkWell(
                onTap: _selectRepeatUntilDate,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        'Repeat until',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _repeatUntilDate != null
                              ? DateFormat('MMM d, y').format(_repeatUntilDate!)
                              : 'Select date',
                          style: TextStyle(
                            color: _repeatUntilDate != null
                                ? const Color(0xFF1F2937)
                                : Colors.grey.shade500,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.grey.shade400, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskTitleSection() {
    return Container(
      decoration: _fieldDecoration(),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Task name',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDeadlineSection() {
    final hasDeadline = _deadlineDate != null && _deadlineTime != null;
    final valueText = hasDeadline
        ? DateFormat('MMM d, h:mm a').format(DateTime(
            _deadlineDate!.year,
            _deadlineDate!.month,
            _deadlineDate!.day,
            _deadlineTime!.hour,
            _deadlineTime!.minute,
          ))
        : 'No deadline';

    return Container(
      decoration: _fieldDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  'Deadline',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: hasDeadline,
                  onChanged: _onDeadlineToggleChanged,
                  activeThumbColor: const Color(0xFF6366F1),
                  activeTrackColor:
                      const Color(0xFF6366F1).withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
          if (hasDeadline) ...[
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey.shade200,
            ),
            GestureDetector(
              onTap: _selectDeadlineDateTime,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Text(
                      'Due date',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        valueText,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _onDeadlineToggleChanged(bool enabled) {
    setState(() {
      if (!enabled) {
        _deadlineDate = null;
        _deadlineTime = null;
        return;
      }

      final fallback = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      _deadlineDate = fallback;
      _deadlineTime = TimeOfDay.fromDateTime(fallback);
    });
  }

  Future<void> _selectDeadlineDateTime() async {
    final initial = _deadlineDate != null
        ? DateTime(_deadlineDate!.year, _deadlineDate!.month,
            _deadlineDate!.day, _deadlineTime!.hour, _deadlineTime!.minute)
        : _startDate;

    await _showDateTimePicker(
      context,
      initialDate: initial,
      onDateTimeChanged: (DateTime newDateTime) {
        setState(() {
          _deadlineDate = newDateTime;
          _deadlineTime = TimeOfDay.fromDateTime(newDateTime);
        });
      },
    );
  }

  void _handleCreate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    final viewModel = Provider.of<CalendarViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final currentUserId = authViewModel.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    const uuid = Uuid();
    int? createdEventCount;

    try {
      if (isEvent) {
        final DateTime start;
        final DateTime end;
        if (_isAllDay) {
          final startDay =
              DateTime(_startDate.year, _startDate.month, _startDate.day);
          var endDay = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            23,
            59,
            59,
            999,
          );
          if (endDay.isBefore(startDay)) {
            endDay = DateTime(
              startDay.year,
              startDay.month,
              startDay.day,
              23,
              59,
              59,
              999,
            );
          }
          start = startDay;
          end = endDay;
        } else {
          start = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
          end = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            _endTime.hour,
            _endTime.minute,
          );
        }

        final freq = EventRecurrence.frequencyFromLabel(_repeatFrequencyLabel);
        final startCal = DateTime(start.year, start.month, start.day);
        if (freq != RecurrenceFrequency.never) {
          if (_repeatUntilDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Choose a repeat end date'),
              ),
            );
            return;
          }
          final untilCal = DateTime(
            _repeatUntilDate!.year,
            _repeatUntilDate!.month,
            _repeatUntilDate!.day,
          );
          if (untilCal.isBefore(startCal)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Choose an end date on or after the event start date',
                ),
              ),
            );
            return;
          }
        }

        final recur = EventRecurrence.encode(
          frequency: freq,
          startLocal: start,
          endsNever: freq == RecurrenceFrequency.never,
          untilLocalDate: _repeatUntilDate,
        );

        if (widget.editEvent != null) {
          final event = widget.editEvent!.copyWith(
            title: _nameController.text,
            description: _detailsController.text,
            startTime: start,
            endTime: end,
            location: _locationController.text,
            hashtags: List<String>.from(_selectedTags),
            isRecurring: recur.isRecurring,
            recurrenceRule: recur.recurrenceRule,
            recurrenceException: recur.recurrenceException,
            updatedAt: DateTime.now(),
          );
          await viewModel.updateEvent(event);
        } else {
          if (freq == RecurrenceFrequency.never) {
            final event = EventModel(
              id: uuid.v4(),
              userId: currentUserId,
              title: _nameController.text,
              description: _detailsController.text,
              startTime: start,
              endTime: end,
              location: _locationController.text,
              hashtags: List<String>.from(_selectedTags),
              isRecurring: recur.isRecurring,
              recurrenceRule: recur.recurrenceRule,
              recurrenceException: recur.recurrenceException,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            final created = await viewModel.createEvent(event);
            createdEventCount = 1;

            if (EnvironmentConfig.shouldClientAttemptTxt2Img) {
              _scheduleEventCoverGenerationBackground(
                viewModel: viewModel,
                created: created,
                currentUserId: currentUserId,
                currentUser: authViewModel.currentUser,
              );
            }
          } else {
            final untilLocal = DateTime(
              _repeatUntilDate!.year,
              _repeatUntilDate!.month,
              _repeatUntilDate!.day,
            );
            final slots = materializeRecurringOccurrences(
              frequency: freq,
              firstStart: start,
              firstEnd: end,
              untilLocalDate: untilLocal,
            );
            if (slots.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No occurrences in the chosen date range'),
                ),
              );
              return;
            }
            final now = DateTime.now();
            final events = <EventModel>[];
            for (final slot in slots) {
              events.add(
                EventModel(
                  id: uuid.v4(),
                  userId: currentUserId,
                  title: _nameController.text,
                  description: _detailsController.text,
                  startTime: slot.start,
                  endTime: slot.end,
                  location: _locationController.text,
                  hashtags: List<String>.from(_selectedTags),
                  isRecurring: false,
                  recurrenceRule: '',
                  recurrenceException: '',
                  createdAt: now,
                  updatedAt: now,
                ),
              );
            }
            final createdList = await viewModel.createEvents(events);
            createdEventCount = createdList.length;

            if (EnvironmentConfig.shouldClientAttemptTxt2Img &&
                createdList.isNotEmpty) {
              _scheduleEventCoverGenerationBackground(
                viewModel: viewModel,
                created: createdList.first,
                currentUserId: currentUserId,
                currentUser: authViewModel.currentUser,
              );
            }
          }
        }
      } else {
        DateTime? deadline;
        if (_deadlineDate != null && _deadlineTime != null) {
          deadline = DateTime(
            _deadlineDate!.year,
            _deadlineDate!.month,
            _deadlineDate!.day,
            _deadlineTime!.hour,
            _deadlineTime!.minute,
          );
        }

        if (widget.editTask != null) {
          final t = widget.editTask!;
          final updated = TaskModel(
            id: t.id,
            userId: t.userId,
            title: _nameController.text,
            description: _detailsController.text,
            dueDate: deadline,
            completed: t.completed,
            priority: _selectedPriority,
            hashtags: List<String>.from(_selectedTags),
            createdAt: t.createdAt,
            updatedAt: DateTime.now(),
          );
          await viewModel.updateTask(updated);
        } else {
          final task = TaskModel(
            id: uuid.v4(),
            userId: currentUserId,
            title: _nameController.text,
            description: _detailsController.text,
            dueDate: deadline,
            completed: false,
            priority: _selectedPriority,
            hashtags: List<String>.from(_selectedTags),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await viewModel.createTask(task);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        String successMsg;
        if (!isEvent) {
          successMsg =
              'Task ${widget.editTask != null ? 'updated' : 'created'} successfully!';
        } else if (widget.editEvent != null) {
          successMsg = 'Event updated successfully!';
        } else if (createdEventCount != null && createdEventCount > 1) {
          successMsg = '$createdEventCount events created successfully!';
        } else {
          successMsg = 'Event created successfully!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${isEvent ? (widget.editEvent != null ? 'update' : 'create') : (widget.editTask != null ? 'update' : 'create')} ${isEvent ? 'event' : 'task'}: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F9FF), Color(0xFFEBEBFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (isEvent) _buildEventForm() else _buildTaskForm(),
                      const SizedBox(height: 30),
                      _buildCreateButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF6366F1),
              size: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: widget.editEvent != null
                  ? const Text(
                      'Edit Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    )
                  : widget.editTask != null
                      ? const Text(
                          'Edit Task',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        )
                      : _buildToggle(),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Event', isEvent),
          _buildToggleButton('Task', !isEvent),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isEvent = label == 'Event';
          if (!isEvent) {
            _bufferWarningText = null;
            _bufferCheckLoading = false;
            _bufferDebounceTimer?.cancel();
          }
        });
        if (isEvent) _scheduleBufferCheck();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D2D2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEventForm() {
    return Column(
      children: [
        _buildEventTitleLocationSection(),
        const SizedBox(height: 20),
        _buildEventDateTimeSection(),
        const SizedBox(height: 20),
        _buildRecurrenceSection(),
        const SizedBox(height: 20),
        _buildEventHashtagField(),
        const SizedBox(height: 20),
        _buildEventDetailsField(),
      ],
    );
  }

  Future<void> _predictHashtags() async {
    final text = '${_nameController.text} ${_detailsController.text}'.trim();
    if (text.isEmpty) return;
    setState(() => _isPredicting = true);
    try {
      final prediction = await _hashtagService.predictHashtags(text);
      if (!mounted) return;
      setState(() {
        _predictedTags = prediction.top5;
        _isPredicting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPredicting = false);
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().replaceAll(RegExp(r'^#+'), '');
    if (trimmed.isEmpty) return;
    if (_selectedTags.contains(trimmed)) return;
    setState(() => _selectedTags.add(trimmed));
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  Widget _buildEventHashtagField() {
    final sortedSuggestions = List<HashtagScore>.from(_predictedTags)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final visibleSuggestions = sortedSuggestions
        .where((p) =>
            !_selectedTags.contains(p.hashtag.replaceAll(RegExp(r'^#+'), '')))
        .toList();

    return Container(
      decoration: _fieldDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tag_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hashtags',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isPredicting) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ],
          ),
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Added',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTags.map((tag) {
                return HashtagChipFilled(
                  tag: tag,
                  onRemove: () => _removeTag(tag),
                );
              }).toList(),
            ),
          ],
          if (visibleSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'From your text',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            ...visibleSuggestions.map((prediction) {
              final displayTag = prediction.hashtag.startsWith('#')
                  ? prediction.hashtag
                  : '#${prediction.hashtag}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HashtagChipSuggestion(
                  tag: prediction.hashtag,
                  displayLabel: displayTag,
                  confidence: prediction.confidence,
                  onTap: () => _addTag(prediction.hashtag),
                ),
              );
            }),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInputController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add tag manually...',
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  onSubmitted: (value) {
                    _addTag(value);
                    _tagInputController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _addTag(_tagInputController.text);
                  _tagInputController.clear();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskForm() {
    return Column(
      children: [
        _buildTaskTitleSection(),
        const SizedBox(height: 20),
        _buildTaskDeadlineSection(),
        const SizedBox(height: 20),
        ModernDropdownField<String>(
          label: 'Priority',
          icon: Icons.flag_outlined,
          value: _selectedPriority,
          displayStringForValue: (val) =>
              val[0].toUpperCase() + val.substring(1),
          items: const ['low', 'medium', 'high', 'urgent'],
          onChanged: (val) {
            if (val != null) setState(() => _selectedPriority = val);
          },
        ),
        const SizedBox(height: 20),
        _buildEventHashtagField(),
        const SizedBox(height: 20),
        _buildEventDetailsField(),
      ],
    );
  }

  Widget _buildEventTitleLocationSection() {
    return Container(
      decoration: _fieldDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Event name',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade200,
          ),
          _buildLocationAutocompleteBody(),
          if (_bufferCheckLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: const Color(0xFF6366F1).withValues(alpha: 0.6),
              ),
            ),
          if (_bufferWarningText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade800,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bufferWarningText!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationAutocompleteBody() {
    final initialLocation = _locationController.text;
    return Autocomplete<String>(
      initialValue: initialLocation.isNotEmpty
          ? TextEditingValue(text: initialLocation)
          : null,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }
        if (_suppressLocationSuggestions &&
            query == _lastSelectedLocationSuggestion) {
          return const Iterable<String>.empty();
        }
        return await LocationService.getPlaceSuggestions(query);
      },
      onSelected: (String selection) {
        _locationController.text = selection;
        _lastSelectedLocationSuggestion = selection;
        _suppressLocationSuggestions = true;
        FocusManager.instance.primaryFocus?.unfocus();
        _scheduleBufferCheck();
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          onTap: () {
            if (_suppressLocationSuggestions) {
              setState(() {
                _suppressLocationSuggestions = false;
              });
            }
          },
          onChanged: (value) {
            _locationController.text = value;
            if (value != _lastSelectedLocationSuggestion &&
                _suppressLocationSuggestions) {
              setState(() {
                _suppressLocationSuggestions = false;
              });
            }
            if (isEvent) _scheduleBufferCheck();
          },
          decoration: InputDecoration(
            hintText: 'Location',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventDetailsField() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TextField(
              controller: _detailsController,
              focusNode: _eventDetailsFocusNode,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Details',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: IgnorePointer(
              child: Icon(
                Icons.drag_handle_rounded,
                color: Colors.grey.shade300,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return Consumer<CalendarViewModel>(
      builder: (context, viewModel, _) {
        return GestureDetector(
          onTap: viewModel.isLoading ? null : _handleCreate,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: viewModel.isLoading ? Colors.grey : Colors.black,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: viewModel.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.editEvent != null || widget.editTask != null
                          ? 'Update'
                          : 'Create',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
