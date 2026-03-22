/// Form validation utilities
class Validators {
  const Validators._();

  static const String passwordHelperText =
      'Use at least 8 characters with uppercase, lowercase, number, and special character.';

  static const String passwordRequirementError =
      'Password must be at least 8 characters and include uppercase, lowercase, number, and special character';

  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Improved RFC-like email regex: allows + in local-part and does not limit TLD length.
    // This is not the full RFC 5322 grammar (which is enormous), but it's a widely-used
    // practical pattern that accepts common valid addresses and rejects obvious invalid ones.
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!isValidPassword(value)) {
      return passwordRequirementError;
    }

    return null;
  }

  /// Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  /// Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Allow optional leading +, digits, spaces, parentheses and hyphens; at least 10 characters, must match entire string
    final phoneRegex = RegExp(r'^\+?[\d\s()\-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // Clean URL regex: supports http/https, optional www, domain labels and path/query
    // Note: The TLD length was changed from {1,6} to {1,63} to match the DNS specification,
    // which allows TLDs up to 63 characters. This relaxes the previous validation and may
    // accept longer TLDs than before. See RFC 1035 section 2.3.1 for details.
    final urlRegex = RegExp(
      r'^https?://(www\.)?[-A-Za-z0-9@:%._+~#=]{1,256}\.[A-Za-z0-9()]{1,63}\b([-A-Za-z0-9()@:%_+.~#?&/=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters long';
    }

    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    if (value.length > maxLength) {
      return '${fieldName ?? 'This field'} must be no more than $maxLength characters long';
    }

    return null;
  }

  /// Numeric validation
  static String? numeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'This field'} must be a valid number';
    }

    return null;
  }

  /// Integer validation
  static String? integer(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    if (int.tryParse(value) == null) {
      return '${fieldName ?? 'This field'} must be a valid integer';
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Check if email is valid (returns boolean)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Check if password is valid (returns boolean)
  static bool isValidPassword(String password) {
    return hasMinPasswordLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasDigit(password) &&
        hasSpecialCharacter(password);
  }

  static bool hasMinPasswordLength(String password) {
    return password.length >= 8;
  }

  static bool hasUppercase(String password) {
    return RegExp(r'[A-Z]').hasMatch(password);
  }

  static bool hasLowercase(String password) {
    return RegExp(r'[a-z]').hasMatch(password);
  }

  static bool hasDigit(String password) {
    return RegExp(r'\d').hasMatch(password);
  }

  static bool hasSpecialCharacter(String password) {
    return RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);
  }
}
