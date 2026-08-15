import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class TransactionModel {
  final String id;
  final String customerId;
  final String customerNama;
  final String nomorNota;
  final String jenisLayanan;
  final ServiceType tipeLayanan;
  final double? berat; // untuk kiloan
  final int? qty; // untuk satuan
  final double hargaSatuan;
  final double totalHarga;
  final TransactionStatus status;
  final DateTime tanggalMasuk;
  final DateTime estimasiSelesai;
  final String createdBy;
  final DateTime? waNotifSentAt; // timestamp saat notif WA berhasil dikirim
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.customerId,
    required this.customerNama,
    required this.nomorNota,
    required this.jenisLayanan,
    required this.tipeLayanan,
    this.berat,
    this.qty,
    required this.hargaSatuan,
    required this.totalHarga,
    required this.status,
    required this.tanggalMasuk,
    required this.estimasiSelesai,
    required this.createdBy,
    this.waNotifSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Buat instance dari Firestore DocumentSnapshot.
  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return TransactionModel.fromMap(doc.data()!, doc.id);
  }

  /// Buat instance dari Map.
  factory TransactionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return TransactionModel(
      id: id ?? map['id'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerNama: map['customerNama'] as String? ?? '',
      nomorNota: map['nomorNota'] as String? ?? '',
      jenisLayanan: map['jenisLayanan'] as String? ?? '',
      tipeLayanan:
          ServiceType.fromString(map['tipeLayanan'] as String? ?? 'kiloan'),
      berat: (map['berat'] as num?)?.toDouble(),
      qty: (map['qty'] as num?)?.toInt(),
      hargaSatuan: (map['hargaSatuan'] as num?)?.toDouble() ?? 0,
      totalHarga: (map['totalHarga'] as num?)?.toDouble() ?? 0,
      status: TransactionStatus.fromString(
        map['status'] as String? ?? 'diterima',
      ),
      tanggalMasuk: _parseTimestamp(map['tanggalMasuk']),
      estimasiSelesai: _parseTimestamp(map['estimasiSelesai']),
      createdBy: map['createdBy'] as String? ?? '',
      waNotifSentAt: map['waNotifSentAt'] != null
          ? _parseTimestamp(map['waNotifSentAt'])
          : null,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerNama': customerNama,
      'nomorNota': nomorNota,
      'jenisLayanan': jenisLayanan,
      'tipeLayanan': tipeLayanan.name,
      'berat': berat,
      'qty': qty,
      'hargaSatuan': hargaSatuan,
      'totalHarga': totalHarga,
      'status': status.firestoreValue,
      'tanggalMasuk': Timestamp.fromDate(tanggalMasuk),
      'estimasiSelesai': Timestamp.fromDate(estimasiSelesai),
      'createdBy': createdBy,
      'waNotifSentAt': waNotifSentAt != null
          ? Timestamp.fromDate(waNotifSentAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? customerId,
    String? customerNama,
    String? nomorNota,
    String? jenisLayanan,
    ServiceType? tipeLayanan,
    double? berat,
    int? qty,
    double? hargaSatuan,
    double? totalHarga,
    TransactionStatus? status,
    DateTime? tanggalMasuk,
    DateTime? estimasiSelesai,
    String? createdBy,
    DateTime? waNotifSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerNama: customerNama ?? this.customerNama,
      nomorNota: nomorNota ?? this.nomorNota,
      jenisLayanan: jenisLayanan ?? this.jenisLayanan,
      tipeLayanan: tipeLayanan ?? this.tipeLayanan,
      berat: berat ?? this.berat,
      qty: qty ?? this.qty,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      totalHarga: totalHarga ?? this.totalHarga,
      status: status ?? this.status,
      tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
      estimasiSelesai: estimasiSelesai ?? this.estimasiSelesai,
      createdBy: createdBy ?? this.createdBy,
      waNotifSentAt: waNotifSentAt ?? this.waNotifSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper: parse Timestamp / int / null ke DateTime.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, nota: $nomorNota, status: ${status.label})';
}
