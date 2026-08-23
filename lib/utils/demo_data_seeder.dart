import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/transaction_model.dart';

/// Helper utility untuk mengisi data dummy awal (seeding) aplikasi LaundryKu.
/// Data dummy metode pembayaran disederhanakan HANYA menggunakan 2 opsi: "Tunai" dan "QRIS".
class DemoDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Daftar opsi metode pembayaran yang diizinkan (HANYA 2 OPSI)
  static const List<String> availablePaymentMethods = ['Tunai', 'QRIS'];

  /// Ambil metode pembayaran acak ("Tunai" atau "QRIS")
  static String getRandomPaymentMethod() {
    return availablePaymentMethods[_random.nextInt(availablePaymentMethods.length)];
  }

  /// Seed data demo lengkap: Pelanggan, Layanan, dan Transaksi
  static Future<bool> seedAllDemoData() async {
    try {
      debugPrint('🌱 Memulai proses seeding data demo LaundryKu...');

      // 1. Seed Services (Layanan)
      await seedServices();

      // 2. Seed Customers (Pelanggan)
      final customerIds = await seedCustomers();

      // 3. Seed Transactions (Transaksi)
      await seedTransactions(customerIds);

      debugPrint('✅ Berhasil melakukan seeding semua data demo LaundryKu!');
      return true;
    } catch (e) {
      debugPrint('❌ Gagal melakukan seeding data demo: $e');
      return false;
    }
  }

  /// Seed katalog layanan awal
  static Future<void> seedServices() async {
    final servicesCol = _firestore.collection('services');
    final existing = await servicesCol.limit(1).get();
    if (existing.docs.isNotEmpty) {
      debugPrint('ℹ️ Layanan sudah ada, melewati seed layanan.');
      return;
    }

    final initialServices = [
      {
        'namaLayanan': 'Cuci Kering Setrika (Reguler)',
        'tipe': ServiceType.kiloan.name,
        'harga': 7000.0,
        'estimasiHari': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'namaLayanan': 'Cuci Kering Setrika (Express)',
        'tipe': ServiceType.kiloan.name,
        'harga': 12000.0,
        'estimasiHari': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'namaLayanan': 'Cuci Lipat (Tanpa Setrika)',
        'tipe': ServiceType.kiloan.name,
        'harga': 5000.0,
        'estimasiHari': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'namaLayanan': 'Setrika Saja (Kiloan)',
        'tipe': ServiceType.kiloan.name,
        'harga': 4500.0,
        'estimasiHari': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'namaLayanan': 'Bed Cover Besar (Satuan)',
        'tipe': ServiceType.satuan.name,
        'harga': 25000.0,
        'estimasiHari': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'namaLayanan': 'Jas / Blazer (Satuan)',
        'tipe': ServiceType.satuan.name,
        'harga': 20000.0,
        'estimasiHari': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'namaLayanan': 'Sepatu Sneakers (Satuan)',
        'tipe': ServiceType.satuan.name,
        'harga': 30000.0,
        'estimasiHari': 3,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final s in initialServices) {
      await servicesCol.add(s);
    }
  }

  /// Seed data pelanggan
  static Future<List<Map<String, String>>> seedCustomers() async {
    final customersCol = _firestore.collection('customers');
    final existing = await customersCol.limit(5).get();
    
    if (existing.docs.isNotEmpty) {
      return existing.docs
          .map((d) => {'id': d.id, 'nama': (d.data()['nama'] as String? ?? 'Pelanggan')})
          .toList();
    }

    final dummyCustomers = [
      {'nama': 'Budi Santoso', 'noHp': '081234567890', 'alamat': 'Jl. Mawar No. 12'},
      {'nama': 'Siti Rahmawati', 'noHp': '085712345678', 'alamat': 'Jl. Melati No. 45'},
      {'nama': 'Andi Pratama', 'noHp': '089611223344', 'alamat': 'Kost Griya Indah No. 5'},
      {'nama': 'Dewi Lestari', 'noHp': '082199887766', 'alamat': 'Perum Permata Blok B2'},
      {'nama': 'Rian Hidayat', 'noHp': '081377889900', 'alamat': 'Jl. Anggrek No. 8'},
    ];

    final List<Map<String, String>> result = [];
    for (final c in dummyCustomers) {
      final docRef = await customersCol.add({
        'nama': c['nama'],
        'noHp': c['noHp'],
        'alamat': c['alamat'],
        'totalTransaksi': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      result.add({'id': docRef.id, 'nama': c['nama']!});
    }

    return result;
  }

  /// Seed transaksi demo historis dengan metode pembayaran HANYA "Tunai" dan "QRIS"
  static Future<void> seedTransactions(List<Map<String, String>> customers) async {
    final txCol = _firestore.collection('transactions');
    final now = DateTime.now();

    final serviceList = [
      {'nama': 'Cuci Kering Setrika (Reguler)', 'tipe': ServiceType.kiloan, 'harga': 7000.0},
      {'nama': 'Cuci Kering Setrika (Express)', 'tipe': ServiceType.kiloan, 'harga': 12000.0},
      {'nama': 'Bed Cover Besar (Satuan)', 'tipe': ServiceType.satuan, 'harga': 25000.0},
      {'nama': 'Sepatu Sneakers (Satuan)', 'tipe': ServiceType.satuan, 'harga': 30000.0},
    ];

    final statuses = [
      TransactionStatus.diterima,
      TransactionStatus.selesai,
      TransactionStatus.sudahDiambil,
    ];

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final txDate = now.subtract(Duration(days: dayOffset));
      final txCountPerDay = 2 + _random.nextInt(3); // 2-4 transaksi per hari

      for (int i = 0; i < txCountPerDay; i++) {
        final cust = customers.isNotEmpty
            ? customers[_random.nextInt(customers.length)]
            : {'id': 'dummy-cust', 'nama': 'Pelanggan Walk-In'};
        final srv = serviceList[_random.nextInt(serviceList.length)];
        final isKiloan = srv['tipe'] == ServiceType.kiloan;
        final berat = isKiloan ? (2.0 + _random.nextInt(6) * 0.5) : null;
        final qty = !isKiloan ? (1 + _random.nextInt(3)) : null;
        final hargaSatuan = srv['harga'] as double;
        final totalHarga = isKiloan ? (berat! * hargaSatuan) : (qty! * hargaSatuan);
        final status = statuses[_random.nextInt(statuses.length)];
        
        // METODE PEMBAYARAN: HANYA "Tunai" atau "QRIS" secara acak
        final paymentMethod = getRandomPaymentMethod();

        // STATUS PEMBAYARAN: 75% lunas, 25% belum_bayar untuk simulasi
        final isLunas = _random.nextDouble() < 0.75;
        final paymentStatus = isLunas ? PaymentStatus.lunas : PaymentStatus.belumBayar;

        final dateStr = '${txDate.year}${txDate.month.toString().padLeft(2, '0')}${txDate.day.toString().padLeft(2, '0')}';
        final notaNumber = 'LDY-$dateStr-${(i + 1).toString().padLeft(3, '0')}${_random.nextInt(90) + 10}';

        final tx = TransactionModel(
          id: '',
          customerId: cust['id'] ?? '',
          customerNama: cust['nama'] ?? 'Pelanggan',
          nomorNota: notaNumber,
          jenisLayanan: srv['nama'] as String,
          tipeLayanan: srv['tipe'] as ServiceType,
          berat: berat,
          qty: qty,
          hargaSatuan: hargaSatuan,
          totalHarga: totalHarga,
          metodePembayaran: paymentMethod, // "Tunai" / "QRIS"
          statusPembayaran: paymentStatus,
          status: status,
          tanggalMasuk: txDate,
          estimasiSelesai: txDate.add(const Duration(days: 2)),
          createdBy: 'Kasir Demo',
          createdAt: txDate,
          updatedAt: txDate,
        );

        await txCol.add(tx.toMap());

        // Increment customer totalTransaksi jika ada customerId
        if (cust['id'] != null && cust['id']!.isNotEmpty) {
          try {
            await _firestore.collection('customers').doc(cust['id']).update({
              'totalTransaksi': FieldValue.increment(1),
            });
          } catch (_) {}
        }
      }
    }
  }
}
