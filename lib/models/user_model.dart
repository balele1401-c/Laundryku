import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class UserModel {
  final String uid;
  final String nama;
  final UserRole role;
  final String laundryId;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.role,
    required this.laundryId,
  });

  /// Buat instance dari Firestore DocumentSnapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  /// Buat instance dari Map (generic, bisa untuk testing juga).
  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserModel(
      uid: id ?? map['uid'] as String? ?? '',
      nama: map['nama'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String? ?? 'kasir'),
      laundryId: map['laundryId'] as String? ?? '',
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'role': role.name,
      'laundryId': laundryId,
    };
  }

  UserModel copyWith({
    String? uid,
    String? nama,
    UserRole? role,
    String? laundryId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      role: role ?? this.role,
      laundryId: laundryId ?? this.laundryId,
    );
  }

  @override
  String toString() => 'UserModel(uid: $uid, nama: $nama, role: ${role.name})';
}
