import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/customer_model.dart';
import '../../models/transaction_model.dart';
import '../../models/enums.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/accent_card.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TransactionModel _currentTx;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentTx = widget.transaction;
  }

  TransactionStatus? get _nextStatus {
    switch (_currentTx.status) {
      case TransactionStatus.diterima:
        return TransactionStatus.prosesCuci;
      case TransactionStatus.prosesCuci:
        return TransactionStatus.prosesSetrika;
      case TransactionStatus.prosesSetrika:
        return TransactionStatus.siapDiambil;
      case TransactionStatus.siapDiambil:
        return TransactionStatus.selesai;
      case TransactionStatus.selesai:
        return null;
    }
  }

  Future<void> _advanceStatus(TransactionStatus next) async {
    setState(() => _isUpdating = true);
    final txProvider = context.read<TransactionProvider>();
    final customerProvider = context.read<CustomerProvider>();

    DateTime? waSentTime;

    // ── TRIGGER OTOMATIS: Kirim notifikasi WA saat status 'siapDiambil' ─
    if (next == TransactionStatus.siapDiambil) {
      final customer = customerProvider.allCustomers.firstWhere(
        (c) => c.id == _currentTx.customerId,
        orElse: () => customerProvider.customers.firstWhere(
          (c) => c.nama == _currentTx.customerNama,
          orElse: () => CustomerModel(
            id: '',
            nama: _currentTx.customerNama,
            noHp: '',
            createdAt: DateTime.now(),
          ),
        ),
      );

      if (customer.noHp.isNotEmpty) {
        final readyMsg = WhatsAppService.generateReadyMessage(
          nama: _currentTx.customerNama,
          nomorNota: _currentTx.nomorNota,
          totalHarga: _currentTx.totalHarga,
        );

        final waResult = await WhatsAppService.sendMessage(
          noHp: customer.noHp,
          pesan: readyMsg,
        );

        if (waResult.isSuccess) {
          waSentTime = DateTime.now();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notifikasi WhatsApp otomatis terkirim ke ${customer.noHp}',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.statusSuccess,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notifikasi WA tidak terkirim: ${waResult.message ?? "Kendala API"}',
                        style: GoogleFonts.inter(),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.statusWarning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }

    final success = await txProvider.updateStatus(
      _currentTx.id,
      next,
      waNotifSentAt: waSentTime,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (success) {
      setState(() {
        _currentTx = _currentTx.copyWith(
          status: next,
          waNotifSentAt: waSentTime ?? _currentTx.waNotifSentAt,
          updatedAt: DateTime.now(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status nota ${_currentTx.nomorNota} diperbarui ke "${next.label}"',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            txProvider.errorMessage ?? 'Gagal memperbarui status',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.statusError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openWhatsAppMessage() async {
    final customerProvider = context.read<CustomerProvider>();
    final customer = customerProvider.allCustomers.firstWhere(
      (c) => c.id == _currentTx.customerId,
      orElse: () => customerProvider.customers.firstWhere(
        (c) => c.nama == _currentTx.customerNama,
        orElse: () => CustomerModel(
          id: '',
          nama: _currentTx.customerNama,
          noHp: '',
          createdAt: DateTime.now(),
        ),
      ),
    );

    if (customer.noHp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp pelanggan tidak ditemukan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String cleaned = customer.noHp.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }

    final message = '''
Halo Kak ${_currentTx.customerNama},
Berikut informasi status laundry Anda di *LaundryKu*:

📄 *Nota*: ${_currentTx.nomorNota}
🧺 *Layanan*: ${_currentTx.jenisLayanan}
💰 *Total*: ${AppFormatters.rupiah(_currentTx.totalHarga)}
📌 *Status Saat Ini*: *${_currentTx.status.label.toUpperCase()}*
⏱ *Estimasi Selesai*: ${AppFormatters.date(_currentTx.estimasiSelesai)}

Terima kasih telah mempercayakan cucian Anda kepada kami! 🙏
''';

    final url = Uri.parse(
        'https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          'Hapus Transaksi?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus nota "${_currentTx.nomorNota}"? Tindakan ini tidak dapat dibatalkan.',
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

    if (confirmed == true && mounted) {
      await context
          .read<TransactionProvider>()
          .deleteTransaction(_currentTx.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus'),
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

    final isOverdue = _currentTx.status != TransactionStatus.selesai &&
        DateTime.now().isAfter(_currentTx.estimasiSelesai);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _currentTx.nomorNota,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Kirim Notifikasi WhatsApp',
            onPressed: _openWhatsAppMessage,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Hapus Nota',
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Overdue Warning Banner if applicable ───────────
              if (isOverdue) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.statusError.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.statusError,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.statusError, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Perhatian: Pesanan ini telah melewati estimasi waktu selesai (${AppFormatters.date(_currentTx.estimasiSelesai)}). Harap segera diproses!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFFCA5A5)
                                : AppTheme.statusError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── 2. Progress Stepper (5 Tahap) ─────────────────────
              _buildProgressStepperCard(context, isDark),
              const SizedBox(height: 20),

              // ── 3. Detail Nota Card ───────────────────────────────
              _buildDetailInfoCard(context, isDark),
              const SizedBox(height: 24),

              // ── 4. Advance Status CTA Button ──────────────────────
              if (_nextStatus != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _isUpdating ? null : () => _advanceStatus(_nextStatus!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _nextStatus == TransactionStatus.selesai
                          ? AppTheme.statusSuccess
                          : AppTheme.ctaColor(context),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _nextStatus == TransactionStatus.selesai
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lanjut ke: ${_nextStatus!.label}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── 5. WhatsApp Notification Button ───────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openWhatsAppMessage,
                  icon: const Icon(
                    Icons.chat_outlined,
                    color: AppTheme.statusSuccess,
                    size: 20,
                  ),
                  label: Text(
                    'Kirim Nota ke WhatsApp Pelanggan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusSuccess,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppTheme.statusSuccess, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepperCard(BuildContext context, bool isDark) {
    final stages = [
      TransactionStatus.diterima,
      TransactionStatus.prosesCuci,
      TransactionStatus.prosesSetrika,
      TransactionStatus.siapDiambil,
      TransactionStatus.selesai,
    ];

    final currentIndex = stages.indexOf(_currentTx.status);

    return SignatureAccentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alur Proses Laundry',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.signatureColor(context)
                      .withAlpha(isDark ? 40 : 25),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  _currentTx.status.label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.signatureColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Horizontal Stepper Bar
          Row(
            children: List.generate(stages.length * 2 - 1, (index) {
              // Even index: Stage Node
              if (index.isEven) {
                final stageIndex = index ~/ 2;
                final isCompleted = stageIndex <= currentIndex;
                final isCurrent = stageIndex == currentIndex;

                return Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? (isCurrent
                                ? AppTheme.ctaColor(context)
                                : AppTheme.signatureColor(context))
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        border: isCurrent
                            ? Border.all(
                                color: Colors.white,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? (isCurrent
                                ? Text(
                                    '${stageIndex + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : const Icon(Icons.check,
                                    size: 16, color: Colors.white))
                            : Text(
                                '${stageIndex + 1}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextHint
                                      : AppTheme.lightTextHint,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getShortStageName(stages[stageIndex]),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent
                            ? (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary)
                            : (isDark
                                ? AppTheme.darkTextHint
                                : AppTheme.lightTextHint),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }

              // Odd index: Connecting Line
              final prevStageIndex = (index - 1) ~/ 2;
              final isLineActive = prevStageIndex < currentIndex;

              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: isLineActive
                      ? AppTheme.signatureColor(context)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getShortStageName(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.diterima:
        return 'Diterima';
      case TransactionStatus.prosesCuci:
        return 'Cuci';
      case TransactionStatus.prosesSetrika:
        return 'Setrika';
      case TransactionStatus.siapDiambil:
        return 'Siap';
      case TransactionStatus.selesai:
        return 'Selesai';
    }
  }

  Widget _buildDetailInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informasi Lengkap Transaksi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              if (_currentTx.waNotifSentAt != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppTheme.statusSuccess.withAlpha(isDark ? 80 : 50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.statusSuccess, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'WA Terkirim',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildRowItem('Nomor Nota', _currentTx.nomorNota, isDark),
          const SizedBox(height: 8),
          _buildRowItem('Nama Pelanggan', _currentTx.customerNama, isDark),
          const SizedBox(height: 8),
          _buildRowItem('Jenis Layanan', _currentTx.jenisLayanan, isDark),
          const SizedBox(height: 8),
          _buildRowItem(
            'Kuantitas / Berat',
            _currentTx.tipeLayanan == ServiceType.kiloan
                ? '${_currentTx.berat ?? "-"} kg'
                : '${_currentTx.qty ?? "-"} pcs',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildRowItem(
            'Tarif Satuan',
            AppFormatters.rupiah(_currentTx.hargaSatuan),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildRowItem(
            'Waktu Masuk',
            AppFormatters.dateTime(_currentTx.tanggalMasuk),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildRowItem(
            'Estimasi Selesai',
            AppFormatters.date(_currentTx.estimasiSelesai),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildRowItem(
            'Kasir Bertugas',
            _currentTx.createdBy.isNotEmpty ? _currentTx.createdBy : 'Kasir',
            isDark,
          ),

          if (_currentTx.waNotifSentAt != null) ...[
            const SizedBox(height: 8),
            _buildRowItem(
              'Notif WhatsApp',
              AppFormatters.dateTime(_currentTx.waNotifSentAt!),
              isDark,
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Total Bayar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL BIAYA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightPrimary,
                ),
              ),
              Text(
                AppFormatters.rupiah(_currentTx.totalHarga),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
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
    );
  }

  Widget _buildRowItem(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
