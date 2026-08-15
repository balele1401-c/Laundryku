import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/customer_model.dart';
import '../models/service_model.dart';
import '../models/transaction_model.dart';

/// Hasil eksekusi seeder demo data.
class DemoSeedResult {
  final int servicesAdded;
  final int customersAdded;
  final int transactionsAdded;
  final bool isSuccess;
  final String message;

  const DemoSeedResult({
    required this.servicesAdded,
    required this.customersAdded,
    required this.transactionsAdded,
    required this.isSuccess,
    required this.message,
  });
}

/// Seeder demo data untuk keperluan presentasi & demo ke calon klien laundry.
/// Script ini HANYA dijalankan secara manual (misal lewat tombol demo di Owner Dashboard).
class DemoDataSeeder {
  DemoDataSeeder._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Jalankan seeding data demo ke Firestore (Layanan, Pelanggan, Transaksi).
  static Future<DemoSeedResult> seedDemoData({
    String createdByName = 'Owner Demo',
  }) async {
    try {
      debugPrint('🌱 Memulai proses seeding data demo LaundryKu...');
      final now = DateTime.now();

      // ── 1. Seed Katalog Layanan ─────────────────────────────────────
      final servicesCollection = _firestore.collection('services');

      int servicesCount = 0;
      final List<ServiceModel> defaultServices = [
        const ServiceModel(
          id: 'srv_cuci_komplit',
          namaLayanan: 'Cuci Komplit Reguler',
          tipe: ServiceType.kiloan,
          harga: 7000,
          estimasiHari: 2,
        ),
        const ServiceModel(
          id: 'srv_cuci_express',
          namaLayanan: 'Cuci Kilat Express',
          tipe: ServiceType.kiloan,
          harga: 12000,
          estimasiHari: 1,
        ),
        const ServiceModel(
          id: 'srv_kering_lipat',
          namaLayanan: 'Cuci Kering Lipat',
          tipe: ServiceType.kiloan,
          harga: 5000,
          estimasiHari: 1,
        ),
        const ServiceModel(
          id: 'srv_bed_cover',
          namaLayanan: 'Bed Cover / Selimut',
          tipe: ServiceType.satuan,
          harga: 25000,
          estimasiHari: 3,
        ),
        const ServiceModel(
          id: 'srv_sepatu',
          namaLayanan: 'Cuci Sepatu Premium',
          tipe: ServiceType.satuan,
          harga: 35000,
          estimasiHari: 3,
        ),
      ];

      for (final srv in defaultServices) {
        await servicesCollection.doc(srv.id).set(srv.toMap());
        servicesCount++;
      }

      // ── 2. Seed Data Pelanggan ─────────────────────────────────────
      final customersCollection = _firestore.collection('customers');
      final List<CustomerModel> dummyCustomers = [
        CustomerModel(
          id: 'cust_siti',
          nama: 'Siti Rahmawati',
          noHp: '081234567890',
          totalTransaksi: 8,
          createdAt: now.subtract(const Duration(days: 45)),
        ),
        CustomerModel(
          id: 'cust_budi',
          nama: 'Budi Santoso',
          noHp: '082198765432',
          totalTransaksi: 6,
          createdAt: now.subtract(const Duration(days: 30)),
        ),
        CustomerModel(
          id: 'cust_dewi',
          nama: 'Dewi Lestari',
          noHp: '085712345678',
          totalTransaksi: 4,
          createdAt: now.subtract(const Duration(days: 25)),
        ),
        CustomerModel(
          id: 'cust_rian',
          nama: 'Rian Pratama',
          noHp: '087811223344',
          totalTransaksi: 3,
          createdAt: now.subtract(const Duration(days: 18)),
        ),
        CustomerModel(
          id: 'cust_anisa',
          nama: 'Anisa Nurhaliza',
          noHp: '089655443322',
          totalTransaksi: 2,
          createdAt: now.subtract(const Duration(days: 12)),
        ),
        CustomerModel(
          id: 'cust_dimas',
          nama: 'Dimas Anggara',
          noHp: '081399887766',
          totalTransaksi: 1,
          createdAt: now.subtract(const Duration(days: 7)),
        ),
        CustomerModel(
          id: 'cust_hendra',
          nama: 'Hendra Wijaya',
          noHp: '085277889900',
          totalTransaksi: 5,
          createdAt: now.subtract(const Duration(days: 20)),
        ),
      ];

      int customersCount = 0;
      for (final cust in dummyCustomers) {
        await customersCollection.doc(cust.id).set(cust.toMap());
        customersCount++;
      }

      // ── 3. Seed Data Transaksi (14 Transaksi Realistis) ─────────────
      final txCollection = _firestore.collection('transactions');

      final List<TransactionModel> dummyTransactions = [
        // 1. Diterima Hari Ini
        TransactionModel(
          id: 'tx_demo_01',
          customerId: 'cust_siti',
          customerNama: 'Siti Rahmawati',
          nomorNota: 'LDY-${_formatDate(now)}-001',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 4.5,
          hargaSatuan: 7000,
          totalHarga: 31500,
          status: TransactionStatus.diterima,
          tanggalMasuk: now.subtract(const Duration(hours: 2)),
          estimasiSelesai: now.add(const Duration(days: 2)),
          createdBy: createdByName,
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        // 2. Diterima Kemarin Sore
        TransactionModel(
          id: 'tx_demo_02',
          customerId: 'cust_budi',
          customerNama: 'Budi Santoso',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 1)))}-002',
          jenisLayanan: 'Cuci Kilat Express',
          tipeLayanan: ServiceType.kiloan,
          berat: 3.0,
          hargaSatuan: 12000,
          totalHarga: 36000,
          status: TransactionStatus.diterima,
          tanggalMasuk: now.subtract(const Duration(days: 1, hours: 3)),
          estimasiSelesai: now.add(const Duration(hours: 10)),
          createdBy: createdByName,
          createdAt: now.subtract(const Duration(days: 1, hours: 3)),
          updatedAt: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        // 3. Proses Cuci (1 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_03',
          customerId: 'cust_dewi',
          customerNama: 'Dewi Lestari',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 1)))}-003',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 5.2,
          hargaSatuan: 7000,
          totalHarga: 36400,
          status: TransactionStatus.prosesCuci,
          tanggalMasuk: now.subtract(const Duration(days: 1, hours: 6)),
          estimasiSelesai: now.add(const Duration(days: 1)),
          createdBy: createdByName,
          createdAt: now.subtract(const Duration(days: 1, hours: 6)),
          updatedAt: now.subtract(const Duration(hours: 4)),
        ),
        // 4. Proses Cuci (2 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_04',
          customerId: 'cust_rian',
          customerNama: 'Rian Pratama',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 2)))}-004',
          jenisLayanan: 'Bed Cover / Selimut',
          tipeLayanan: ServiceType.satuan,
          qty: 2,
          hargaSatuan: 25000,
          totalHarga: 50000,
          status: TransactionStatus.prosesCuci,
          tanggalMasuk: now.subtract(const Duration(days: 2, hours: 4)),
          estimasiSelesai: now.add(const Duration(days: 1)),
          createdBy: createdByName,
          createdAt: now.subtract(const Duration(days: 2, hours: 4)),
          updatedAt: now.subtract(const Duration(hours: 5)),
        ),
        // 5. Proses Setrika (2 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_05',
          customerId: 'cust_anisa',
          customerNama: 'Anisa Nurhaliza',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 2)))}-005',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 6.0,
          hargaSatuan: 7000,
          totalHarga: 42000,
          status: TransactionStatus.prosesSetrika,
          tanggalMasuk: now.subtract(const Duration(days: 2, hours: 8)),
          estimasiSelesai: now.add(const Duration(hours: 4)),
          createdBy: createdByName,
          createdAt: now.subtract(const Duration(days: 2, hours: 8)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        // 6. Proses Setrika (3 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_06',
          customerId: 'cust_dimas',
          customerNama: 'Dimas Anggara',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 3)))}-006',
          jenisLayanan: 'Cuci Sepatu Premium',
          tipeLayanan: ServiceType.satuan,
          qty: 1,
          hargaSatuan: 35000,
          totalHarga: 35000,
          status: TransactionStatus.prosesSetrika,
          tanggalMasuk: now.subtract(const Duration(days: 3, hours: 2)),
          estimasiSelesai: now,
          createdBy: createdByName,
          createdAt: now.subtract(const Duration(days: 3, hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        // 7. Siap Diambil + WA Sent (3 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_07',
          customerId: 'cust_hendra',
          customerNama: 'Hendra Wijaya',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 3)))}-007',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 7.5,
          hargaSatuan: 7000,
          totalHarga: 52500,
          status: TransactionStatus.siapDiambil,
          tanggalMasuk: now.subtract(const Duration(days: 3, hours: 6)),
          estimasiSelesai: now.subtract(const Duration(days: 1)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(hours: 6)),
          createdAt: now.subtract(const Duration(days: 3, hours: 6)),
          updatedAt: now.subtract(const Duration(hours: 6)),
        ),
        // 8. Siap Diambil + WA Sent (4 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_08',
          customerId: 'cust_siti',
          customerNama: 'Siti Rahmawati',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 4)))}-008',
          jenisLayanan: 'Cuci Kering Lipat',
          tipeLayanan: ServiceType.kiloan,
          berat: 8.0,
          hargaSatuan: 5000,
          totalHarga: 40000,
          status: TransactionStatus.siapDiambil,
          tanggalMasuk: now.subtract(const Duration(days: 4, hours: 5)),
          estimasiSelesai: now.subtract(const Duration(days: 3)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 1)),
          createdAt: now.subtract(const Duration(days: 4, hours: 5)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        // 9. Selesai (5 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_09',
          customerId: 'cust_budi',
          customerNama: 'Budi Santoso',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 5)))}-009',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 5.0,
          hargaSatuan: 7000,
          totalHarga: 35000,
          status: TransactionStatus.selesai,
          tanggalMasuk: now.subtract(const Duration(days: 5, hours: 4)),
          estimasiSelesai: now.subtract(const Duration(days: 3)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 3)),
          createdAt: now.subtract(const Duration(days: 5, hours: 4)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        // 10. Selesai (7 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_10',
          customerId: 'cust_dewi',
          customerNama: 'Dewi Lestari',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 7)))}-010',
          jenisLayanan: 'Cuci Kilat Express',
          tipeLayanan: ServiceType.kiloan,
          berat: 4.0,
          hargaSatuan: 12000,
          totalHarga: 48000,
          status: TransactionStatus.selesai,
          tanggalMasuk: now.subtract(const Duration(days: 7, hours: 6)),
          estimasiSelesai: now.subtract(const Duration(days: 6)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 6)),
          createdAt: now.subtract(const Duration(days: 7, hours: 6)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        // 11. Selesai (9 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_11',
          customerId: 'cust_rian',
          customerNama: 'Rian Pratama',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 9)))}-011',
          jenisLayanan: 'Bed Cover / Selimut',
          tipeLayanan: ServiceType.satuan,
          qty: 1,
          hargaSatuan: 25000,
          totalHarga: 25000,
          status: TransactionStatus.selesai,
          tanggalMasuk: now.subtract(const Duration(days: 9, hours: 3)),
          estimasiSelesai: now.subtract(const Duration(days: 6)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 6)),
          createdAt: now.subtract(const Duration(days: 9, hours: 3)),
          updatedAt: now.subtract(const Duration(days: 6)),
        ),
        // 12. Selesai (11 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_12',
          customerId: 'cust_siti',
          customerNama: 'Siti Rahmawati',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 11)))}-012',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 10.0,
          hargaSatuan: 7000,
          totalHarga: 70000,
          status: TransactionStatus.selesai,
          tanggalMasuk: now.subtract(const Duration(days: 11, hours: 4)),
          estimasiSelesai: now.subtract(const Duration(days: 9)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 9)),
          createdAt: now.subtract(const Duration(days: 11, hours: 4)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        // 13. Selesai (13 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_13',
          customerId: 'cust_hendra',
          customerNama: 'Hendra Wijaya',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 13)))}-013',
          jenisLayanan: 'Cuci Sepatu Premium',
          tipeLayanan: ServiceType.satuan,
          qty: 2,
          hargaSatuan: 35000,
          totalHarga: 70000,
          status: TransactionStatus.selesai,
          tanggalMasuk: now.subtract(const Duration(days: 13, hours: 5)),
          estimasiSelesai: now.subtract(const Duration(days: 10)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 10)),
          createdAt: now.subtract(const Duration(days: 13, hours: 5)),
          updatedAt: now.subtract(const Duration(days: 9)),
        ),
        // 14. Selesai (14 Hari Lalu)
        TransactionModel(
          id: 'tx_demo_14',
          customerId: 'cust_budi',
          customerNama: 'Budi Santoso',
          nomorNota: 'LDY-${_formatDate(now.subtract(const Duration(days: 14)))}-014',
          jenisLayanan: 'Cuci Komplit Reguler',
          tipeLayanan: ServiceType.kiloan,
          berat: 6.5,
          hargaSatuan: 7000,
          totalHarga: 45500,
          status: TransactionStatus.selesai,
          tanggalMasuk: now.subtract(const Duration(days: 14, hours: 2)),
          estimasiSelesai: now.subtract(const Duration(days: 12)),
          createdBy: createdByName,
          waNotifSentAt: now.subtract(const Duration(days: 12)),
          createdAt: now.subtract(const Duration(days: 14, hours: 2)),
          updatedAt: now.subtract(const Duration(days: 11)),
        ),
      ];

      int transactionsCount = 0;
      for (final tx in dummyTransactions) {
        await txCollection.doc(tx.id).set(tx.toMap());
        transactionsCount++;
      }

      debugPrint('✅ Sukses seed: $servicesCount layanan, $customersCount pelanggan, $transactionsCount transaksi.');

      return DemoSeedResult(
        servicesAdded: servicesCount,
        customersAdded: customersCount,
        transactionsAdded: transactionsCount,
        isSuccess: true,
        message: 'Berhasil membuat $customersCount pelanggan dan $transactionsCount transaksi demo.',
      );
    } catch (e) {
      debugPrint('❌ Gagal seeding data demo: $e');
      return DemoSeedResult(
        servicesAdded: 0,
        customersAdded: 0,
        transactionsAdded: 0,
        isSuccess: false,
        message: 'Gagal membuat data demo: ${e.toString()}',
      );
    }
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
