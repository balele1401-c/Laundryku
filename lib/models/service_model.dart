import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class ServiceModel {
  final String id;
  final String namaLayanan;
  final ServiceType tipe;
  final double harga;
  final int estimasiHari;

  const ServiceModel({
    required this.id,
    required this.namaLayanan,
    required this.tipe,
    required this.harga,
    required this.estimasiHari,
  });

  /// Buat instance dari Firestore DocumentSnapshot.
  factory ServiceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ServiceModel.fromMap(doc.data()!, doc.id);
  }

  /// Buat instance dari Map.
  factory ServiceModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return ServiceModel(
      id: id ?? map['id'] as String? ?? '',
      namaLayanan: map['namaLayanan'] as String? ?? '',
      tipe: ServiceType.fromString(map['tipe'] as String? ?? 'kiloan'),
      harga: (map['harga'] as num?)?.toDouble() ?? 0,
      estimasiHari: (map['estimasiHari'] as num?)?.toInt() ?? 1,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'namaLayanan': namaLayanan,
      'tipe': tipe.name,
      'harga': harga,
      'estimasiHari': estimasiHari,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? namaLayanan,
    ServiceType? tipe,
    double? harga,
    int? estimasiHari,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      namaLayanan: namaLayanan ?? this.namaLayanan,
      tipe: tipe ?? this.tipe,
      harga: harga ?? this.harga,
      estimasiHari: estimasiHari ?? this.estimasiHari,
    );
  }

  @override
  String toString() =>
      'ServiceModel(id: $id, nama: $namaLayanan, tipe: ${tipe.label})';
}
