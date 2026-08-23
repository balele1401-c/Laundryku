import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';
import '../models/enums.dart';
import '../utils/formatters.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _transactionSub;

  List<TransactionModel> _transactions = [];
  TransactionStatus? _filterStatus;
  bool _filterBelumBayarOnly = false;
  bool _filterBelumDiambilOnly = false;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ─── Constructor ─────────────────────────────────────────────────────

  TransactionProvider() {
    _initTransactionStream();
  }

  @override
  void dispose() {
    _transactionSub?.cancel();
    super.dispose();
  }

  // ─── Getters ──────────────────────────────────────────────────────────

  List<TransactionModel> get transactions {
    var list = _transactions;

    // Filter status alur
    if (_filterStatus != null) {
      list = list.where((t) => t.status == _filterStatus).toList();
    }

    // Filter khusus: Belum Bayar
    if (_filterBelumBayarOnly) {
      list = list.where((t) => t.isBelumBayar).toList();
    }

    // Filter khusus: Belum Diambil
    if (_filterBelumDiambilOnly) {
      list = list.where((t) => t.isBelumDiambil).toList();
    }

    // Filter search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((t) {
        final notaMatch = t.nomorNota.toLowerCase().contains(query);
        final nameMatch = t.customerNama.toLowerCase().contains(query);
        final serviceMatch = t.jenisLayanan.toLowerCase().contains(query);
        return notaMatch || nameMatch || serviceMatch;
      }).toList();
    }

    return list;
  }

  List<TransactionModel> get allTransactions => _transactions;
  int get totalTransactions => _transactions.length;
  TransactionStatus? get filterStatus => _filterStatus;
  bool get filterBelumBayarOnly => _filterBelumBayarOnly;
  bool get filterBelumDiambilOnly => _filterBelumDiambilOnly;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Metrics / Stats ─────────────────────────────────────────────────

  /// 5 Transaksi terbaru untuk Dashboard
  List<TransactionModel> get recentTransactions =>
      _transactions.take(5).toList();

  /// Jumlah order aktif (belum selesai)
  int get activeTransactionsCount =>
      _transactions.where((t) => t.status != TransactionStatus.selesai).length;

  /// Jumlah pesanan belum diambil (belum status selesai/sudah diambil)
  int get belumDiambilCount =>
      _transactions.where((t) => t.isBelumDiambil).length;

  /// Jumlah pesanan yang belum dibayar
  int get belumBayarCount =>
      _transactions.where((t) => t.isBelumBayar).length;

  /// Jumlah pesanan selesai/siap diambil tapi belum bayar (perlu perhatian khusus)
  int get attentionRequiredCount =>
      _transactions.where((t) => t.isAttentionRequired).length;

  /// Jumlah pesanan Diterima (antrean)
  int get antreanCount =>
      _transactions.where((t) => t.status == TransactionStatus.diterima).length;

  /// Jumlah pesanan Selesai (siap diambil pelanggan)
  int get selesaiCount =>
      _transactions.where((t) => t.status == TransactionStatus.selesai).length;

  /// Jumlah pesanan Sudah Diambil
  int get sudahDiambilCount =>
      _transactions.where((t) => t.status == TransactionStatus.sudahDiambil).length;

  /// Jumlah transaksi masuk hari ini
  int get todayTransactionsCount {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _transactions
        .where((t) => t.tanggalMasuk.isAfter(todayStart))
        .length;
  }

  /// Total pendapatan hari ini
  double get todayIncome {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _transactions
        .where((t) => t.tanggalMasuk.isAfter(todayStart))
        .fold<double>(0, (runningTotal, item) => runningTotal + item.totalHarga);
  }

  // ─── Realtime Stream ──────────────────────────────────────────────────

  void _initTransactionStream() {
    _isLoading = true;
    notifyListeners();

    _transactionSub = _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _transactions = snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('⚠️ Error streaming transactions: $error');
        _errorMessage = 'Gagal memuat daftar transaksi: ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ─── Filters & Search ─────────────────────────────────────────────────

  void setFilterStatus(TransactionStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterBelumBayar(bool value) {
    _filterBelumBayarOnly = value;
    notifyListeners();
  }

  void toggleFilterBelumBayar() {
    _filterBelumBayarOnly = !_filterBelumBayarOnly;
    notifyListeners();
  }

  void setFilterBelumDiambil(bool value) {
    _filterBelumDiambilOnly = value;
    notifyListeners();
  }

  void toggleFilterBelumDiambil() {
    _filterBelumDiambilOnly = !_filterBelumDiambilOnly;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterStatus = null;
    _filterBelumBayarOnly = false;
    _filterBelumDiambilOnly = false;
    _searchQuery = '';
    notifyListeners();
  }

  // ─── Generate Nomor Nota ──────────────────────────────────────────────

  /// Generate nomor nota format: LDY-YYYYMMDD-XXX (contoh: LDY-20260815-001)
  String generateNomorNota() {
    final now = DateTime.now();
    final dateStr = AppFormatters.notaDate(now);

    final todayCount = _transactions.where((t) {
      return t.nomorNota.startsWith('LDY-$dateStr');
    }).length;

    final nextNumber = (todayCount + 1).toString().padLeft(3, '0');
    final randomSuffix = Random().nextInt(90 + 1) + 10;
    return 'LDY-$dateStr-$nextNumber$randomSuffix';
  }

  // ─── CRUD Operations ─────────────────────────────────────────────────

  /// Buat transaksi baru di Firestore + increment totalTransaksi pelanggan.
  Future<TransactionModel?> createTransaction({
    required String customerId,
    required String customerNama,
    required String jenisLayanan,
    required ServiceType tipeLayanan,
    double? berat,
    int? qty,
    required double hargaSatuan,
    required double totalHarga,
    String metodePembayaran = 'Tunai',
    PaymentStatus statusPembayaran = PaymentStatus.lunas,
    required int estimasiHari,
    required String createdBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final estimasi = now.add(Duration(days: max(1, estimasiHari)));
      final nota = generateNomorNota();

      final newTransaction = TransactionModel(
        id: '',
        customerId: customerId,
        customerNama: customerNama.trim(),
        nomorNota: nota,
        jenisLayanan: jenisLayanan,
        tipeLayanan: tipeLayanan,
        berat: berat,
        qty: qty,
        hargaSatuan: hargaSatuan,
        totalHarga: totalHarga,
        metodePembayaran: metodePembayaran,
        statusPembayaran: statusPembayaran,
        status: TransactionStatus.diterima,
        tanggalMasuk: now,
        estimasiSelesai: estimasi,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Simpan transaksi
      final docRef =
          await _firestore.collection('transactions').add(newTransaction.toMap());

      // 2. Increment totalTransaksi pada dokumen customer jika customerId valid
      if (customerId.isNotEmpty) {
        try {
          await _firestore.collection('customers').doc(customerId).update({
            'totalTransaksi': FieldValue.increment(1),
          });
        } catch (custErr) {
          debugPrint('⚠️ Gagal increment customer totalTransaksi: $custErr');
        }
      }

      _isLoading = false;
      notifyListeners();
      return newTransaction.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ Error creating transaction: $e');
      _errorMessage = 'Gagal membuat transaksi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update status transaksi (Diterima -> Proses Cuci -> Proses Setrika -> Siap Diambil -> Selesai).
  Future<bool> updateStatus(
    String transactionId,
    TransactionStatus newStatus, {
    DateTime? waNotifSentAt,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': newStatus.firestoreValue,
        'updatedAt': Timestamp.now(),
      };

      if (waNotifSentAt != null) {
        updateData['waNotifSentAt'] = Timestamp.fromDate(waNotifSentAt);
      }

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updateData);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating status: $e');
      _errorMessage = 'Gagal memperbarui status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update status pembayaran transaksi (Lunas / Belum Bayar).
  Future<bool> updatePaymentStatus(
    String transactionId,
    PaymentStatus newStatus,
  ) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'statusPembayaran': newStatus.firestoreValue,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error updating payment status: $e');
      _errorMessage = 'Gagal memperbarui status pembayaran: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Update detail transaksi yang diedit (layanan, berat/qty, metode & status pembayaran, audit trail).
  Future<bool> updateTransactionDetails({
    required String transactionId,
    required String jenisLayanan,
    required ServiceType tipeLayanan,
    double? berat,
    int? qty,
    required double hargaSatuan,
    required double totalHarga,
    required String metodePembayaran,
    required PaymentStatus statusPembayaran,
    required String editedBy,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('transactions').doc(transactionId).update({
        'jenisLayanan': jenisLayanan,
        'tipeLayanan': tipeLayanan.name,
        'berat': berat,
        'qty': qty,
        'hargaSatuan': hargaSatuan,
        'totalHarga': totalHarga,
        'metodePembayaran': metodePembayaran,
        'statusPembayaran': statusPembayaran.firestoreValue,
        'lastEditedAt': Timestamp.fromDate(now),
        'editedBy': editedBy,
        'updatedAt': Timestamp.fromDate(now),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error updating transaction details: $e');
      _errorMessage = 'Gagal memperbarui transaksi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Tandai bahwa notifikasi WhatsApp berhasil dikirim ke pelanggan.
  Future<bool> markWaNotifSent(
    String transactionId,
    DateTime sentAt,
  ) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'waNotifSentAt': Timestamp.fromDate(sentAt),
      });
      return true;
    } catch (e) {
      debugPrint('⚠️ Gagal update waNotifSentAt: $e');
      return false;
    }
  }

  /// Hapus transaksi dari Firestore.
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting transaction: $e');
      _errorMessage = 'Gagal menghapus transaksi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
