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

/// Enum untuk status transaksi laundry — mengikuti alur 3 tahap: Diterima -> Selesai -> Sudah Diambil.
enum TransactionStatus {
  diterima,
  selesai,
  sudahDiambil;

  /// Label yang ramah tampilan (UI-friendly).
  String get label {
    switch (this) {
      case TransactionStatus.diterima:
        return 'Diterima';
      case TransactionStatus.selesai:
        return 'Selesai';
      case TransactionStatus.sudahDiambil:
        return 'Sudah Diambil';
    }
  }

  /// Nilai yang disimpan di Firestore.
  String get firestoreValue {
    switch (this) {
      case TransactionStatus.diterima:
        return 'diterima';
      case TransactionStatus.selesai:
        return 'selesai';
      case TransactionStatus.sudahDiambil:
        return 'sudah_diambil';
    }
  }

  /// Konversi dari String Firestore ke enum.
  static TransactionStatus fromString(String value) {
    switch (value) {
      case 'diterima':
        return TransactionStatus.diterima;
      case 'selesai':
        return TransactionStatus.selesai;
      case 'sudah_diambil':
        return TransactionStatus.sudahDiambil;
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

/// Enum untuk status pembayaran transaksi.
enum PaymentStatus {
  belumBayar,
  lunas;

  String get label {
    switch (this) {
      case PaymentStatus.belumBayar:
        return 'Belum Bayar';
      case PaymentStatus.lunas:
        return 'Lunas';
    }
  }

  String get firestoreValue {
    switch (this) {
      case PaymentStatus.belumBayar:
        return 'belum_bayar';
      case PaymentStatus.lunas:
        return 'lunas';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'belum_bayar':
      case 'belumbayar':
      case 'belum bayar':
      case 'unpaid':
        return PaymentStatus.belumBayar;
      case 'lunas':
      case 'paid':
      default:
        return PaymentStatus.lunas;
    }
  }
}

