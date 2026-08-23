import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_carousel.dart';
import '../../widgets/accent_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/app_logo.dart';
import '../customer/customer_list_screen.dart';
import '../transaction/transaction_form_screen.dart';
import '../transaction/transaction_list_screen.dart';

class KasirDashboardScreen extends StatelessWidget {
  const KasirDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final customerProvider = context.watch<CustomerProvider>();
    final txProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoIcon(size: 30),
            const SizedBox(width: 10),
            Text(
              'LaundryKu Kasir',
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
                              : AppTheme.lightAccent.withAlpha(40),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          size: 28,
                          color: isDark
                              ? AppTheme.darkPrimary
                              : AppTheme.lightPrimaryVariant,
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
                                    user?.nama ?? 'Kasir Laundry',
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
                                    color: AppTheme.lightAccent
                                        .withAlpha(isDark ? 50 : 30),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: AppTheme.lightAccent
                                          .withAlpha(isDark ? 100 : 70),
                                    ),
                                  ),
                                  child: Text(
                                    'KASIR',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppTheme.darkPrimary
                                          : const Color(0xFF0284C7),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Shift Operasional Aktif • Siap Melayani',
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

              // ── 3. Quick Action Grid ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium),
                child: Text(
                  'Aksi Cepat',
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
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.post_add_rounded,
                        title: 'Input Nota',
                        subtitle: 'Pesanan baru',
                        color: AppTheme.ctaColor(context),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionFormScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.search_rounded,
                        title: 'Cari Nota',
                        subtitle: '${txProvider.activeTransactionsCount} aktif',
                        color: AppTheme.lightPrimaryVariant,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionListScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickActionButton(
                        context: context,
                        icon: Icons.people_alt_outlined,
                        title: 'Pelanggan',
                        subtitle: '${customerProvider.totalCustomers} orang',
                        color: AppTheme.signatureColor(context),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CustomerListScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. Laundry Status Pipeline ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Proses Cucian',
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
                        'Lihat Semua →',
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
                child: Column(
                  children: [
                    _buildStatusRow(
                      context: context,
                      icon: Icons.inbox_outlined,
                      label: 'Diterima (Antrean Masuk)',
                      count: '${txProvider.antreanCount} Nota',
                      color: AppTheme.statusWarning,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(
                              initialStatusFilter: TransactionStatus.diterima,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      context: context,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Selesai (Siap Diambil)',
                      count: '${txProvider.selesaiCount} Nota',
                      color: AppTheme.statusSuccess,
                      isHighlighted: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(
                              initialStatusFilter: TransactionStatus.selesai,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                      context: context,
                      icon: Icons.task_alt_rounded,
                      label: 'Sudah Diambil Pelanggan',
                      count: '${txProvider.sudahDiambilCount} Nota',
                      color: const Color(0xFF64748B),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransactionListScreen(
                              initialStatusFilter:
                                  TransactionStatus.sudahDiambil,
                            ),
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

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SignatureAccentCard(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SignatureAccentCard(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              count,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
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
          'Apakah Anda yakin ingin keluar dari akun Kasir?',
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
