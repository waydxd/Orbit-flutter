import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view/profile_registration_page.dart';
import '../view_model/auth_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../../utils/validators.dart';
import '../../../utils/constants.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _passwordValue => _passwordController.text;

  bool get _hasStartedTypingPassword => _passwordValue.isNotEmpty;

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.clearError();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileRegistrationPage(
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        return Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: Constants.fontSizeL,
                        fontWeight: Constants.fontWeightBold,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: Constants.spacingL),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!Validators.isValidEmail(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Constants.spacingM),
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
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
                    ),
                    validator: _validateUsername,
                  ),
                  const SizedBox(height: Constants.spacingM),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!Validators.isValidPassword(value)) {
                        return Validators.passwordRequirementError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Constants.spacingS),
                  _PasswordRequirementsCard(
                    hasStartedTyping: _hasStartedTypingPassword,
                    hasMinLength:
                        Validators.hasMinPasswordLength(_passwordValue),
                    hasUppercase: Validators.hasUppercase(_passwordValue),
                    hasLowercase: Validators.hasLowercase(_passwordValue),
                    hasNumber: Validators.hasDigit(_passwordValue),
                    hasSpecialCharacter:
                        Validators.hasSpecialCharacter(_passwordValue),
                  ),
                  const SizedBox(height: Constants.spacingM),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (authViewModel.error != null) ...[
                    const SizedBox(height: Constants.spacingM),
                    Container(
                      padding: const EdgeInsets.all(Constants.spacingS),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Constants.radiusM),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: Constants.iconS,
                          ),
                          const SizedBox(width: Constants.spacingS),
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
                          borderRadius:
                              BorderRadius.circular(Constants.radiusM),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: Constants.buttonHeight,
                        ),
                      ),
                      onPressed: authViewModel.isLoading ? null : _submit,
                      child: authViewModel.isLoading
                          ? const SizedBox(
                              height: Constants.iconS,
                              width: Constants.iconS,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: Constants.fontSizeM,
                                color: Colors.white,
                                fontWeight: Constants.fontWeightSemiBold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: Constants.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: Constants.fontSizeXS,
                          fontWeight: Constants.fontWeightNormal,
                          color: Color(0xFF787878),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: Constants.fontSizeXS,
                            fontWeight: Constants.fontWeightSemiBold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
    return null;
  }
}

class _PasswordRequirementsCard extends StatelessWidget {
  final bool hasStartedTyping;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialCharacter;

  const _PasswordRequirementsCard({
    required this.hasStartedTyping,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Constants.spacingS),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Constants.radiusM),
        border: Border.all(
          color: AppColors.grey300.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must include:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: Constants.spacingS),
          _RequirementRow(
            label: 'At least 8 characters',
            isMet: hasMinLength,
            showReminder: hasStartedTyping,
          ),
          _RequirementRow(
            label: 'An uppercase letter',
            isMet: hasUppercase,
            showReminder: hasStartedTyping,
          ),
          _RequirementRow(
            label: 'A lowercase letter',
            isMet: hasLowercase,
            showReminder: hasStartedTyping,
          ),
          _RequirementRow(
            label: 'A number',
            isMet: hasNumber,
            showReminder: hasStartedTyping,
          ),
          _RequirementRow(
            label: 'A special character',
            isMet: hasSpecialCharacter,
            showReminder: hasStartedTyping,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool isMet;
  final bool showReminder;

  const _RequirementRow({
    required this.label,
    required this.isMet,
    required this.showReminder,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isMet
        ? AppColors.success
        : showReminder
            ? AppColors.error
            : AppColors.textSecondary;

    final IconData icon = isMet
        ? Icons.check_circle_rounded
        : showReminder
            ? Icons.radio_button_unchecked_rounded
            : Icons.info_outline_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: Constants.spacingXS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Constants.spacingS),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
