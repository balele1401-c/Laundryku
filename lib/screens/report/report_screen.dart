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

    // Kalkulasi Total Omzet
    final totalOmzet = filteredTx.fold<double>(
        0, (sum, item) => sum + item.totalHarga);

    final totalTransaksi = filteredTx.length;
    final rataRataTransaksi =
        totalTransaksi > 0 ? totalOmzet / totalTransaksi : 0.0;

    final belumDiambilCount = filteredTx.where((t) {
      return t.status == TransactionStatus.siapDiambil ||
          t.status == TransactionStatus.prosesCuci ||
          t.status == TransactionStatus.prosesSetrika ||
          t.status == TransactionStatus.diterima;
    }).length;

    final kiloanCount = filteredTx
        .where((t) => t.tipeLayanan == ServiceType.kiloan)
        .length;
    final satuanCount = filteredTx
        .where((t) => t.tipeLayanan == ServiceType.satuan)
        .length;

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
              const SizedBox(height: 20),

              // ── 3. Bar Chart Tren Omzet ───────────────────────────
              _buildBarChartSection(context, isDark, chartData),
              const SizedBox(height: 20),

              // ── 4. Statistik Tambahan ─────────────────────────────
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

              // ── 5. Transaksi pada Periode Ini ─────────────────────
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
