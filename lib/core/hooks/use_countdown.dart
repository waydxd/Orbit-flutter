import 'dart:async';

class CountdownController {
  final CountdownConfig config;
  final CountdownState _state = CountdownState();
  Timer? _timer;
  bool _hasWarned = false;
  DateTime? _currentDueDate;

  CountdownController({required this.config});

  CountdownState get state => _state;

  void start() {
    _currentDueDate = config.dueDate;
    _hasWarned = false;
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _updateState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateState();
    });
  }

  void _updateState() {
    if (config.dueDate == null) {
      _state.text = '';
      return;
    }

    final now = DateTime.now();
    final difference = config.dueDate!.difference(now);

    // Call onWarning if due in less than 30 minutes and hasn't warned yet
    if (!difference.isNegative && difference.inMinutes <= 30 && !_hasWarned) {
      _hasWarned = true;
      config.onWarning?.call();
    }

    // Call onTick
    config.onTick?.call(difference.inSeconds);

    // Update text
    String newText;
    if (difference.isNegative) {
      newText = 'Overdue';
    } else if (difference.inDays > 1) {
      newText = '${difference.inDays} days';
    } else if (difference.inDays == 1) {
      newText = '1 day ${difference.inHours.remainder(24)}h';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);

      if (hours > 0) {
        newText = '${hours}h ${minutes}m';
      } else if (minutes > 0) {
        newText = '${minutes}m';
      } else {
        newText = '< 1m';
      }
    }

    _state.text = newText;
  }

  void updateDueDate(DateTime? dueDate) {
    if (_currentDueDate != dueDate) {
      _currentDueDate = dueDate;
      _hasWarned = false;
      _updateState();
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class CountdownConfig {
  final DateTime? dueDate;
  final void Function()? onWarning;
  final void Function(int seconds)? onTick;

  CountdownConfig({
    this.dueDate,
    this.onWarning,
    this.onTick,
  });
}

class CountdownState {
  String text = '';
}
