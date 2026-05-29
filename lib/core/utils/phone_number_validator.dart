String? validatePhoneNumber(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Phone number is required';

  final normalized = text.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (!RegExp(r'^\+?\d+$').hasMatch(normalized)) {
    return 'Enter a valid phone number';
  }

  final digits = normalized.replaceFirst('+', '');
  if (normalized.startsWith('+91')) {
    return digits.length == 12
        ? null
        : 'Enter a valid 10-digit Indian phone number';
  }
  if (!normalized.startsWith('+')) {
    return digits.length == 10 ? null : 'Enter a valid 10-digit phone number';
  }
  if (digits.length < 8 || digits.length > 15) {
    return 'Enter a valid international phone number';
  }
  return null;
}
