import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String nama;
  final String noHp;
  final int totalTransaksi;
  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.nama,
    required this.noHp,
    this.totalTransaksi = 0,
    required this.createdAt,
  });

  /// Buat instance dari Firestore DocumentSnapshot.
  factory CustomerModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CustomerModel.fromMap(doc.data()!, doc.id);
  }

  /// Buat instance dari Map.
  factory CustomerModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return CustomerModel(
      id: id ?? map['id'] as String? ?? '',
      nama: map['nama'] as String? ?? '',
      noHp: map['noHp'] as String? ?? '',
      totalTransaksi: (map['totalTransaksi'] as num?)?.toInt() ?? 0,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'noHp': noHp,
      'totalTransaksi': totalTransaksi,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? nama,
    String? noHp,
    int? totalTransaksi,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      noHp: noHp ?? this.noHp,
      totalTransaksi: totalTransaksi ?? this.totalTransaksi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Helper: parse Timestamp / int / null ke DateTime.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  @override
  String toString() => 'CustomerModel(id: $id, nama: $nama, noHp: $noHp)';
}
