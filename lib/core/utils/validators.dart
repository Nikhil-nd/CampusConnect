class Validators {
  Validators._();

  static bool isCollegeEmail(String email, String domain) {
    final String normalized = email.trim().toLowerCase();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(normalized) &&
        normalized.endsWith('@$domain');
  }

  static bool isCollegeEmailInDomains(String email, List<String> domains) {
    final String normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(normalized)) {
      return false;
    }

    for (final String domain in domains) {
      if (normalized.endsWith('@${domain.toLowerCase()}')) {
        return true;
      }
    }

    return false;
  }

  static String? requiredText(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Value'}) {
    final double? parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed < 0) {
      return '$field must be a positive number';
    }
    return null;
  }
}
