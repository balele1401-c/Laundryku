import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_model.dart';
import '../models/enums.dart';

class ServiceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _serviceSub;

  List<ServiceModel> _services = [];
  ServiceType? _filterType;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Constructor ─────────────────────────────────────────────────────

  ServiceProvider() {
    _initServiceStream();
  }

  @override
  void dispose() {
    _serviceSub?.cancel();
    super.dispose();
  }

  // ─── Getters ──────────────────────────────────────────────────────────

  List<ServiceModel> get services {
    if (_filterType == null) {
      return _services;
    }
    return _services.where((s) => s.tipe == _filterType).toList();
  }

  List<ServiceModel> get allServices => _services;
  int get totalServices => _services.length;
  ServiceType? get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Realtime Stream ──────────────────────────────────────────────────

  void _initServiceStream() {
    _isLoading = true;
    notifyListeners();

    _serviceSub = _firestore.collection('services').snapshots().listen(
      (snapshot) {
        _services = snapshot.docs
            .map((doc) => ServiceModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('⚠️ Error streaming services: $error');
        _errorMessage = 'Gagal memuat katalog layanan: ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ─── Filter ───────────────────────────────────────────────────────────

  void setFilterType(ServiceType? type) {
    _filterType = type;
    notifyListeners();
  }

  // ─── CRUD Operations ─────────────────────────────────────────────────

  /// Tambah layanan baru ke katalog.
  Future<bool> addService({
    required String namaLayanan,
    required ServiceType tipe,
    required double harga,
    required int estimasiHari,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newService = ServiceModel(
        id: '',
        namaLayanan: namaLayanan.trim(),
        tipe: tipe,
        harga: harga,
        estimasiHari: estimasiHari,
      );

      await _firestore.collection('services').add(newService.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding service: $e');
      _errorMessage = 'Gagal menambah layanan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update layanan yang sudah ada.
  Future<bool> updateService({
    required String id,
    required String namaLayanan,
    required ServiceType tipe,
    required double harga,
    required int estimasiHari,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('services').doc(id).update({
        'namaLayanan': namaLayanan.trim(),
        'tipe': tipe.name,
        'harga': harga,
        'estimasiHari': estimasiHari,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating service: $e');
      _errorMessage = 'Gagal memperbarui layanan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus layanan dari Firestore.
  Future<bool> deleteService(String id) async {
    try {
      await _firestore.collection('services').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting service: $e');
      _errorMessage = 'Gagal menghapus layanan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
