import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/themes/app_colors.dart';
import '../../../core/services/app_settings_service.dart';
import '../../../modules/location_tracking/services/location_tracking_service.dart';

class GpsSettingsPage extends StatefulWidget {
  const GpsSettingsPage({super.key});

  @override
  State<GpsSettingsPage> createState() => _GpsSettingsPageState();
}

class _GpsSettingsPageState extends State<GpsSettingsPage> {
  final _settings = AppSettingsService();
  final _locationTracking = LocationTrackingService();

  bool _loading = true;
  bool _trackingEnabled = false;

  bool _serviceEnabled = false;
  LocationPermission _permission = LocationPermission.denied;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _trackingEnabled = await _settings.getGpsTrackingEnabled();
    await _refreshLocationStatus();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _refreshLocationStatus() async {
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _permission = await Geolocator.checkPermission();
  }

  Future<void> _setTrackingEnabled(bool enabled) async {
    setState(() => _trackingEnabled = enabled);
    await _settings.setGpsTrackingEnabled(enabled);

    if (!enabled) {
      // Stop the background service loop.
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      await _refreshLocationStatus();
      if (!mounted) return;
      setState(() {});
      return;
    }

    // Enabled: request permissions and start/ensure service.
    if (!mounted) return;
    await _locationTracking.initialize(context);
    await _refreshLocationStatus();
    if (!mounted) return;
    setState(() {});
  }

  String _permissionLabel(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.denied => 'Denied',
      LocationPermission.deniedForever => 'Denied (permanently)',
      LocationPermission.whileInUse => 'While in use',
      LocationPermission.always => 'Always',
      LocationPermission.unableToDetermine => 'Unable to determine',
    };
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
                  'GPS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage location tracking used for stay-point detection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Location tracking',
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
                              title: 'Enable location tracking',
                              subtitle:
                                  'Runs in the background to detect your frequent places.',
                              value: _trackingEnabled,
                              onChanged: _setTrackingEnabled,
                            ),
                            const _DividerLine(),
                            _StatusRow(
                              label: 'Location services',
                              value: _serviceEnabled ? 'On' : 'Off',
                              valueColor: _serviceEnabled
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(height: 8),
                            _StatusRow(
                              label: 'Permission',
                              value: _permissionLabel(_permission),
                              valueColor:
                                  (_permission == LocationPermission.always ||
                                          _permission ==
                                              LocationPermission.whileInUse)
                                      ? AppColors.success
                                      : AppColors.error,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await _refreshLocationStatus();
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.7),
                                      side: BorderSide(
                                        color: AppColors.grey300
                                            .withValues(alpha: 0.9),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text(
                                      'Refresh status',
                                      style: TextStyle(
                                          color: AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Takes user to system settings; useful for deniedForever.
                                      await openAppSettings();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Open settings'),
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

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

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
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
