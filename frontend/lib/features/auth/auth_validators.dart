abstract final class AuthValidators {
  static final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email.';
    }
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter your full name.';
    }
    if (name.length < 2) {
      return 'Enter at least two characters.';
    }
    return null;
  }

  static String? organization(String? value) {
    final organization = value?.trim() ?? '';
    if (organization.isEmpty) {
      return 'Please enter your hospital or organization.';
    }
    return null;
  }
}
