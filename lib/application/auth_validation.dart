enum AuthInputError { required, invalidEmail, shortPassword, passwordMismatch }

abstract final class AuthValidation {
  static AuthInputError? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return AuthInputError.required;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return AuthInputError.invalidEmail;
    }
    return null;
  }

  static AuthInputError? password(String value, {required bool registering}) {
    if (value.isEmpty) return AuthInputError.required;
    // UI policy only; the future authentication service must enforce its policy.
    if (registering && value.runes.length < 6) {
      return AuthInputError.shortPassword;
    }
    return null;
  }

  static AuthInputError? confirmation(String value, String password) {
    if (value.isEmpty) return AuthInputError.required;
    return value == password ? null : AuthInputError.passwordMismatch;
  }
}
