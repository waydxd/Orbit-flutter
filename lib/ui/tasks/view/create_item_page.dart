import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/location_service.dart';

class _DateTimePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateTimeChanged;

  const _DateTimePickerSheet({
    required this.initialDate,
    required this.onDateTimeChanged,
  });

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  late DateTime _selectedDate;
  int _selectedTab = 0; // 0 for Date, 1 for Time

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
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
            child: _selectedTab == 0
                ? CupertinoDatePicker(
                    key: const ValueKey('date_picker'),
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDate,
                    minimumDate:
                        DateTime.now().subtract(const Duration(days: 1)),
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        _selectedDate = DateTime(
                          newDate.year,
                          newDate.month,
                          newDate.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
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

  const CreateItemPage({
    this.initialIsEvent = true,
    this.editEvent,
    super.key,
  });

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  bool isEvent = true;
  int selectedColorIndex = 0;

  // Form controllers and state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isEvent = widget.editEvent != null ? true : widget.initialIsEvent;

    if (widget.editEvent != null) {
      _prefillFromEditEvent();
    }
  }

  void _prefillFromEditEvent() {
    final event = widget.editEvent!;
    _nameController.text = event.title;
    _detailsController.text = event.description;
    _locationController.text = event.location;
    _startDate = event.startTime;
    _startTime = TimeOfDay.fromDateTime(event.startTime);
    _endDate = event.endTime;
    _endTime = TimeOfDay.fromDateTime(event.endTime);
  }

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;

  String _selectedRepeat = 'Never';
  String _selectedPriority = 'medium';
  String? _selectedTag;

  final List<Color> eventColors = [
    const Color(0xFFE0E5EC), // The planet/moon one (placeholder)
    const Color(0xFF0D3B4C),
    const Color(0xFF005691),
    const Color(0xFF2CB9B0),
    const Color(0xFF63E695),
    const Color(0xFFFF8A80),
    const Color(0xFFFFB74D),
    const Color(0xFFE195FF),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _showDateTimePicker(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateTimeChanged,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return _DateTimePickerSheet(
          initialDate: initialDate,
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
      onDateTimeChanged: (DateTime newDateTime) {
        setState(() {
          _startDate = newDateTime;
          _startTime = TimeOfDay.fromDateTime(newDateTime);

          final currentEnd = DateTime(_endDate.year, _endDate.month,
              _endDate.day, _endTime.hour, _endTime.minute);
          if (currentEnd.isBefore(newDateTime)) {
            final newEnd = newDateTime.add(const Duration(hours: 1));
            _endDate = newEnd;
            _endTime = TimeOfDay.fromDateTime(newEnd);
          }
        });
      },
    );
  }

  Future<void> _selectEndDateTime() async {
    final initial = DateTime(_endDate.year, _endDate.month, _endDate.day,
        _endTime.hour, _endTime.minute);
    await _showDateTimePicker(
      context,
      initialDate: initial,
      onDateTimeChanged: (DateTime newDateTime) {
        setState(() {
          _endDate = newDateTime;
          _endTime = TimeOfDay.fromDateTime(newDateTime);
        });
      },
    );
  }

  Future<void> _selectDeadlineDateTime() async {
    final initial = _deadlineDate != null
        ? DateTime(_deadlineDate!.year, _deadlineDate!.month,
            _deadlineDate!.day, _deadlineTime!.hour, _deadlineTime!.minute)
        : DateTime.now();

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

    try {
      if (isEvent) {
        final start = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        final end = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          _endTime.hour,
          _endTime.minute,
        );

        if (widget.editEvent != null) {
          final event = widget.editEvent!.copyWith(
            title: _nameController.text,
            description: _detailsController.text,
            startTime: start,
            endTime: end,
            location: _locationController.text,
            updatedAt: DateTime.now(),
          );
          await viewModel.updateEvent(event);
        } else {
          final event = EventModel(
            id: uuid.v4(),
            userId: currentUserId,
            title: _nameController.text,
            description: _detailsController.text,
            startTime: start,
            endTime: end,
            location: _locationController.text,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await viewModel.createEvent(event);
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

        final fullDescription = (_selectedTag != null && _selectedTag!.isNotEmpty)
            ? '#$_selectedTag ${_detailsController.text}'
            : _detailsController.text;

        final task = TaskModel(
          id: uuid.v4(),
          userId: currentUserId,
          title: _nameController.text,
          description: fullDescription,
          dueDate: deadline,
          completed: false,
          priority: _selectedPriority,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await viewModel.createTask(task);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isEvent ? 'Event' : 'Task'} ${widget.editEvent != null ? 'updated' : 'created'} successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to ${widget.editEvent != null ? 'update' : 'create'} ${isEvent ? 'event' : 'task'}: $e'),
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
              _buildHeader(),
              const SizedBox(height: 20),
              if (widget.editEvent == null) ...[
                _buildToggle(),
                const SizedBox(height: 30),
              ] else ...[
                const Text(
                  'Edit Event',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 30),
              ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left,
              color: Color(0xFF6366F1),
              size: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
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
      onTap: () => setState(() => isEvent = label == 'Event'),
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
        _buildTextField(_nameController, 'Event name'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectStartDateTime,
                child: _buildTimeField(
                  DateFormat('MMM d, h:mm a').format(DateTime(
                      _startDate.year,
                      _startDate.month,
                      _startDate.day,
                      _startTime.hour,
                      _startTime.minute)),
                  Icons.flag_outlined,
                  title: 'Start',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _selectEndDateTime,
                child: _buildTimeField(
                  DateFormat('MMM d, h:mm a').format(DateTime(
                      _endDate.year,
                      _endDate.month,
                      _endDate.day,
                      _endTime.hour,
                      _endTime.minute)),
                  Icons.play_arrow_outlined,
                  title: 'End',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildLocationField(),
        const SizedBox(height: 20),
        ModernDropdownField<String>(
          label: 'Repeat',
          icon: Icons.repeat_rounded,
          value: _selectedRepeat,
          displayStringForValue: (val) => val,
          items: const ['Never', 'Daily', 'Weekly', 'Monthly'],
          onChanged: (val) {
            if (val != null) setState(() => _selectedRepeat = val);
          },
        ),
        const SizedBox(height: 20),
        _buildDetailsField(_detailsController),
        const SizedBox(height: 20),
        _buildColorPicker(),
      ],
    );
  }

  Widget _buildTaskForm() {
    return Column(
      children: [
        _buildTextField(_nameController, 'Task name'),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _selectDeadlineDateTime,
          child: _buildTimeField(
            _deadlineDate != null
                ? DateFormat('MMM d, h:mm a').format(DateTime(
                    _deadlineDate!.year,
                    _deadlineDate!.month,
                    _deadlineDate!.day,
                    _deadlineTime!.hour,
                    _deadlineTime!.minute))
                : 'Deadline',
            Icons.access_time_rounded,
            title: 'Deadline',
          ),
        ),
        const SizedBox(height: 20),
        ModernDropdownField<String>(
          label: 'Tag',
          icon: Icons.label_outline_rounded,
          value: _selectedTag,
          displayStringForValue: (val) => '# $val',
          items: const ['Health', 'Work', 'Study', 'FYP'],
          onChanged: (val) {
            setState(() => _selectedTag = val);
          },
        ),
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
        _buildDetailsField(_detailsController),
      ],
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: _fieldDecoration(),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return await LocationService.getPlaceSuggestions(
              textEditingValue.text);
        },
        onSelected: (String selection) {
          _locationController.text = selection;
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          // Sync controllers
          controller.addListener(() {
            _locationController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            decoration: InputDecoration(
              hintText: 'Location (Optional)',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon:
                  Icon(Icons.location_on_outlined, color: Colors.grey.shade400),
              border: InputBorder.none,
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
                      leading:
                          const Icon(Icons.location_on, color: Colors.grey),
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
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: _fieldDecoration(),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(String value, IconData icon, {String? title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2CB9B0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2CB9B0), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  value,
                  style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailsField(TextEditingController controller) {
    return Container(
      height: 150,
      decoration: _fieldDecoration(),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Details',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Icon(
              Icons.drag_handle_rounded,
              color: Colors.grey.shade300,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0FF), width: 1),
          bottom: BorderSide(color: Color(0xFFE0E0FF), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(eventColors.length, (index) {
            return GestureDetector(
              onTap: () => setState(() => selectedColorIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: eventColors[index],
                  shape: BoxShape.circle,
                  border: selectedColorIndex == index
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: selectedColorIndex == index
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: index == 0
                    ? Center(
                        child: Icon(
                          Icons.public,
                          size: 20,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
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
                      widget.editEvent != null ? 'Update' : 'Create',
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
