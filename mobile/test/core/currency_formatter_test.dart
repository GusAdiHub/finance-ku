import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formatRupiah formats integer amounts correctly', () {
      expect(CurrencyFormatter.formatRupiah(50000), 'Rp 50.000');
      expect(CurrencyFormatter.formatRupiah(0), 'Rp 0');
      expect(CurrencyFormatter.formatRupiah(1000000), 'Rp 1.000.000');
    });

    test('formatRupiah handles String and Decimal-like strings', () {
      expect(CurrencyFormatter.formatRupiah('45000'), 'Rp 45.000');
      expect(CurrencyFormatter.formatRupiah('45000.00'), 'Rp 45.000');
      expect(CurrencyFormatter.formatRupiah(null), 'Rp 0');
      expect(CurrencyFormatter.formatRupiah(''), 'Rp 0');
    });

    test('parseRupiah parses formatted string back to double', () {
      expect(CurrencyFormatter.parseRupiah('Rp 50.000'), 50000.0);
      expect(CurrencyFormatter.parseRupiah('Rp 1.500.000'), 1500000.0);
      expect(CurrencyFormatter.parseRupiah(''), 0.0);
    });

    test('formatCompactRupiah produces human-friendly representations', () {
      expect(CurrencyFormatter.formatCompactRupiah(50000), 'Rp 50 rb');
      expect(CurrencyFormatter.formatCompactRupiah(1500000), 'Rp 1,5 jt');
      expect(CurrencyFormatter.formatCompactRupiah(2000000000), 'Rp 2 M');
      expect(CurrencyFormatter.formatCompactRupiah(500), 'Rp 500');
    });
  });
}
