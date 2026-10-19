import 'package:intl/intl.dart';

class AppUtils {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String todayIso() {
    return DateTime.now().toIso8601String().substring(0, 10);
  }

  // DIPERBAIKI: menerima 2 DateTime, bukan lagi String filter
  static String filterLabel(DateTime start, DateTime end) {
    final startStr = DateFormat('dd MMM', 'id_ID').format(start);
    final endStr = DateFormat('dd MMM yyyy', 'id_ID').format(end);
    return '$startStr – $endStr';
  }

  // Helper format tanggal untuk display di tombol picker
  static String formatDateDisplay(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }
}