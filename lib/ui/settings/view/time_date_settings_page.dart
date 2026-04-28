import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../core/themes/app_colors.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../utils/region_timezone_data.dart';

class TimeDateSettingsPage extends StatefulWidget {
  const TimeDateSettingsPage({super.key});

  @override
  State<TimeDateSettingsPage> createState() => _TimeDateSettingsPageState();
}

class _TimeDateSettingsPageState extends State<TimeDateSettingsPage> {
  final _settings = AppSettingsService();

  bool _loading = true;
  String? _selectedTimezoneId;
  String? _deviceTimezoneId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      _deviceTimezoneId = tzInfo.identifier;
    } catch (_) {
      _deviceTimezoneId = null;
    }

    _selectedTimezoneId = await _settings.getTimezoneId();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _setTimezone(String? timezoneId) async {
    setState(() => _selectedTimezoneId = timezoneId);
    await _settings.setTimezoneId(timezoneId);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        'Time & Date',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose the timezone used for dates and reminders.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Timezone',
                        child: _loading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ModernDropdownField<String>(
                                    label: 'Timezone',
                                    icon: Icons.schedule_rounded,
                                    value: _selectedTimezoneId,
                                    searchable: true,
                                    searchHint: 'Search timezones...',
                                    displayStringForValue: (tz) =>
                                        RegionTimezoneData.timezoneDisplayName(
                                            tz),
                                    items: RegionTimezoneData.timezones,
                                    onChanged: (value) => _setTimezone(value),
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    label: 'Current selection',
                                    value: _selectedTimezoneId == null
                                        ? 'System default'
                                        : RegionTimezoneData
                                            .timezoneDisplayName(
                                            _selectedTimezoneId!,
                                          ),
                                  ),
                                  const SizedBox(height: 6),
                                  _InfoRow(
                                    label: 'Device timezone',
                                    value: _deviceTimezoneId == null
                                        ? 'Unknown'
                                        : RegionTimezoneData
                                            .timezoneDisplayName(
                                            _deviceTimezoneId!,
                                          ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _selectedTimezoneId == null
                                              ? null
                                              : () => _setTimezone(null),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.7),
                                            side: BorderSide(
                                              color: AppColors.grey300
                                                  .withValues(alpha: 0.9),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          child: const Text(
                                            'Use system default',
                                            style: TextStyle(
                                                color: AppColors.textPrimary),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _deviceTimezoneId == null
                                              ? null
                                              : () => _setTimezone(
                                                    _deviceTimezoneId,
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          child:
                                              const Text('Use device timezone'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
