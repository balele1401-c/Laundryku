import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/customer_model.dart';
import '../../models/enums.dart';
import '../../models/transaction_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/receipt_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/api_keys.dart';
import '../../utils/formatters.dart';
import 'edit_transaction_screen.dart';

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
        return TransactionStatus.selesai;
      case TransactionStatus.selesai:
        return TransactionStatus.sudahDiambil;
      case TransactionStatus.sudahDiambil:
        return null;
    }
  }

  Future<void> _advanceStatus(TransactionStatus next) async {
    setState(() => _isUpdating = true);
    final txProvider = context.read<TransactionProvider>();
    final customerProvider = context.read<CustomerProvider>();

    DateTime? waSentTime;

    // ── TRIGGER OTOMATIS: Kirim notifikasi WA otomatis saat cucian Selesai (siap diambil) ─
    if (next == TransactionStatus.selesai) {
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

      // Hanya kirim API otomatis jika token Fonnte sudah diisi
      if (customer.noHp.isNotEmpty && ApiKeys.fonnteToken.trim().isNotEmpty) {
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
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp. Pastikan WhatsApp terpasang.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka WhatsApp: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  Future<void> _togglePaymentStatus() async {
    final nextStatus = _currentTx.isLunas
        ? PaymentStatus.belumBayar
        : PaymentStatus.lunas;

    setState(() => _isUpdating = true);
    final success = await context
        .read<TransactionProvider>()
        .updatePaymentStatus(_currentTx.id, nextStatus);

    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (success) {
          _currentTx = _currentTx.copyWith(statusPembayaran: nextStatus);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status pembayaran diubah menjadi: ${nextStatus.label}'
                : 'Gagal memperbarui status pembayaran',
          ),
          backgroundColor:
              nextStatus == PaymentStatus.lunas ? const Color(0xFF10B981) : const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            icon: const Icon(Icons.edit_outlined),
            tooltip: _currentTx.isSudahDiambil
                ? 'Transaksi yang sudah diambil tidak dapat diedit'
                : 'Edit Transaksi',
            onPressed: _currentTx.isSudahDiambil
                ? null
                : () async {
                    final txProvider = context.read<TransactionProvider>();
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            EditTransactionScreen(transaction: _currentTx),
                      ),
                    );
                    if (updated == true && mounted) {
                      final fresh = txProvider.allTransactions.firstWhere(
                        (t) => t.id == _currentTx.id,
                        orElse: () => _currentTx,
                      );
                      setState(() => _currentTx = fresh);
                    }
                  },
          ),
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
              // ── 1. Status Pengambilan Banner (Jelas & Menonjol di Bagian Atas) ──
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: (_currentTx.isSudahDiambil
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withAlpha(isDark ? 40 : 20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: _currentTx.isSudahDiambil
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_currentTx.isSudahDiambil
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                            .withAlpha(isDark ? 50 : 30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentTx.isSudahDiambil
                            ? Icons.check_circle_rounded
                            : Icons.access_time_rounded,
                        color: _currentTx.isSudahDiambil
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentTx.isSudahDiambil
                                ? 'STATUS: SUDAH DIAMBIL'
                                : 'STATUS: BELUM DIAMBIL PELANGGAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _currentTx.isSudahDiambil
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentTx.isSudahDiambil
                                ? 'Cucian telah diserahkan sepenuhnya ke pelanggan.'
                                : (_currentTx.status == TransactionStatus.selesai
                                    ? 'Cucian sudah selesai dicuci & disetrika. Siap diambil pelanggan!'
                                    : 'Cucian masih dalam proses antrean/pengerjaan.'),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Overdue Warning Banner if applicable ───────────────
              if (isOverdue) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
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

              // ── Alert Tunggakan Pembayaran ───────────────────────
              if (_currentTx.isAttentionRequired) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withAlpha(isDark ? 45 : 20),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFFE11D48),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.priority_high_rounded,
                          color: Color(0xFFE11D48), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perhatian: Ada Tunggakan Pembayaran!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE11D48),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cucian sudah ${_currentTx.status.label.toLowerCase()}, namun pelanggan BELUM BAYAR (${AppFormatters.rupiah(_currentTx.totalHarga)}). Harap tagih pembayaran saat penyerahan cucian.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFFECDD3)
                                    : const Color(0xFF9F1239),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── 2. Progress Stepper (3 Tahap: Diterima -> Selesai -> Sudah Diambil) ─────
              _buildProgressStepperCard(context, isDark),
              const SizedBox(height: 20),

              // ── 3. Detail Nota Card ───────────────────────────────
              _buildDetailInfoCard(context, isDark),
              const SizedBox(height: 24),

              // ── 4. Advance Status CTA Button (Diterima -> Selesai -> Sudah Diambil) ──
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
                          : AppTheme.signatureColor(context),
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
                                    : Icons.done_all_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _nextStatus == TransactionStatus.selesai
                                    ? 'Tandai Cucian Selesai (Siap Diambil)'
                                    : 'Serahkan Cucian (Sudah Diambil)',
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

              // ── 5. Cetak Nota Struk (PDF) Button ──────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final customerProvider = context.read<CustomerProvider>();
                    final customer = customerProvider.allCustomers.firstWhere(
                      (c) => c.id == _currentTx.customerId,
                      orElse: () => CustomerModel(
                        id: '',
                        nama: _currentTx.customerNama,
                        noHp: '',
                        createdAt: DateTime.now(),
                      ),
                    );
                    await ReceiptService.printReceipt(
                      context,
                      _currentTx,
                      customer: customer,
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: Text(
                    'Cetak Nota Struk (PDF)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── 6. WhatsApp Notification Button ───────────────────
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
    const steps = TransactionStatus.values;
    final currentIdx = steps.indexOf(_currentTx.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppTheme.lightShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                'Status Proses Cucian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                'Langkah ${currentIdx + 1} dari ${steps.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.signatureColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            children: List.generate(steps.length, (idx) {
              final step = steps[idx];
              final isDone = idx < currentIdx;
              final isCurrent = idx == currentIdx;
              final isLast = idx == steps.length - 1;

              Color stepColor;
              if (isDone) {
                stepColor = AppTheme.statusSuccess;
              } else if (isCurrent) {
                stepColor = AppTheme.signatureColor(context);
              } else {
                stepColor = isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1);
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Node + Vertical Line
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? AppTheme.statusSuccess
                                : isCurrent
                                    ? AppTheme.signatureColor(context)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9)),
                            border: Border.all(
                              color: stepColor,
                              width: isCurrent ? 2.5 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    size: 16, color: Colors.white)
                                : Text(
                                    '${idx + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent
                                          ? Colors.white
                                          : (isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary),
                                    ),
                                  ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isDone
                                  ? AppTheme.statusSuccess
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Step Info
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: isLast ? 0 : 20, top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              step.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : (isDone
                                        ? FontWeight.w600
                                        : FontWeight.w500),
                                color: isCurrent
                                    ? (isDark
                                        ? Colors.white
                                        : AppTheme.lightPrimary)
                                    : (isDone
                                        ? (isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.lightTextPrimary)
                                        : (isDark
                                            ? AppTheme.darkTextHint
                                            : AppTheme.lightTextHint)),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.signatureColor(context)
                                      .withAlpha(isDark ? 40 : 25),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall),
                                ),
                                child: Text(
                                  'SEDANG PROSES',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.signatureColor(context),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppTheme.lightShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
          const SizedBox(height: 8),

          // Row Status Pengambilan
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pengambilan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_currentTx.isSudahDiambil
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withAlpha(isDark ? 45 : 25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: _currentTx.isSudahDiambil
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentTx.isSudahDiambil
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      size: 12,
                      color: _currentTx.isSudahDiambil
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentTx.isSudahDiambil ? 'Sudah Diambil' : 'Belum Diambil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _currentTx.isSudahDiambil
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row Status Pembayaran + Action Switch
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              InkWell(
                onTap: _isUpdating ? null : _togglePaymentStatus,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_currentTx.isLunas
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE11D48))
                        .withAlpha(isDark ? 45 : 25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: _currentTx.isLunas
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE11D48),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentTx.isLunas
                            ? Icons.verified_rounded
                            : Icons.priority_high_rounded,
                        size: 13,
                        color: _currentTx.isLunas
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentTx.isLunas ? 'Lunas' : 'Belum Bayar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _currentTx.isLunas
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.sync_rounded,
                        size: 11,
                        color: isDark
                            ? AppTheme.darkTextHint
                            : AppTheme.lightTextHint,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildRowItem(
            'Metode Pembayaran',
            _currentTx.metodePembayaran,
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

          if (_currentTx.lastEditedAt != null) ...[
            const SizedBox(height: 8),
            _buildRowItem(
              'Diedit Terakhir',
              '${AppFormatters.dateTime(_currentTx.lastEditedAt!)} oleh ${_currentTx.editedBy ?? "Kasir"}',
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
