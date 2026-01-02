import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../calendar/view_model/calendar_view_model.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/task_model.dart';

class CreateItemPage extends StatefulWidget {
  const CreateItemPage({super.key});

  @override
  State<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends State<CreateItemPage> {
  bool isEvent = true;
  int selectedColorIndex = 0;

  // Form controllers and state
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

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
  String _selectedTag = '';

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
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(hours: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _deadlineTime ?? TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _deadlineDate = picked;
          _deadlineTime = pickedTime;
        });
      }
    }
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

        final event = EventModel(
          id: uuid.v4(),
          userId: currentUserId,
          title: _nameController.text,
          description: _detailsController.text,
          startTime: start,
          endTime: end,
          location: '', // Can be added later
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await viewModel.createEvent(event);
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

        final fullDescription = _selectedTag.isNotEmpty
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isEvent ? 'Event' : 'Task'} created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ${isEvent ? 'event' : 'task'}: $e'),
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
              _buildToggle(),
              const SizedBox(height: 30),
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
                onTap: () async {
                  await _selectDate(context, true);
                  if (mounted) await _selectTime(context, true);
                },
                child: _buildTimeField(
                  '${_startDate.day}/${_startDate.month} ${_startTime.format(context)}',
                  Icons.flag_outlined,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  await _selectDate(context, false);
                  if (mounted) await _selectTime(context, false);
                },
                child: _buildTimeField(
                  '${_endDate.day}/${_endDate.month} ${_endTime.format(context)}',
                  Icons.play_arrow_outlined,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDropdownField('Repeat', _selectedRepeat, (val) {
          setState(() => _selectedRepeat = val!);
        }, ['Never', 'Daily', 'Weekly', 'Monthly']),
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
          onTap: _selectDeadline,
          child: _buildTimeField(
            _deadlineDate != null
                ? '${_deadlineDate!.day}/${_deadlineDate!.month} ${_deadlineTime!.format(context)}'
                : 'Deadline',
            Icons.access_time,
            isTask: true,
          ),
        ),
        const SizedBox(height: 20),
        _buildDropdownField(
          '# Tag',
          _selectedTag,
          (val) {
            setState(() => _selectedTag = val!);
          },
          ['', 'Health', 'Work', 'Study', 'FYP'],
          isTag: true,
        ),
        const SizedBox(height: 20),
        _buildDropdownField('Priority', _selectedPriority, (val) {
          setState(() => _selectedPriority = val!);
        }, ['low', 'medium', 'high', 'urgent']),
        const SizedBox(height: 20),
        _buildDetailsField(_detailsController),
      ],
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

  Widget _buildTimeField(String label, IconData icon, {bool isTask = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2CB9B0), size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    void Function(String?) onChanged,
    List<String> items, {
    bool isTag = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: _fieldDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isTag ? '# Tag' : label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(
                Icons.unfold_more_rounded,
                color: Colors.cyan.shade300,
                size: 20,
              ),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value.isEmpty && isTag ? 'None' : value,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }).toList(),
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
                  : const Text(
                      'Create',
                      style: TextStyle(
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
