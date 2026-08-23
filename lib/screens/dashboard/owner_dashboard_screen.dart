import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/enums.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/brand_carousel.dart';
import '../../widgets/accent_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/app_logo.dart';
import '../customer/customer_list_screen.dart';
import '../service/service_list_screen.dart';
import '../transaction/transaction_list_screen.dart';
import '../transaction/transaction_form_screen.dart';
import '../transaction/transaction_detail_screen.dart';
import '../report/report_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final customerProvider = context.watch<CustomerProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final recentTxs = txProvider.recentTransactions;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoIcon(size: 30),
            const SizedBox(width: 10),
            Text(
              'LaundryKu Owner',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TransactionFormScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.ctaColor(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Transaksi Baru',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── 1. Hero Brand Carousel ────────────────────────────
              const BrandCarousel(),
              const SizedBox(height: 20),

              // ── 2. Greeting & Profile Section ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SignatureAccentCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0369A1)
                              : AppTheme.lightPrimaryVariant.withAlpha(30),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 28,
                          color: isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user?.nama ?? 'Owner Laundry',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightPrimaryVariant
                                        .withAlpha(isDark ? 50 : 25),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: AppTheme.lightPrimaryVariant
                                          .withAlpha(isDark ? 100 : 50),
                                    ),
                                  ),
                                  child: Text(
                                    'OWNER',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppTheme.darkPrimary
                                          : AppTheme.lightPrimaryVariant,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Pantau omzet bisnis & operasional cabang',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 3. Summary Cards Grid 2 Kolom ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ringkasan Hari Ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReportScreen(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 16,
                            color: AppTheme.signatureColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lihat Laporan →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.signatureColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            icon: Icons.payments_outlined,
                            title: 'Omzet Hari Ini',
                            value: AppFormatters.rupiah(txProvider.todayIncome),
                            accentColor: AppTheme.statusSuccess,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ReportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            icon: Icons.receipt_long_outlined,
                            title: 'Transaksi Hari Ini',
                            value: '${txProvider.todayTransactionsCount} Transaksi',
                            accentColor: AppTheme.lightPrimaryVariant,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TransactionListScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Cucian Selesai',
                            value: '${txProvider.selesaiCount} Nota',
                            accentColor: AppTheme.statusSuccess,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TransactionListScreen(
                                    initialStatusFilter:
                                        TransactionStatus.selesai,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            context: context,
                            icon: Icons.schedule_rounded,
                            title: 'Belum Diambil',
                            value: '${txProvider.belumDiambilCount} Nota',
                            accentColor: const Color(0xFFF59E0B),
                            onTap: () {
                              final provider = context.read<TransactionProvider>();
                              if (!provider.filterBelumDiambilOnly) {
                                provider.toggleFilterBelumDiambil();
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TransactionListScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      context: context,
                      icon: Icons.people_outline_rounded,
                      title: 'Total Pelanggan Terdaftar',
                      value: '${customerProvider.totalCustomers} Orang',
                      accentColor: AppTheme.ctaColor(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. Transaksi Terbaru (5 Terakhir) ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaksi Terbaru',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Semua Transaksi →',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.signatureColor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: recentTxs.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border:
                              Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Text(
                          'Belum ada transaksi yang dibuat.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      )
                    : Column(
                        children: recentTxs.map((tx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildRecentTxCard(context, tx, isDark),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),

              // ── 5. Owner Menu Feature List ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Menu Manajemen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan & Omzet Bisnis',
                      subtitle:
                          'Analisis pendapatan, rata-rata nota, tren harian dan grafik',
                      badgeText: 'Laporan',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ReportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.receipt_long_rounded,
                      title: 'Daftar Semua Transaksi & Nota',
                      subtitle:
                          'Lihat ${txProvider.totalTransactions} riwayat transaksi & lacak status pesanan',
                      badgeText: '${txProvider.totalTransactions}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.people_alt_outlined,
                      title: 'Data & Kontak Pelanggan',
                      subtitle:
                          'Lihat ${customerProvider.totalCustomers} pelanggan, tambah, edit & chat WhatsApp',
                      badgeText: '${customerProvider.totalCustomers}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomerListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      context: context,
                      icon: Icons.dry_cleaning_outlined,
                      title: 'Manajemen Layanan & Tarif',
                      subtitle:
                          'Kelola ${serviceProvider.totalServices} paket kiloan, satuan, dan estimasi waktu',
                      badgeText: '${serviceProvider.totalServices}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ServiceListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTxCard(
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

    return SignatureAccentCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: tx),
          ),
        );
      },
      accentColor: statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx.nomorNota,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (tx.metodePembayaran.toUpperCase() == 'QRIS'
                                ? (isDark
                                    ? const Color(0xFF818CF8)
                                    : const Color(0xFF4F46E5))
                                : (isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF059669)))
                            .withAlpha(isDark ? 35 : 20),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: (tx.metodePembayaran.toUpperCase() == 'QRIS'
                                  ? (isDark
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFF4F46E5))
                                  : (isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF059669)))
                              .withAlpha(isDark ? 70 : 40),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tx.metodePembayaran,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: tx.metodePembayaran.toUpperCase() == 'QRIS'
                              ? (isDark
                                  ? const Color(0xFF818CF8)
                                  : const Color(0xFF4F46E5))
                              : (isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (tx.isLunas
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE11D48))
                            .withAlpha(isDark ? 35 : 20),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: (tx.isLunas
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE11D48))
                              .withAlpha(isDark ? 70 : 40),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tx.isLunas ? 'Lunas' : 'Belum Bayar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: tx.isLunas
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(isDark ? 40 : 25),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
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
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (tx.isSudahDiambil
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                            .withAlpha(isDark ? 35 : 20),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: (tx.isSudahDiambil
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withAlpha(isDark ? 70 : 40),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tx.isSudahDiambil
                                ? Icons.check_circle_rounded
                                : Icons.access_time_rounded,
                            size: 9,
                            color: tx.isSudahDiambil
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 2.5),
                          Text(
                            tx.isSudahDiambil
                                ? 'Sudah Diambil'
                                : 'Belum Diambil',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: tx.isSudahDiambil
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tx.customerNama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  '${tx.jenisLayanan} • ${AppFormatters.date(tx.tanggalMasuk)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
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
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SignatureAccentCard(
      onTap: onTap,
      accentColor: accentColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SignatureAccentCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF334155)
                  : AppTheme.lightPrimaryVariant.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppTheme.lightTextHint,
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(
            color: AppTheme.borderColor(context),
          ),
        ),
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Owner?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
