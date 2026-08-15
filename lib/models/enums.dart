/// Enum untuk role pengguna aplikasi.
enum UserRole {
  owner,
  kasir;

  /// Konversi dari String (Firestore) ke enum.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.kasir,
    );
  }
}

/// Enum untuk status transaksi laundry — mengikuti alur proses.
enum TransactionStatus {
  diterima,
  prosesCuci,
  prosesSetrika,
  siapDiambil,
  selesai;

  /// Label yang ramah tampilan (UI-friendly).
  String get label {
    switch (this) {
      case TransactionStatus.diterima:
        return 'Diterima';
      case TransactionStatus.prosesCuci:
        return 'Proses Cuci';
      case TransactionStatus.prosesSetrika:
        return 'Proses Setrika';
      case TransactionStatus.siapDiambil:
        return 'Siap Diambil';
      case TransactionStatus.selesai:
        return 'Selesai';
    }
  }

  /// Nilai yang disimpan di Firestore.
  String get firestoreValue {
    switch (this) {
      case TransactionStatus.diterima:
        return 'diterima';
      case TransactionStatus.prosesCuci:
        return 'proses_cuci';
      case TransactionStatus.prosesSetrika:
        return 'proses_setrika';
      case TransactionStatus.siapDiambil:
        return 'siap_diambil';
      case TransactionStatus.selesai:
        return 'selesai';
    }
  }

  /// Konversi dari String Firestore ke enum.
  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'diterima':
        return TransactionStatus.diterima;
      case 'proses_cuci':
        return TransactionStatus.prosesCuci;
      case 'proses_setrika':
        return TransactionStatus.prosesSetrika;
      case 'siap_diambil':
        return TransactionStatus.siapDiambil;
      case 'selesai':
        return TransactionStatus.selesai;
      default:
        return TransactionStatus.diterima;
    }
  }
}

/// Enum untuk tipe layanan.
enum ServiceType {
  kiloan,
  satuan;

  String get label {
    switch (this) {
      case ServiceType.kiloan:
        return 'Kiloan';
      case ServiceType.satuan:
        return 'Satuan';
    }
  }

  static ServiceType fromString(String value) {
    return ServiceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ServiceType.kiloan,
    );
  }
}
