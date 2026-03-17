import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/view_model/auth_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/region_timezone_data.dart';
import '../../../utils/validators.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedRegion;
  String? _selectedTimezone;
  String? _lastSyncedSignature;

  static const Map<String, String> _genderLabels = {
    'male': 'Male',
    'female': 'Female',
    'non-binary': 'Non-binary',
    'prefer_not_to_say': 'Prefer not to say',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _signatureForUser(UserModel user) => user.toJson().toString();

  void _syncFromUser(UserModel user) {
    final signature = _signatureForUser(user);
    if (_lastSyncedSignature == signature) return;

    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _usernameController.text = user.username ?? '';
    _selectedRegion = user.region;
    _selectedTimezone = user.timezone;
    _selectedGender = user.gender;
    _birthDate = user.birthDate;
    _lastSyncedSignature = signature;
  }

  String _initialsForUser(UserModel? user) {
    final source = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName
        : (user?.email ?? 'U');
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 20);
    DateTime tempDate = initialDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('Cancel'),
                      ),
                      Expanded(
                        child: Text(
                          'Select birthday',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(tempDate),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: DateTime(now.year - 150),
                      maximumDate: DateTime(now.year - 13),
                      use24hFormat: true,
                      onDateTimeChanged: (value) {
                        tempDate = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.updateProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      username: _usernameController.text,
      region: _selectedRegion ?? '',
      timezone: _selectedTimezone ?? '',
      gender: _selectedGender ?? '',
      birthDate: _birthDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final user = authViewModel.currentUser;
        if (user != null) {
          _syncFromUser(user);
        }

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
              child: authViewModel.isLoading && user == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
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
                          const SizedBox(height: 20),
                          _ProfileHeaderCard(
                            initials: _initialsForUser(user),
                            title: user?.displayName ?? 'Your profile',
                            subtitle: user?.email ?? 'Signed in account',
                            isVerified: user?.emailVerified ?? false,
                          ),
                          if (authViewModel.error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: authViewModel.error!),
                          ],
                          const SizedBox(height: 18),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionCard(
                                  title: 'Basic information',
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _firstNameController,
                                              label: 'First name',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildTextField(
                                              controller: _lastNameController,
                                              label: 'Last name',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      _buildTextField(
                                        controller: _usernameController,
                                        label: 'Username',
                                        validator: _validateUsername,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildReadOnlyField(
                                        label: 'Email',
                                        value: user?.email ?? '',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _SectionCard(
                                  title: 'Preferences',
                                  child: Column(
                                    children: [
                                      ModernDropdownField<String>(
                                        label: 'Region',
                                        icon: Icons.public_rounded,
                                        value: _selectedRegion,
                                        searchable: true,
                                        searchHint: 'Search countries...',
                                        displayStringForValue: (code) =>
                                            RegionTimezoneData
                                                .regionDisplayName(code),
                                        items: RegionTimezoneData.regions.keys
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedRegion = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      ModernDropdownField<String>(
                                        label: 'Timezone',
                                        icon: Icons.schedule_rounded,
                                        value: _selectedTimezone,
                                        searchable: true,
                                        searchHint: 'Search timezones...',
                                        displayStringForValue: (tz) =>
                                            RegionTimezoneData
                                                .timezoneDisplayName(tz),
                                        items: RegionTimezoneData.timezones,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedTimezone = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      ModernDropdownField<String>(
                                        label: 'Gender',
                                        icon: Icons.person_outline_rounded,
                                        value: _selectedGender,
                                        displayStringForValue: (key) =>
                                            _genderLabels[key] ?? key,
                                        items: _genderLabels.keys.toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedGender = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _BirthDateField(
                                        birthDate: _birthDate,
                                        onPickDate: _pickBirthDate,
                                        onClear: _birthDate == null
                                            ? null
                                            : () {
                                                setState(() {
                                                  _birthDate = null;
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  authViewModel.isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: authViewModel.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Save profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: _inputDecoration(label: label, hintText: hintText),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: _inputDecoration(label: label),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  String? _validateUsername(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Username is required';
    }
    if (trimmed.length < 3 || trimmed.length > 50) {
      return 'Username must be between 3 and 50 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return 'Use only letters, numbers, underscores, and hyphens';
    }
    if (RegExp(r'[_-]{2,}').hasMatch(trimmed)) {
      return 'Username cannot contain consecutive underscores or hyphens';
    }
    return Validators.maxLength(trimmed, 50, 'Username');
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String initials;
  final String title;
  final String subtitle;
  final bool isVerified;

  const _ProfileHeaderCard({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8E86FF), Color(0xFF6B63F6)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (isVerified) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Email verified',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BirthDateField extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onPickDate;
  final VoidCallback? onClear;

  const _BirthDateField({
    required this.birthDate,
    required this.onPickDate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = birthDate != null;
    final displayText =
        hasValue ? DateFormat('MMM d, yyyy').format(birthDate!) : 'Birth date';

    return GestureDetector(
      onTap: onPickDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: hasValue ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasValue) ...[
                    const Text(
                      'Birth date',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    displayText,
                    style: TextStyle(
                      color:
                          hasValue ? AppColors.textPrimary : AppColors.grey400,
                      fontSize: hasValue ? 14 : 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.grey100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.grey400,
                    size: 16,
                  ),
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.grey400,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
