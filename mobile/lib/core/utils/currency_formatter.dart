import 'package:intl/intl.dart';

/// Utility for Indonesian Rupiah Currency Formatting
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Formats numeric or string amount to Indonesian Rupiah standard
  /// Example: 50000 -> "Rp 50.000"
  static String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';

    num parsedAmount = 0;
    if (amount is num) {
      parsedAmount = amount;
    } else if (amount is String) {
      // Remove any non-numeric characters except minus and period
      final cleanStr = amount.replaceAll(RegExp(r'[^0-9.-]'), '');
      parsedAmount = num.tryParse(cleanStr) ?? 0;
    }

    return _rupiahFormatter.format(parsedAmount);
  }

  /// Parses Rupiah string back to double
  /// Example: "Rp 50.000" -> 50000.0
  static double parseRupiah(String text) {
    if (text.isEmpty) return 0.0;
    final cleanStr = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleanStr) ?? 0.0;
  }

  /// Compact representation for charts or small badges
  /// Example: 1500000 -> "Rp 1,5 jt", 50000 -> "Rp 50 rb"
  static String formatCompactRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';

    num parsedAmount = 0;
    if (amount is num) {
      parsedAmount = amount;
    } else if (amount is String) {
      final cleanStr = amount.replaceAll(RegExp(r'[^0-9.-]'), '');
      parsedAmount = num.tryParse(cleanStr) ?? 0;
    }

    final isNegative = parsedAmount < 0;
    final absAmount = parsedAmount.abs();

    String result;
    if (absAmount >= 1000000000) {
      final val = absAmount / 1000000000;
      result = 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} M';
    } else if (absAmount >= 1000000) {
      final val = absAmount / 1000000;
      result = 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} jt';
    } else if (absAmount >= 1000) {
      final val = absAmount / 1000;
      result = 'Rp ${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} rb';
    } else {
      result = 'Rp $absAmount';
    }

    return isNegative ? '-$result' : result;
  }
}
