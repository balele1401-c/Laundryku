import 'package:intl/intl.dart';

/// Helper formatters untuk mata uang Rupiah & tanggal aplikasi LaundryKu.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('id_ID');

  /// Format angka ke Rupiah (contoh: 7000 -> "Rp 7.000").
  static String rupiah(num value) {
    return _rupiahFormat.format(value);
  }

  /// Format angka murni berpemisah ribuan (contoh: 7000 -> "7.000").
  static String number(num value) {
    return _numberFormat.format(value);
  }

  /// Parse string input Rupiah ke double murni (contoh: "Rp 15.000" -> 15000.0).
  static double parseRupiah(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  /// Format tanggal Indonesia (contoh: "15 Agu 2026").
  static String date(DateTime dateTime) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format tanggal & waktu Indonesia (contoh: "15 Agu 2026, 14:30").
  static String dateTime(DateTime dateTime) {
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final min = dateTime.minute.toString().padLeft(2, '0');
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $hour:$min';
    }
  }

  /// Format tanggal untuk nomor nota (contoh: "20260815").
  static String notaDate(DateTime dateTime) {
    return DateFormat('yyyyMMdd').format(dateTime);
  }
}
