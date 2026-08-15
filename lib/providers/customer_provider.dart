import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customerSub;

  List<CustomerModel> _customers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Constructor ─────────────────────────────────────────────────────

  CustomerProvider() {
    _initCustomerStream();
  }

  @override
  void dispose() {
    _customerSub?.cancel();
    super.dispose();
  }

  // ─── Getters ──────────────────────────────────────────────────────────

  List<CustomerModel> get customers {
    if (_searchQuery.trim().isEmpty) {
      return _customers;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _customers.where((c) {
      final nameMatch = c.nama.toLowerCase().contains(query);
      final phoneMatch = c.noHp.contains(query);
      return nameMatch || phoneMatch;
    }).toList();
  }

  List<CustomerModel> get allCustomers => _customers;
  int get totalCustomers => _customers.length;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Realtime Stream ──────────────────────────────────────────────────

  void _initCustomerStream() {
    _isLoading = true;
    notifyListeners();

    _customerSub = _firestore
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _customers = snapshot.docs
            .map((doc) => CustomerModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('⚠️ Error streaming customers: $error');
        _errorMessage = 'Gagal memuat data pelanggan: ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // ─── CRUD Operations ─────────────────────────────────────────────────

  /// Tambah data pelanggan baru ke Firestore.
  Future<bool> addCustomer({
    required String nama,
    required String noHp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedPhone = _normalizePhoneNumber(noHp);

      // Cek duplikasi nomor HP jika perlu
      final existing = _customers.where((c) => c.noHp == normalizedPhone);
      if (existing.isNotEmpty) {
        _errorMessage = 'Nomor HP sudah terdaftar atas nama ${existing.first.nama}.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newCustomer = CustomerModel(
        id: '',
        nama: nama.trim(),
        noHp: normalizedPhone,
        totalTransaksi: 0,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('customers').add(newCustomer.toMap());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding customer: $e');
      _errorMessage = 'Gagal menambah pelanggan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update data pelanggan yang sudah ada.
  Future<bool> updateCustomer({
    required String id,
    required String nama,
    required String noHp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedPhone = _normalizePhoneNumber(noHp);

      await _firestore.collection('customers').doc(id).update({
        'nama': nama.trim(),
        'noHp': normalizedPhone,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating customer: $e');
      _errorMessage = 'Gagal memperbarui pelanggan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Hapus pelanggan dari Firestore.
  Future<bool> deleteCustomer(String id) async {
    try {
      await _firestore.collection('customers').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting customer: $e');
      _errorMessage = 'Gagal menghapus pelanggan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  /// Standarisasi nomor HP Indonesia ke format '08xxxxxxxxxx'.
  String _normalizePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('+62')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('62')) {
      cleaned = '0${cleaned.substring(2)}';
    }
    return cleaned;
  }
}
