import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/accent_card.dart';
import '../../widgets/theme_toggle_button.dart';

enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  custom,
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.thisWeek;
  DateTimeRange? _customDateRange;

  bool _isExportingPdf = false;
  bool _isExportingExcel = false;
  bool _isExportingWord = false;

  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case ReportPeriod.thisWeek:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.custom:
        return _customDateRange?.start ??
            DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriod.today:
      case ReportPeriod.thisWeek:
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case ReportPeriod.custom:
        if (_customDateRange != null) {
          final end = _customDateRange!.end;
          return DateTime(end.year, end.month, end.day, 23, 59, 59);
        }
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  String get _selectedPeriodLabel {
    switch (_selectedPeriod) {
      case ReportPeriod.today:
        return 'Hari Ini';
      case ReportPeriod.thisWeek:
        return '7 Hari Terakhir';
      case ReportPeriod.thisMonth:
        return 'Bulan Ini';
      case ReportPeriod.custom:
        return _customDateRange != null
            ? '${DateFormat('d/M').format(_customDateRange!.start)} - ${DateFormat('d/M').format(_customDateRange!.end)}'
            : 'Kustom';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = ReportPeriod.custom;
        _customDateRange = picked;
      });
    }
  }

  // ── Handlers Ekspor Laporan ───────────────────────────────────────────────

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportPdf(List<TransactionModel> txs) async {
    if (txs.isEmpty) {
      _showSnackBar(
        message: 'Tidak ada data transaksi pada periode ini untuk diekspor ke PDF.',
        backgroundColor: AppTheme.statusWarning,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isExportingPdf = true);
    try {
      await ReportExportService.sharePdfReport(
        startDate: _startDate,
        endDate: _endDate,
        transactions: txs,
        title: 'Laporan Keuangan LaundryKu - $_selectedPeriodLabel',
      );

      _showSnackBar(
        message: 'Laporan PDF berhasil dibuat & siap dibagikan/diunduh!',
        backgroundColor: AppTheme.statusSuccess,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      debugPrint('❌ Error export PDF: $e');
      _showSnackBar(
        message: 'Gagal mengekspor PDF: ${e.toString()}',
        backgroundColor: AppTheme.statusError,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportExcel(List<TransactionModel> txs) async {
    if (txs.isEmpty) {
      _showSnackBar(
        message: 'Tidak ada data transaksi pada periode ini untuk diekspor ke Excel.',
        backgroundColor: AppTheme.statusWarning,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isExportingExcel = true);
    try {
      await ReportExportService.shareExcelReport(
        startDate: _startDate,
        endDate: _endDate,
        transactions: txs,
        title: 'Laporan Keuangan LaundryKu (Excel) - $_selectedPeriodLabel',
      );

      _showSnackBar(
        message: 'Laporan Excel (.xlsx) berhasil dibuat & siap dibagikan/diunduh!',
        backgroundColor: AppTheme.statusSuccess,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      debugPrint('❌ Error export Excel: $e');
      _showSnackBar(
        message: 'Gagal mengekspor Excel: ${e.toString()}',
        backgroundColor: AppTheme.statusError,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _exportWord(List<TransactionModel> txs) async {
    if (txs.isEmpty) {
      _showSnackBar(
        message: 'Tidak ada data transaksi pada periode ini untuk diekspor ke Word.',
        backgroundColor: AppTheme.statusWarning,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isExportingWord = true);
    try {
      await ReportExportService.shareWordReport(
        startDate: _startDate,
        endDate: _endDate,
        transactions: txs,
        title: 'Laporan Keuangan LaundryKu (Word) - $_selectedPeriodLabel',
      );

      _showSnackBar(
        message: 'Laporan Word (.docx) berhasil dibuat & siap dibagikan/diunduh!',
        backgroundColor: AppTheme.statusSuccess,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      debugPrint('❌ Error export Word: $e');
      _showSnackBar(
        message: 'Gagal mengekspor Word: ${e.toString()}',
        backgroundColor: AppTheme.statusError,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isExportingWord = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.currentUser?.role == UserRole.owner;

    // Role Guard
    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Laporan Keuangan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 48, color: AppTheme.statusError),
                const SizedBox(height: 16),
                Text(
                  'Akses Dibatasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Laporan omzet dan analitik keuangan hanya dapat diakses oleh akun Owner.',
                  style: GoogleFonts.inter(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final txProvider = context.watch<TransactionProvider>();
    final allTx = txProvider.allTransactions;

    // Filter transaksi berdasarkan range periode
    final filteredTx = allTx.where((t) {
      return t.tanggalMasuk.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
          t.tanggalMasuk.isBefore(_endDate.add(const Duration(seconds: 1)));
    }).toList();

    // Kalkulasi Total Omzet & Metrik
    final totalOmzet = filteredTx.fold<double>(
        0, (sum, item) => sum + item.totalHarga);

    final totalTransaksi = filteredTx.length;
    final rataRataTransaksi =
        totalTransaksi > 0 ? totalOmzet / totalTransaksi : 0.0;

    final belumDiambilCount =
        filteredTx.where((t) => t.isBelumDiambil).length;

    final kiloanCount = filteredTx
        .where((t) => t.tipeLayanan == ServiceType.kiloan)
        .length;
    final satuanCount = filteredTx
        .where((t) => t.tipeLayanan == ServiceType.satuan)
        .length;

    // Breakdown Metode Pembayaran (Tunai vs QRIS)
    final tunaiTxs = filteredTx
        .where((t) => t.metodePembayaran.toUpperCase() != 'QRIS')
        .toList();
    final qrisTxs = filteredTx
        .where((t) => t.metodePembayaran.toUpperCase() == 'QRIS')
        .toList();

    final omzetTunai = tunaiTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);
    final omzetQris = qrisTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);

    // Hitung data harian untuk Bar Chart
    final chartData = _generateChartData(filteredTx, _startDate, _endDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Laporan & Omzet',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Periode Filter Chips ───────────────────────────
              _buildPeriodFilterRow(context, isDark),
              const SizedBox(height: 16),

              // ── 2. Highlight Card Total Omzet ─────────────────────
              _buildOmzetHeroCard(context, totalOmzet, isDark),
              const SizedBox(height: 16),

              // ── 3. SECTION BARU: Breakdown Metode Pembayaran ──────
              _buildSectionTitle('Breakdown Metode Pembayaran', isDark),
              const SizedBox(height: 10),
              _buildPaymentMethodBreakdown(
                context: context,
                isDark: isDark,
                totalOmzet: totalOmzet,
                totalTx: totalTransaksi,
                omzetTunai: omzetTunai,
                tunaiCount: tunaiTxs.length,
                omzetQris: omzetQris,
                qrisCount: qrisTxs.length,
              ),
              const SizedBox(height: 20),

              // ── 4. SECTION BARU: Tombol Export PDF, Excel, Word ────
              _buildSectionTitle('Ekspor Laporan ($_selectedPeriodLabel)', isDark),
              const SizedBox(height: 10),
              _buildExportButtonsSection(context, isDark, filteredTx),
              const SizedBox(height: 20),

              // ── 5. Bar Chart Tren Omzet ───────────────────────────
              _buildBarChartSection(context, isDark, chartData),
              const SizedBox(height: 20),

              // ── 6. Statistik Tambahan ─────────────────────────────
              _buildSectionTitle('Metrik & Statistik Operasional', isDark),
              const SizedBox(height: 10),
              _buildStatisticsGrid(
                context,
                isDark,
                totalTransaksi,
                rataRataTransaksi,
                belumDiambilCount,
                kiloanCount,
                satuanCount,
              ),
              const SizedBox(height: 24),

              // ── 7. Transaksi pada Periode Ini ─────────────────────
              _buildSectionTitle(
                'Rincian Transaksi Periode Ini (${filteredTx.length})',
                isDark,
              ),
              const SizedBox(height: 10),
              if (filteredTx.isEmpty)
                _buildEmptyState(context, isDark)
              else
                ...filteredTx.take(8).map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildTransactionRowItem(context, tx, isDark),
                  );
                }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildPeriodFilterRow(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPeriodChip(
            label: 'Hari Ini',
            isSelected: _selectedPeriod == ReportPeriod.today,
            onTap: () => setState(() => _selectedPeriod = ReportPeriod.today),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPeriodChip(
            label: '7 Hari Terakhir',
            isSelected: _selectedPeriod == ReportPeriod.thisWeek,
            onTap: () => setState(() => _selectedPeriod = ReportPeriod.thisWeek),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPeriodChip(
            label: 'Bulan Ini',
            isSelected: _selectedPeriod == ReportPeriod.thisMonth,
            onTap: () => setState(() => _selectedPeriod = ReportPeriod.thisMonth),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildPeriodChip(
            label: _customDateRange != null
                ? '${DateFormat('d/M').format(_customDateRange!.start)} - ${DateFormat('d/M').format(_customDateRange!.end)}'
                : 'Kustom 📅',
            isSelected: _selectedPeriod == ReportPeriod.custom,
            onTap: _pickCustomRange,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = AppTheme.signatureColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(isDark ? 60 : 30)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.borderColor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? activeColor
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildOmzetHeroCard(
    BuildContext context,
    double totalOmzet,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withAlpha(isDark ? 80 : 50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL OMZET PERIODE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF93C5FD),
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${AppFormatters.date(_startDate)} - ${AppFormatters.date(_endDate)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppFormatters.rupiah(totalOmzet),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pendapatan kotor dari transaksi yang tercatat di sistem',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFDBEAFE),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION BARU: Breakdown Metode Pembayaran Card ────────────────────────

  Widget _buildPaymentMethodBreakdown({
    required BuildContext context,
    required bool isDark,
    required double totalOmzet,
    required int totalTx,
    required double omzetTunai,
    required int tunaiCount,
    required double omzetQris,
    required int qrisCount,
  }) {
    final pctTunai = totalOmzet > 0 ? (omzetTunai / totalOmzet) : 0.0;
    final pctQris = totalOmzet > 0 ? (omzetQris / totalOmzet) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── 1. Kartu Tunai ──
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess.withAlpha(isDark ? 35 : 18),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.statusSuccess.withAlpha(isDark ? 70 : 40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 16,
                                color: AppTheme.statusSuccess,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tunai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusSuccess,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.statusSuccess.withAlpha(40),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              '$tunaiCount Nota',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.statusSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatters.rupiah(omzetTunai),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF065F46),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(pctTunai * 100).toStringAsFixed(1)}% dari total omzet',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── 2. Kartu QRIS ──
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(isDark ? 35 : 18),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withAlpha(isDark ? 70 : 40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code_2_rounded,
                                size: 16,
                                color: Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'QRIS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withAlpha(40),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              '$qrisCount Nota',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatters.rupiah(omzetQris),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF3730A3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(pctQris * 100).toStringAsFixed(1)}% dari total omzet',
                        style: GoogleFonts.inter(
                          fontSize: 10,
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
          ),
          const SizedBox(height: 12),

          // Visual Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (totalOmzet > 0 && pctTunai > 0)
                    Expanded(
                      flex: max(1, (pctTunai * 100).toInt()),
                      child: Container(color: AppTheme.statusSuccess),
                    ),
                  if (totalOmzet > 0 && pctQris > 0)
                    Expanded(
                      flex: max(1, (pctQris * 100).toInt()),
                      child: Container(color: const Color(0xFF6366F1)),
                    ),
                  if (totalOmzet <= 0)
                    Expanded(
                      child: Container(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION BARU: Tombol Export PDF, Excel, Word ───────────────────────────

  Widget _buildExportButtonsSection(
    BuildContext context,
    bool isDark,
    List<TransactionModel> txs,
  ) {
    return Row(
      children: [
        // 1. Export PDF
        Expanded(
          child: _buildExportActionButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFEF4444),
            isLoading: _isExportingPdf,
            isDark: isDark,
            onTap: () => _exportPdf(txs),
          ),
        ),
        const SizedBox(width: 8),

        // 2. Export Excel (.xlsx)
        Expanded(
          child: _buildExportActionButton(
            label: 'Excel',
            icon: Icons.table_view_rounded,
            color: const Color(0xFF10B981),
            isLoading: _isExportingExcel,
            isDark: isDark,
            onTap: () => _exportExcel(txs),
          ),
        ),
        const SizedBox(width: 8),

        // 3. Export Word (.docx)
        Expanded(
          child: _buildExportActionButton(
            label: 'Word',
            icon: Icons.description_rounded,
            color: const Color(0xFF2563EB),
            isLoading: _isExportingWord,
            isDark: isDark,
            onTap: () => _exportWord(txs),
          ),
        ),
      ],
    );
  }

  Widget _buildExportActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 35 : 18),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withAlpha(isDark ? 70 : 40),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartSection(
    BuildContext context,
    bool isDark,
    List<_DailyRevenue> data,
  ) {
    final maxRevenue = data.isEmpty
        ? 100000.0
        : data.map((d) => d.revenue).reduce(max);
    final maxY = maxRevenue <= 0 ? 100000.0 : (maxRevenue * 1.25);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grafik Tren Omzet Harian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                'Bar Chart (Rp)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada data omzet untuk periode ini',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF1E293B),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = data[group.x.toInt()];
                            return BarTooltipItem(
                              '${item.label}\n${AppFormatters.rupiah(rod.toY)}',
                              GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              String text = '';
                              if (value >= 1000000) {
                                text = '${(value / 1000000).toStringAsFixed(1)}Jt';
                              } else if (value >= 1000) {
                                text = '${(value / 1000).toInt()}k';
                              } else {
                                text = value.toInt().toString();
                              }
                              return Text(
                                text,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppTheme.darkTextHint
                                      : AppTheme.lightTextHint,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data[index].shortDay,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: isDark
                                ? const Color(0xFF334155).withAlpha(80)
                                : const Color(0xFFE2E8F0),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (index) {
                        final item = data[index];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: item.revenue,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  isDark
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF1E3A8A),
                                  AppTheme.signatureColor(context),
                                ],
                              ),
                              width: data.length > 10 ? 10 : 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(
    BuildContext context,
    bool isDark,
    int totalTransaksi,
    double rataRataTransaksi,
    int belumDiambilCount,
    int kiloanCount,
    int satuanCount,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.receipt_long_rounded,
                title: 'Total Transaksi',
                value: '$totalTransaksi Nota',
                accentColor: AppTheme.lightPrimaryVariant,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.analytics_outlined,
                title: 'Rata-rata Nota',
                value: AppFormatters.rupiah(rataRataTransaksi),
                accentColor: AppTheme.statusSuccess,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.pending_actions_rounded,
                title: 'Cucian Belum Diambil',
                value: '$belumDiambilCount Nota',
                accentColor: AppTheme.ctaColor(context),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.pie_chart_outline_rounded,
                title: 'Kiloan vs Satuan',
                value: '$kiloanCount kg / $satuanCount pcs',
                accentColor: AppTheme.signatureColor(context),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    required bool isDark,
  }) {
    return SignatureAccentCard(
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
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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

  Widget _buildTransactionRowItem(
    BuildContext context,
    TransactionModel tx,
    bool isDark,
  ) {
    final isQris = tx.metodePembayaran.toUpperCase() == 'QRIS';
    final methodColor = isQris
        ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.signatureColor(context).withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              Icons.receipt_rounded,
              color: AppTheme.signatureColor(context),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx.customerNama,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: methodColor.withAlpha(isDark ? 35 : 20),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: methodColor.withAlpha(isDark ? 70 : 40),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tx.metodePembayaran,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: methodColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${tx.nomorNota} • ${AppFormatters.date(tx.tanggalMasuk)}',
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Text(
        'Tidak ada transaksi pada periode ini',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }

  List<_DailyRevenue> _generateChartData(
    List<TransactionModel> txs,
    DateTime start,
    DateTime end,
  ) {
    final daysCount = end.difference(start).inDays + 1;
    // Batasi maksimum 14 bar agar rapi di layar mobile
    final effectiveDays = min(max(1, daysCount), 14);

    final List<_DailyRevenue> result = [];

    for (int i = 0; i < effectiveDays; i++) {
      final currentDay = start.add(Duration(days: i));
      final dayStart = DateTime(currentDay.year, currentDay.month, currentDay.day);
      final dayEnd = DateTime(currentDay.year, currentDay.month, currentDay.day, 23, 59, 59);

      final dayTxs = txs.where((t) {
        return t.tanggalMasuk.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            t.tanggalMasuk.isBefore(dayEnd.add(const Duration(seconds: 1)));
      });

      final dayRevenue =
          dayTxs.fold<double>(0, (sum, t) => sum + t.totalHarga);

      result.add(
        _DailyRevenue(
          date: currentDay,
          label: DateFormat('d MMM', 'id_ID').format(currentDay),
          shortDay: DateFormat('d/M').format(currentDay),
          revenue: dayRevenue,
        ),
      );
    }

    return result;
  }
}

class _DailyRevenue {
  final DateTime date;
  final String label;
  final String shortDay;
  final double revenue;

  _DailyRevenue({
    required this.date,
    required this.label,
    required this.shortDay,
    required this.revenue,
  });
}
