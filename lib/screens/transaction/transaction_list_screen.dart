import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/transaction_model.dart';
import '../../models/enums.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/accent_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/skeleton_loading.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends StatefulWidget {
  final TransactionStatus? initialStatusFilter;

  const TransactionListScreen({super.key, this.initialStatusFilter});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<TransactionProvider>()
            .setFilterStatus(widget.initialStatusFilter);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TransactionFormScreen(),
      ),
    );
  }

  void _openDetail(TransactionModel tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transaction: tx),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status, bool isDark) {
    switch (status) {
      case TransactionStatus.diterima:
        return AppTheme.statusWarning;
      case TransactionStatus.selesai:
        return AppTheme.statusSuccess;
      case TransactionStatus.sudahDiambil:
        return isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final transactions = txProvider.transactions;
    final currentStatus = txProvider.filterStatus;
    final isFiltered = currentStatus != null ||
        txProvider.filterBelumBayarOnly ||
        txProvider.filterBelumDiambilOnly ||
        txProvider.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Daftar Transaksi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTransaction,
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
        child: Column(
          children: [
            // ── Search & Filter Controls ──────────────────────────
            _buildSearchAndFilters(context, isDark, txProvider, currentStatus),

            // ── Transactions List ─────────────────────────────────
            Expanded(
              child: txProvider.isLoading && transactions.isEmpty
                  ? const SkeletonLoadingList(itemCount: 6, itemHeight: 120)
                  : transactions.isEmpty
                      ? _buildEmptyState(context, isDark, isFiltered)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 10,
                              bottom: 90,
                            ),
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return _buildTransactionCard(
                                  context, tx, isDark);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    bool isDark,
    TransactionProvider provider,
    TransactionStatus? currentStatus,
  ) {
    final hasActiveFilter = currentStatus != null ||
        provider.filterBelumBayarOnly ||
        provider.filterBelumDiambilOnly ||
        provider.searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor(context),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) => provider.setSearchQuery(val),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari nota, pelanggan, layanan...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Baris 1: Status Alur Laundry Chips (3 Tahap: Diterima -> Selesai -> Sudah Diambil)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip(
                  label: 'Semua (${provider.allTransactions.length})',
                  isSelected: currentStatus == null,
                  onTap: () => provider.setFilterStatus(null),
                  color: AppTheme.signatureColor(context),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Diterima (${provider.antreanCount})',
                  isSelected: currentStatus == TransactionStatus.diterima,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.diterima),
                  color: AppTheme.statusWarning,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Selesai (${provider.selesaiCount})',
                  isSelected: currentStatus == TransactionStatus.selesai,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.selesai),
                  color: AppTheme.statusSuccess,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Sudah Diambil (${provider.sudahDiambilCount})',
                  isSelected: currentStatus == TransactionStatus.sudahDiambil,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.sudahDiambil),
                  color: const Color(0xFF64748B),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Baris 2: Quick Filter Khusus (Belum Bayar & Belum Diambil)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Quick Filter: Belum Bayar
                _buildQuickToggleChip(
                  context: context,
                  label: 'Belum Bayar (${provider.belumBayarCount})',
                  icon: Icons.error_outline_rounded,
                  isSelected: provider.filterBelumBayarOnly,
                  activeColor: const Color(0xFFE11D48),
                  isDark: isDark,
                  onTap: () => provider.toggleFilterBelumBayar(),
                ),
                const SizedBox(width: 8),
                // Quick Filter: Belum Diambil
                _buildQuickToggleChip(
                  context: context,
                  label: 'Belum Diambil (${provider.belumDiambilCount})',
                  icon: Icons.schedule_rounded,
                  isSelected: provider.filterBelumDiambilOnly,
                  activeColor: const Color(0xFFD97706),
                  isDark: isDark,
                  onTap: () => provider.toggleFilterBelumDiambil(),
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? Colors.white
                                : Colors.black)
                            .withAlpha(isDark ? 20 : 10),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Reset Filter',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggleChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(isDark ? 60 : 30)
              : (isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.borderColor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(isDark ? 60 : 30)
              : (isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderColor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? color
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    bool isDark,
  ) {
    final statusColor = _getStatusColor(tx.status, isDark);
    final isOverdue = tx.isOverdue;
    final isAttention = tx.isAttentionRequired;

    final isKiloan = tx.tipeLayanan == ServiceType.kiloan;
    final qtyText = isKiloan ? '${tx.berat ?? "-"} kg' : '${tx.qty ?? "-"} pcs';

    final effectiveAccentColor = isAttention
        ? const Color(0xFFE11D48)
        : (isOverdue ? AppTheme.statusError : statusColor);

    return SignatureAccentCard(
      onTap: () => _openDetail(tx),
      accentColor: effectiveAccentColor,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Highlight Alert Strip (Jika cucian selesai/siap diambil tapi belum bayar) ──
          if (isAttention) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const Icon(Icons.warning_amber_rounded,
                      size: 13, color: Color(0xFFE11D48)),
                  const SizedBox(width: 4),
                  Text(
                    'PERHATIAN: CUCIAN SIAP / BELUM BAYAR (TAGIH PEMBAYARAN)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE11D48),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Row 1: Nomor Nota + Status Alur Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx.nomorNota,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(isDark ? 45 : 25),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  tx.status.label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Customer Name + Tanggal Masuk
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tx.customerNama,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                AppFormatters.date(tx.tanggalMasuk),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextHint
                      : AppTheme.lightTextHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 3: Service & Qty + Total Harga
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isKiloan
                          ? Icons.local_laundry_service_outlined
                          : Icons.checkroom_outlined,
                      size: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${tx.jenisLayanan} • $qtyText',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.rupiah(tx.totalHarga),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkPrimary
                      : AppTheme.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Divider(height: 1),
          const SizedBox(height: 8),

          // Row 4: BADGES BAR (Status Pengambilan, Status Pembayaran, Metode, WA Notif)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 1. Badge STATUS PENGAMBILAN
              _buildPickupStatusBadge(context, tx.isSudahDiambil, isDark),

              // 2. Badge STATUS PEMBAYARAN
              _buildPaymentStatusBadge(context, tx.isLunas, isDark),

              // 3. Badge METODE PEMBAYARAN (Tunai / QRIS)
              _buildPaymentMethodBadge(context, tx.metodePembayaran, isDark),

              // 4. Badge WhatsApp Sent if applicable
              if (tx.waNotifSentAt != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess.withAlpha(isDark ? 30 : 18),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.statusSuccess.withAlpha(isDark ? 70 : 40),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 11, color: AppTheme.statusSuccess),
                      const SizedBox(width: 3),
                      Text(
                        'WA Sent',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Badge Overdue if applicable
              if (isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppTheme.statusError.withAlpha(isDark ? 35 : 20),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                        color: AppTheme.statusError, width: 0.8),
                  ),
                  child: Text(
                    'LEWAT ESTIMASI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.statusError,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge Status Pengambilan ("Belum Diambil" vs "Sudah Diambil")
  Widget _buildPickupStatusBadge(
      BuildContext context, bool isSudahDiambil, bool isDark) {
    final color = isSudahDiambil
        ? const Color(0xFF10B981)
        : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 20),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: color.withAlpha(isDark ? 80 : 50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSudahDiambil
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3.5),
          Text(
            isSudahDiambil ? 'Sudah Diambil' : 'Belum Diambil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge Status Pembayaran ("Belum Bayar" vs "Lunas")
  Widget _buildPaymentStatusBadge(
      BuildContext context, bool isLunas, bool isDark) {
    final color = isLunas
        ? const Color(0xFF10B981)
        : const Color(0xFFE11D48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 35 : 20),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: color.withAlpha(isDark ? 80 : 50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLunas
                ? Icons.verified_rounded
                : Icons.priority_high_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isLunas ? 'Lunas' : 'Belum Bayar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge Metode Pembayaran (Tunai / QRIS)
  Widget _buildPaymentMethodBadge(
      BuildContext context, String method, bool isDark) {
    final isQris = method.toUpperCase() == 'QRIS';
    final badgeColor = isQris
        ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(isDark ? 35 : 20),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: badgeColor.withAlpha(isDark ? 80 : 50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isQris ? Icons.qr_code_2_rounded : Icons.payments_outlined,
            size: 11,
            color: badgeColor,
          ),
          const SizedBox(width: 3),
          Text(
            isQris ? 'QRIS' : 'Tunai',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    bool isFiltered,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.signatureColor(context)
                    .withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: AppTheme.signatureColor(context)
                      .withAlpha(isDark ? 60 : 40),
                ),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: AppTheme.signatureColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'Tidak Ada Transaksi di Filter Ini'
                  : 'Belum Ada Riwayat Transaksi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Coba ubah status alur, filter Belum Bayar/Diambil, atau kata kunci pencarian.'
                  : 'Buat transaksi nota cucian baru untuk mulai mencatat pesanan pelanggan.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!isFiltered)
              ElevatedButton.icon(
                onPressed: _openNewTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ctaColor(context),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Buat Transaksi Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

