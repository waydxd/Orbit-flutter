import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../../core/services/app_settings_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _settings = AppSettingsService();

  bool _loading = true;
  bool _eventsEnabled = true;
  bool _tasksEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _settings.getEventNotificationsEnabled();
    final tasks = await _settings.getTaskNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _eventsEnabled = events;
      _tasksEnabled = tasks;
      _loading = false;
    });
  }

  Future<void> _setEvents(bool enabled) async {
    setState(() => _eventsEnabled = enabled);
    await _settings.setEventNotificationsEnabled(enabled);
  }

  Future<void> _setTasks(bool enabled) async {
    setState(() => _tasksEnabled = enabled);
    await _settings.setTaskNotificationsEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E0FF),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECF9FB), Color(0xFFE2E0FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 22,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Control which reminders Orbit is allowed to send.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Event & Task notifications',
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            _ToggleTile(
                              title: 'Event notifications',
                              subtitle:
                                  'Reminders for upcoming calendar events.',
                              value: _eventsEnabled,
                              onChanged: _setEvents,
                            ),
                            const _DividerLine(),
                            _ToggleTile(
                              title: 'Task notifications',
                              subtitle: 'Reminders for tasks and due dates.',
                              value: _tasksEnabled,
                              onChanged: _setTasks,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                const _HintCard(
                  text:
                      'If you turned on these toggles but still don’t receive notifications, check system notification permissions for Orbit in your phone settings.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (next) => onChanged(next),
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.grey300.withValues(alpha: 0.75),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;

  const _HintCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
