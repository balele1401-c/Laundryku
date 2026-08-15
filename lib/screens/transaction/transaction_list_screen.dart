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
      case TransactionStatus.prosesCuci:
        return isDark ? AppTheme.darkPrimary : AppTheme.lightPrimaryVariant;
      case TransactionStatus.prosesSetrika:
        return AppTheme.signatureColor(context);
      case TransactionStatus.siapDiambil:
        return AppTheme.statusSuccess;
      case TransactionStatus.selesai:
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
                  ? const SkeletonLoadingList(itemCount: 6, itemHeight: 110)
                  : transactions.isEmpty
                      ? _buildEmptyState(
                          context, isDark, currentStatus != null)
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
          const SizedBox(height: 12),

          // Horizontal Status Filter Chips
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
                  label: 'Cuci (${provider.prosesCuciCount})',
                  isSelected: currentStatus == TransactionStatus.prosesCuci,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.prosesCuci),
                  color: isDark
                      ? AppTheme.darkPrimary
                      : AppTheme.lightPrimaryVariant,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Setrika (${provider.prosesSetrikaCount})',
                  isSelected: currentStatus == TransactionStatus.prosesSetrika,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.prosesSetrika),
                  color: AppTheme.signatureColor(context),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Siap Diambil (${provider.siapDiambilCount})',
                  isSelected: currentStatus == TransactionStatus.siapDiambil,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.siapDiambil),
                  color: AppTheme.statusSuccess,
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Selesai',
                  isSelected: currentStatus == TransactionStatus.selesai,
                  onTap: () =>
                      provider.setFilterStatus(TransactionStatus.selesai),
                  color: const Color(0xFF64748B),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
    final isOverdue = tx.status != TransactionStatus.selesai &&
        DateTime.now().isAfter(tx.estimasiSelesai);

    final isKiloan = tx.tipeLayanan == ServiceType.kiloan;
    final qtyText = isKiloan ? '${tx.berat ?? "-"} kg' : '${tx.qty ?? "-"} pcs';

    return Stack(
      children: [
        SignatureAccentCard(
          onTap: () => _openDetail(tx),
          accentColor: isOverdue ? AppTheme.statusError : statusColor,
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Nomor Nota + Status Badge
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
                  Row(
                    children: [
                      if (tx.waNotifSentAt != null) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.statusSuccess.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle,
                              size: 13, color: AppTheme.statusSuccess),
                        ),
                      ],
                      if (isOverdue) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.statusError.withAlpha(30),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                                color: AppTheme.statusError, width: 1),
                          ),
                          child: Text(
                            'LEWAT ESTIMASI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.statusError,
                            ),
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(isDark ? 45 : 25),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          tx.status.label.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Customer Name
              Text(
                tx.customerNama,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Row 3: Service & Qty
              Row(
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
              const SizedBox(height: 10),

              const Divider(height: 1),
              const SizedBox(height: 8),

              // Row 4: Total Price + Date
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.lightPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
                  ? 'Tidak Ada Transaksi di Kategori Ini'
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
                  ? 'Coba ganti filter status atau kata kunci pencarian.'
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
