/// Utility validator untuk form input aplikasi LaundryKu.
class AppValidators {
  AppValidators._();

  /// Validasi nama wajib diisi, minimal 2 karakter.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama pelanggan wajib diisi';
    }
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }

  /// Validasi nomor HP format Indonesia (awalan 08, 62, atau +62, 10-14 digit).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor HP wajib diisi';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');

    // Format regex Indonesia: 08xx, 628xx, +628xx
    final phoneRegex = RegExp(r'^(\+628|628|08)[0-9]{8,12}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Format nomor HP tidak valid (contoh: 081234567890)';
    }

    return null;
  }
}
