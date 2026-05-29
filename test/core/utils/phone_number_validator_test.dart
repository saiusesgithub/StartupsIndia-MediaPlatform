import 'package:flutter_test/flutter_test.dart';
import 'package:startups_india_media_platform/core/utils/phone_number_validator.dart';

void main() {
  group('validatePhoneNumber', () {
    test('accepts a ten-digit Indian local number', () {
      expect(validatePhoneNumber('98765 43210'), isNull);
    });

    test('accepts an Indian number with the +91 country code', () {
      expect(validatePhoneNumber('+91 98765 43210'), isNull);
    });

    test('rejects Indian local numbers that are not ten digits', () {
      expect(validatePhoneNumber('999999999999999999'), isNotNull);
    });

    test('accepts a plausible international E.164 number', () {
      expect(validatePhoneNumber('+14155552671'), isNull);
    });

    test('rejects letters and missing values', () {
      expect(validatePhoneNumber('phone123'), isNotNull);
      expect(validatePhoneNumber(''), isNotNull);
    });
  });
}
