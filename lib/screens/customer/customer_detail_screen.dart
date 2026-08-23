import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/customer_model.dart';
import '../../models/transaction_model.dart';
import '../../models/enums.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/accent_card.dart';
import '../transaction/transaction_detail_screen.dart';
import '../transaction/transaction_form_screen.dart';
import 'add_edit_customer_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  Future<void> _openWhatsApp(BuildContext context) async {
    if (customer.noHp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp pelanggan tidak valid'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String cleaned = customer.noHp.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }

    final message =
        'Halo Kak ${customer.nama}, ada yang bisa kami bantu dari LaundryKu? 😊';
    final url =
        Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terpasang.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka aplikasi WhatsApp: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Text(
          'Hapus Pelanggan?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${customer.nama}"? Riwayat transaksi lama tetap tersimpan.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<CustomerProvider>().deleteCustomer(customer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data pelanggan "${customer.nama}" berhasil dihapus'),
            backgroundColor: AppTheme.statusSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();

    // Ambil semua transaksi milik pelanggan ini
    final customerTransactions = txProvider.allTransactions.where((t) {
      return t.customerId == customer.id ||
          (customer.id.isNotEmpty && t.customerId == customer.id) ||
          t.customerNama.toLowerCase() == customer.nama.toLowerCase();
    }).toList();

    // Kalkulasi Total Belanja
    final totalBelanja = customerTransactions.fold<double>(
      0,
      (sum, t) => sum + t.totalHarga,
    );

    final isLoyalCustomer = customer.totalTransaksi >= 5 || totalBelanja >= 150000;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil Pelanggan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Pelanggan',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditCustomerScreen(customer: customer),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus Pelanggan',
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Hero Customer Info Card ────────────────────────
                _buildCustomerProfileCard(
                  context,
                  isDark,
                  isLoyalCustomer,
                  totalBelanja,
                  customerTransactions.length,
                ),
                const SizedBox(height: 16),

                // ── 2. Quick Action Buttons ───────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        icon: const Icon(Icons.chat_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          'Chat WhatsApp',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TransactionFormScreen(
                                preselectedCustomer: customer,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.ctaColor(context),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded,
                            size: 18, color: Colors.white),
                        label: Text(
                          'Transaksi Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── 3. Riwayat Transaksi Pelanggan ────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Transaksi (${customerTransactions.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Urut Terbaru',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (customerTransactions.isEmpty)
                  _buildEmptyTransactions(context, isDark)
                else
                  ...customerTransactions.map((tx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildTransactionHistoryCard(context, tx, isDark),
                    );
                  }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerProfileCard(
    BuildContext context,
    bool isDark,
    bool isLoyalCustomer,
    double totalBelanja,
    int totalCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppTheme.lightShadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Hero Avatar
              Hero(
                tag: 'cust_avatar_${customer.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.signatureColor(context)
                      .withAlpha(isDark ? 50 : 30),
                  child: Text(
                    customer.nama.isNotEmpty
                        ? customer.nama[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.signatureColor(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.nama,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (isLoyalCustomer) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withAlpha(30),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 12, color: Color(0xFFD97706)),
                                const SizedBox(width: 3),
                                Text(
                                  'SETIA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          customer.noHp,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.lightTextHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Member sejak: ${AppFormatters.date(customer.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.darkTextHint
                                : AppTheme.lightTextHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Total Belanja Metric
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric(
                'Total Transaksi',
                '$totalCount kali',
                AppTheme.lightPrimaryVariant,
                isDark,
              ),
              Container(
                height: 30,
                width: 1,
                color: AppTheme.borderColor(context),
              ),
              _buildMiniMetric(
                'Total Belanja',
                AppFormatters.rupiah(totalBelanja),
                AppTheme.statusSuccess,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color:
                isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryCard(
    BuildContext context,
    TransactionModel tx,
    bool isDark,
  ) {
    Color statusColor;
    switch (tx.status) {
      case TransactionStatus.diterima:
        statusColor = AppTheme.statusWarning;
        break;
      case TransactionStatus.selesai:
        statusColor = AppTheme.statusSuccess;
        break;
      case TransactionStatus.sudahDiambil:
        statusColor = const Color(0xFF64748B);
        break;
    }

    final isAttention = tx.isAttentionRequired;
    final effectiveAccentColor =
        isAttention ? const Color(0xFFE11D48) : statusColor;

    return SignatureAccentCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: tx),
          ),
        );
      },
      accentColor: effectiveAccentColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAttention) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48).withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: const Color(0xFFE11D48).withAlpha(isDark ? 80 : 50),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.priority_high_rounded,
                      size: 12, color: Color(0xFFE11D48)),
                  const SizedBox(width: 4),
                  Text(
                    'PERHATIAN: TUNGGAKAN BELUM DIBAYAR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx.nomorNota,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  tx.status.label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tx.jenisLayanan,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppFormatters.date(tx.tanggalMasuk),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextHint
                      : AppTheme.lightTextHint,
                ),
              ),
              Text(
                AppFormatters.rupiah(tx.totalHarga),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges: Status Pengambilan, Status Pembayaran, Metode Pembayaran
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              // Badge Pengambilan
              _buildHistoryBadge(
                label: tx.isSudahDiambil ? 'Sudah Diambil' : 'Belum Diambil',
                icon: tx.isSudahDiambil
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                color: tx.isSudahDiambil
                    ? const Color(0xFF10B981)
                    : const Color(0xFFD97706),
                isDark: isDark,
              ),
              // Badge Pembayaran
              _buildHistoryBadge(
                label: tx.isLunas ? 'Lunas' : 'Belum Bayar',
                icon: tx.isLunas
                    ? Icons.verified_rounded
                    : Icons.priority_high_rounded,
                color: tx.isLunas
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE11D48),
                isDark: isDark,
              ),
              // Badge Metode
              _buildHistoryBadge(
                label: tx.metodePembayaran,
                icon: tx.metodePembayaran.toUpperCase() == 'QRIS'
                    ? Icons.qr_code_2_rounded
                    : Icons.payments_outlined,
                color: tx.metodePembayaran.toUpperCase() == 'QRIS'
                    ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
                    : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryBadge({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 20),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: color.withAlpha(isDark ? 70 : 40),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyTransactions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 36,
            color: isDark ? AppTheme.darkTextHint : AppTheme.lightTextHint,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada transaksi untuk pelanggan ini',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
