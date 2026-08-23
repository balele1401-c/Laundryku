import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../models/service_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/accent_card.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  ServiceModel? _selectedService;

  late double _berat;
  late int _qty;
  late final TextEditingController _beratTextController;
  late final TextEditingController _qtyTextController;
  Timer? _debounceTimer;

  // Add-ons
  bool _addonParfum = false;
  final double _hargaParfum = 5000;

  bool _addonExpress = false;
  final double _hargaExpress = 10000;

  bool _addonAntiBakteri = false;
  final double _hargaAntiBakteri = 3000;

  // Metode Pembayaran: "Tunai" dan "QRIS"
  late String _metodePembayaran;

  // Status Pembayaran: Lunas atau Belum Bayar
  late PaymentStatus _statusPembayaran;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _berat = tx.berat ?? 3.0;
    _qty = tx.qty ?? 1;
    _beratTextController = TextEditingController(
      text: tx.berat != null ? tx.berat.toString() : '3.0',
    );
    _qtyTextController = TextEditingController(
      text: tx.qty != null ? tx.qty.toString() : '1',
    );

    _metodePembayaran = tx.metodePembayaran;
    _statusPembayaran = tx.statusPembayaran;

    // Deteksi addon dari nama layanan tersimpan
    final jenisLower = tx.jenisLayanan.toLowerCase();
    if (jenisLower.contains('parfum')) _addonParfum = true;
    if (jenisLower.contains('express')) _addonExpress = true;
    if (jenisLower.contains('anti bakteri')) _addonAntiBakteri = true;

    // Match initial service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serviceProvider = context.read<ServiceProvider>();
      final services = serviceProvider.allServices;
      if (services.isNotEmpty) {
        final match = services.firstWhere(
          (s) => tx.jenisLayanan.toLowerCase().contains(s.namaLayanan.toLowerCase()),
          orElse: () => services.firstWhere(
            (s) => s.tipe == tx.tipeLayanan,
            orElse: () => services.first,
          ),
        );
        setState(() {
          _selectedService = match;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _beratTextController.dispose();
    _qtyTextController.dispose();
    super.dispose();
  }

  double get _baseTotal {
    if (_selectedService == null) {
      return widget.transaction.hargaSatuan *
          (widget.transaction.tipeLayanan == ServiceType.kiloan ? _berat : _qty);
    }
    if (_selectedService!.tipe == ServiceType.kiloan) {
      return _selectedService!.harga * _berat;
    } else {
      return _selectedService!.harga * _qty;
    }
  }

  double get _addonsTotal {
    double total = 0;
    if (_addonParfum) total += _hargaParfum;
    if (_addonExpress) total += _hargaExpress;
    if (_addonAntiBakteri) total += _hargaAntiBakteri;
    return total;
  }

  double get _grandTotal => _baseTotal + _addonsTotal;

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_grandTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total transaksi tidak boleh Rp 0'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Jika transaksi lama sudah Lunas dan metode pembayaran atau status pembayaran diubah, beri peringatan konfirmasi
    final tx = widget.transaction;
    final isChangingPaidStatus = tx.isLunas &&
        (_statusPembayaran != PaymentStatus.lunas || _metodePembayaran != tx.metodePembayaran);

    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();

    if (isChangingPaidStatus) {
      final signatureColor = AppTheme.signatureColor(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.statusWarning, size: 28),
              const SizedBox(width: 10),
              Text(
                'Konfirmasi Perubahan',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            'Transaksi ini sebelumnya berstatus LUNAS (${tx.metodePembayaran}). '
            'Anda mengubah metode/status pembayaran menjadi $_metodePembayaran (${_statusPembayaran.label}). Lanjutkan?',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: signatureColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Ya, Simpan Perubahan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    final serviceName = _selectedService != null
        ? _selectedService!.namaLayanan
        : widget.transaction.jenisLayanan;
    final serviceType = _selectedService != null
        ? _selectedService!.tipe
        : widget.transaction.tipeLayanan;
    final unitPrice = _selectedService != null
        ? _selectedService!.harga
        : widget.transaction.hargaSatuan;

    List<String> addonsList = [];
    if (_addonParfum) addonsList.add('Parfum Premium');
    if (_addonExpress) addonsList.add('Express 1 Hari');
    if (_addonAntiBakteri) addonsList.add('Anti Bakteri');

    String fullServiceName = serviceName;
    if (addonsList.isNotEmpty) {
      fullServiceName += ' (+${addonsList.join(", ")})';
    }

    final success = await txProvider.updateTransactionDetails(
      transactionId: widget.transaction.id,
      jenisLayanan: fullServiceName,
      tipeLayanan: serviceType,
      berat: serviceType == ServiceType.kiloan ? _berat : null,
      qty: serviceType == ServiceType.satuan ? _qty : null,
      hargaSatuan: unitPrice,
      totalHarga: _grandTotal,
      metodePembayaran: _metodePembayaran,
      statusPembayaran: _statusPembayaran,
      editedBy: auth.currentUser?.nama ?? 'Kasir / Owner',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Perubahan transaksi ${widget.transaction.nomorNota} berhasil disimpan!',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            txProvider.errorMessage ?? 'Gagal menyimpan perubahan transaksi',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.statusError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final serviceProvider = context.watch<ServiceProvider>();
    final services = serviceProvider.allServices;
    final tx = widget.transaction;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Transaksi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info Readonly Nota & Pelanggan ─────────────────────────
                _buildReadonlyInfoCard(context, isDark, tx),
                const SizedBox(height: 20),

                // ── Paket Layanan ─────────────────────────────────────────
                _buildSectionHeader('Paket Layanan', isDark),
                const SizedBox(height: 8),
                _buildServiceSection(context, isDark, services),
                const SizedBox(height: 20),

                // ── Berat / Qty Manual Input ──────────────────────────────
                if (_selectedService != null || true) ...[
                  _buildSectionHeader(
                    (_selectedService?.tipe ?? tx.tipeLayanan) == ServiceType.kiloan
                        ? 'Timbangan Berat (kg)'
                        : 'Jumlah Potong (pcs)',
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildQuantitySection(context, isDark),
                  const SizedBox(height: 20),

                  // ── Layanan Tambahan (Add-ons) ──────────────────────────
                  _buildSectionHeader('Layanan Ekstra / Add-ons', isDark),
                  const SizedBox(height: 8),
                  _buildAddonsSection(context, isDark),
                  const SizedBox(height: 20),
                ],

                // ── Metode Pembayaran ─────────────────────────────────────
                _buildSectionHeader('Metode Pembayaran', isDark),
                const SizedBox(height: 8),
                _buildPaymentMethodSection(context, isDark),
                const SizedBox(height: 20),

                // ── Status Pembayaran ─────────────────────────────────────
                _buildSectionHeader('Status Pembayaran', isDark),
                const SizedBox(height: 8),
                _buildPaymentStatusSection(context, isDark),
                const SizedBox(height: 24),

                // ── Real-time Calculation Card ───────────────────────────
                _buildCalculationCard(context, isDark),
                const SizedBox(height: 24),

                // ── Submit Button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ctaColor(context),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: _isSaving
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
                              const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Simpan Perubahan Transaksi',
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildReadonlyInfoCard(BuildContext context, bool isDark, TransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                'Informasi Nota (Readonly)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.signatureColor(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'KUNCI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildInfoRow('Nomor Nota', tx.nomorNota, isBold: true),
          const SizedBox(height: 6),
          _buildInfoRow('Nama Pelanggan', tx.customerNama, isBold: true),
          const SizedBox(height: 6),
          _buildInfoRow('Tanggal Masuk', AppFormatters.dateTime(tx.tanggalMasuk)),
          const SizedBox(height: 6),
          _buildInfoRow('Kasir Pembuat', tx.createdBy.isNotEmpty ? tx.createdBy : 'Kasir'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSection(
    BuildContext context,
    bool isDark,
    List<ServiceModel> services,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: services.isEmpty
          ? Center(
              child: Text(
                widget.transaction.jenisLayanan,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            )
          : DropdownButtonFormField<ServiceModel>(
              initialValue: _selectedService,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintText: 'Pilih jenis paket layanan...',
                prefixIcon: Icon(Icons.dry_cleaning_outlined, size: 20),
              ),
              items: services.map((s) {
                final isKiloan = s.tipe == ServiceType.kiloan;
                return DropdownMenuItem<ServiceModel>(
                  value: s,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.namaLayanan,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${AppFormatters.rupiah(s.harga)} / ${isKiloan ? "kg" : "pcs"}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.signatureColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedService = val;
                });
              },
            ),
    );
  }

  Widget _buildQuantitySection(BuildContext context, bool isDark) {
    final effectiveType = _selectedService?.tipe ?? widget.transaction.tipeLayanan;
    final effectivePrice = _selectedService?.harga ?? widget.transaction.hargaSatuan;
    final isKiloan = effectiveType == ServiceType.kiloan;

    return SignatureAccentCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isKiloan ? 'Input Berat Cucian' : 'Input Jumlah Pakaian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.signatureColor(context).withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  isKiloan
                      ? 'Tarif @ ${AppFormatters.rupiah(effectivePrice)} / kg'
                      : 'Tarif @ ${AppFormatters.rupiah(effectivePrice)} / pcs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.signatureColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isKiloan)
            TextFormField(
              controller: _beratTextController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Berat Cucian (kg)',
                hintText: 'Contoh: 3.5',
                prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                suffixText: 'kg',
                suffixStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.signatureColor(context),
                ),
                helperText: 'Maksimal 2 angka desimal (cth: 3.25)',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Berat cucian wajib diisi';
                }
                final cleaned = val.replaceAll(',', '.').trim();
                final parsed = double.tryParse(cleaned);
                if (parsed == null || parsed <= 0) {
                  return 'Berat harus berupa angka lebih dari 0 kg';
                }
                return null;
              },
              onChanged: (val) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  final cleaned = val.replaceAll(',', '.').trim();
                  final parsed = double.tryParse(cleaned);
                  if (parsed != null && parsed > 0 && mounted) {
                    setState(() {
                      _berat = parsed;
                    });
                  }
                });
              },
            )
          else
            TextFormField(
              controller: _qtyTextController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Jumlah Potong (pcs)',
                hintText: 'Contoh: 5',
                prefixIcon: const Icon(Icons.checkroom_outlined, size: 20),
                suffixText: 'pcs',
                suffixStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.signatureColor(context),
                ),
                helperText: 'Masukkan jumlah potong pakaian',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Jumlah pakaian wajib diisi';
                }
                final parsed = int.tryParse(val.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Jumlah harus minimal 1 pcs';
                }
                return null;
              },
              onChanged: (val) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  final parsed = int.tryParse(val.trim());
                  if (parsed != null && parsed > 0 && mounted) {
                    setState(() {
                      _qty = parsed;
                    });
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAddonsSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: _addonParfum,
            onChanged: (val) => setState(() => _addonParfum = val ?? false),
            title: Text(
              'Parfum Premium',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '+ ${AppFormatters.rupiah(_hargaParfum)} (Aroma tahan lama)',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            secondary: const Icon(Icons.local_florist_outlined, color: Color(0xFFEC4899)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const Divider(height: 8),
          CheckboxListTile(
            value: _addonExpress,
            onChanged: (val) => setState(() => _addonExpress = val ?? false),
            title: Text(
              'Layanan Express 1 Hari',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '+ ${AppFormatters.rupiah(_hargaExpress)} (Prioritas 24 jam)',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            secondary: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const Divider(height: 8),
          CheckboxListTile(
            value: _addonAntiBakteri,
            onChanged: (val) => setState(() => _addonAntiBakteri = val ?? false),
            title: Text(
              'Anti Bakteri & Tungau',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '+ ${AppFormatters.rupiah(_hargaAntiBakteri)} (Disinfektan higienis)',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            secondary: const Icon(Icons.sanitizer_outlined, color: Color(0xFF10B981)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPaymentMethodChip(
              context: context,
              label: 'Tunai',
              icon: Icons.payments_outlined,
              isSelected: _metodePembayaran == 'Tunai',
              onTap: () => setState(() => _metodePembayaran = 'Tunai'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPaymentMethodChip(
              context: context,
              label: 'QRIS',
              icon: Icons.qr_code_2_rounded,
              isSelected: _metodePembayaran == 'QRIS',
              onTap: () => setState(() => _metodePembayaran = 'QRIS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.signatureColor(context).withAlpha(isDark ? 50 : 30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppTheme.signatureColor(context)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppTheme.signatureColor(context)
                  : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.signatureColor(context)
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPaymentStatusChip(
              context: context,
              label: 'Lunas',
              icon: Icons.check_circle_rounded,
              activeColor: AppTheme.statusSuccess,
              isSelected: _statusPembayaran == PaymentStatus.lunas,
              onTap: () => setState(() => _statusPembayaran = PaymentStatus.lunas),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPaymentStatusChip(
              context: context,
              label: 'Belum Bayar',
              icon: Icons.pending_outlined,
              activeColor: AppTheme.statusError,
              isSelected: _statusPembayaran == PaymentStatus.belumBayar,
              onTap: () => setState(() => _statusPembayaran = PaymentStatus.belumBayar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(isDark ? 50 : 25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationCard(BuildContext context, bool isDark) {
    final effectiveType = _selectedService?.tipe ?? widget.transaction.tipeLayanan;
    final isKiloan = effectiveType == ServiceType.kiloan;
    final qtyLabel = isKiloan ? '$_berat kg' : '$_qty pcs';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Layanan Utama ($qtyLabel)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Text(
                AppFormatters.rupiah(_baseTotal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          if (_addonsTotal > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biaya Tambahan (Add-ons)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  '+ ${AppFormatters.rupiah(_addonsTotal)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL HARGA REVISI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Metode: $_metodePembayaran • ${_statusPembayaran.label}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.signatureColor(context),
                    ),
                  ),
                ],
              ),
              Text(
                AppFormatters.rupiah(_grandTotal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkPrimary
                      : AppTheme.lightPrimaryVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
