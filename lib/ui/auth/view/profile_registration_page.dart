import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../view_model/auth_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/widgets/modern_dropdown.dart';
import '../../../utils/constants.dart';

class ProfileRegistrationPage extends StatefulWidget {
  final String email;
  final String username;
  final String password;
  final String confirmPassword;

  const ProfileRegistrationPage({
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    super.key,
  });

  @override
  State<ProfileRegistrationPage> createState() =>
      _ProfileRegistrationPageState();
}

class _ProfileRegistrationPageState extends State<ProfileRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;
  String _detectedRegion = '';
  String _detectedTimezone = '';

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
      if (mounted) {
        context.read<AuthViewModel>().clearError();
      }
    });
    _loadDeviceProfileDefaults();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceProfileDefaults() async {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    String timezone = '';

    try {
      timezone = await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      timezone = '';
    }

    if (!mounted) return;

    setState(() {
      _detectedRegion = locale.countryCode ?? '';
      _detectedTimezone = timezone;
    });
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
                        child: const Text('Done'),
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

  Future<void> _completeRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.completeRegistration(
      email: widget.email,
      username: widget.username,
      password: widget.password,
      confirmPassword: widget.confirmPassword,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      region: _detectedRegion,
      timezone: _detectedTimezone,
      gender: _selectedGender ?? '',
      birthDate: _birthDate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFCDC9F1),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAFFFE), Color(0xFFCDC9F1)],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(Constants.spacingM),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Constants.spacingL,
                              vertical: Constants.spacingXL,
                            ),
                            decoration: ShapeDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Constants.radiusXXL),
                              ),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x3318303F),
                                  blurRadius: Constants.shadowBlurRadius,
                                  offset: Offset(
                                    Constants.shadowOffset,
                                    Constants.shadowOffset,
                                  ),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 22,
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: Constants.spacingM),
                                  const Text(
                                    'Complete Your Profile',
                                    style: TextStyle(
                                      fontSize: Constants.fontSizeL,
                                      fontWeight: Constants.fontWeightBold,
                                      fontFamily: 'Poppins',
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: Constants.spacingS),
                                  Text(
                                    'Finish setting up your profile. Region and timezone will be detected automatically from your device.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                  ),
                                  const SizedBox(height: Constants.spacingL),
                                  _buildTextField(
                                    controller: _firstNameController,
                                    label: 'First name',
                                  ),
                                  const SizedBox(height: Constants.spacingM),
                                  _buildTextField(
                                    controller: _lastNameController,
                                    label: 'Last name',
                                  ),
                                  const SizedBox(height: Constants.spacingM),
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
                                  const SizedBox(height: Constants.spacingM),
                                  _BirthDateCard(
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
                                  if (authViewModel.error != null) ...[
                                    const SizedBox(height: Constants.spacingM),
                                    Container(
                                      padding: const EdgeInsets.all(
                                          Constants.spacingS),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            Constants.radiusM),
                                        border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                            size: Constants.iconS,
                                          ),
                                          const SizedBox(
                                              width: Constants.spacingS),
                                          Expanded(
                                            child: Text(
                                              authViewModel.error!,
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontSize: Constants.fontSizeS,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: Constants.spacingL),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              Constants.radiusM),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: Constants.buttonHeight,
                                        ),
                                      ),
                                      onPressed: authViewModel.isLoading
                                          ? null
                                          : _completeRegistration,
                                      child: authViewModel.isLoading
                                          ? const SizedBox(
                                              height: Constants.iconS,
                                              width: Constants.iconS,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: Constants.fontSizeM,
                                                color: Colors.white,
                                                fontWeight: Constants
                                                    .fontWeightSemiBold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    String? hintText,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      readOnly: readOnly,
      validator: validator,
      decoration: _inputDecoration(label: label, hintText: hintText),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.radiusL),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Constants.radiusL),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

class _BirthDateCard extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onPickDate;
  final VoidCallback? onClear;

  const _BirthDateCard({
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
