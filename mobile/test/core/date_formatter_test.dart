import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatDate formats date into Indonesian format', () {
      final date = DateTime(2026, 11, 6);
      expect(DateFormatter.formatDate(date), '6 Nov 2026');
    });

    test('formatFullDate formats full month name in Indonesian', () {
      final date = DateTime(2026, 11, 6);
      expect(DateFormatter.formatFullDate(date), '6 November 2026');
    });

    test('toIsoUtcString converts DateTime to ISO 8601 UTC format', () {
      final date = DateTime.utc(2026, 11, 6, 14, 30, 0);
      expect(DateFormatter.toIsoUtcString(date), '2026-11-06T14:30:00.000Z');
    });

    test('parseIsoUtcString parses ISO UTC string back to UTC DateTime', () {
      const isoStr = '2026-11-06T14:30:00.000Z';
      final parsed = DateFormatter.parseIsoUtcString(isoStr);
      expect(parsed, isNotNull);
      expect(parsed!.year, 2026);
      expect(parsed.month, 11);
      expect(parsed.day, 6);
      expect(parsed.hour, 14);
      expect(parsed.minute, 30);
      expect(parsed.isUtc, isTrue);
    });
  });
}
