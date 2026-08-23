import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/customer_model.dart';
import '../../models/service_model.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/receipt_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/accent_card.dart';

class TransactionFormScreen extends StatefulWidget {
  final CustomerModel? preselectedCustomer;

  const TransactionFormScreen({super.key, this.preselectedCustomer});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerModel? _selectedCustomer;
  ServiceModel? _selectedService;

  double _berat = 3.0; // default 3.0 kg untuk kiloan
  int _qty = 1; // default 1 pcs untuk satuan
  final TextEditingController _beratTextController =
      TextEditingController(text: '3.0');
  final TextEditingController _qtyTextController =
      TextEditingController(text: '1');
  Timer? _debounceTimer;

  // Add-ons
  bool _addonParfum = false;
  final double _hargaParfum = 5000;

  bool _addonExpress = false;
  final double _hargaExpress = 10000;

  bool _addonAntiBakteri = false;
  final double _hargaAntiBakteri = 3000;

  // Metode Pembayaran: HANYA 2 opsi ("Tunai" dan "QRIS")
  String _metodePembayaran = 'Tunai';

  // Status Pembayaran: Lunas atau Belum Bayar
  PaymentStatus _statusPembayaran = PaymentStatus.lunas;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _beratTextController.dispose();
    _qtyTextController.dispose();
    super.dispose();
  }

  double get _baseTotal {
    if (_selectedService == null) return 0;
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

  int get _effectiveEstimasiHari {
    if (_selectedService == null) return 1;
    if (_addonExpress) {
      return 1; // Express langsung 1 hari
    }
    return _selectedService!.estimasiHari;
  }

  DateTime get _estimatedCompletionDate {
    return DateTime.now().add(Duration(days: _effectiveEstimasiHari));
  }

  Future<void> _openQuickAddCustomerDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isDialogSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor:
                isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              side: BorderSide(color: AppTheme.borderColor(context)),
            ),
            title: Text(
              'Tambah Pelanggan Cepat',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Form(
              key: dialogFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Nama Pelanggan',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: AppValidators.validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Nomor WhatsApp / HP',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    validator: AppValidators.validatePhone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isDialogSaving
                    ? null
                    : () async {
                        if (!dialogFormKey.currentState!.validate()) return;
                        setDialogState(() => isDialogSaving = true);

                        final provider = context.read<CustomerProvider>();
                        final success = await provider.addCustomer(
                          nama: nameCtrl.text,
                          noHp: phoneCtrl.text,
                        );

                        if (mounted) {
                          setDialogState(() => isDialogSaving = false);
                          if (success) {
                            // Temukan customer yang baru dibuat
                            final newCust = provider.customers.firstWhere(
                              (c) => c.nama.trim() == nameCtrl.text.trim(),
                              orElse: () => CustomerModel(
                                id: '',
                                nama: nameCtrl.text.trim(),
                                noHp: phoneCtrl.text.trim(),
                                createdAt: DateTime.now(),
                              ),
                            );
                            setState(() => _selectedCustomer = newCust);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ctaColor(context),
                  foregroundColor: Colors.white,
                ),
                child: isDialogSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomerPickerSheet() {
    final customerProvider = context.read<CustomerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final list = customerProvider.allCustomers.where((c) {
            if (query.isEmpty) return true;
            final q = query.toLowerCase();
            return c.nama.toLowerCase().contains(q) || c.noHp.contains(q);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SizedBox(
              height: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilih Pelanggan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search Bar
                  TextField(
                    onChanged: (val) {
                      setSheetState(() => query = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau nomor HP...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick add button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openQuickAddCustomerDialog();
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('+ Tambah Pelanggan Baru'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Text(
                              'Pelanggan tidak ditemukan',
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final c = list[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.signatureColor(context)
                                          .withAlpha(40),
                                  child: Text(
                                    c.nama.isNotEmpty
                                        ? c.nama[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppTheme.signatureColor(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  c.nama,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  c.noHp,
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${c.totalTransaksi}x cuci',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.signatureColor(context),
                                  ),
                                ),
                                onTap: () {
                                  setState(() => _selectedCustomer = c);
                                  Navigator.of(ctx).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSaveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih pelanggan terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih layanan laundry terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();

    String serviceNameWithAddons = _selectedService!.namaLayanan;
    List<String> addonsList = [];
    if (_addonParfum) addonsList.add('Parfum Premium');
    if (_addonExpress) addonsList.add('Express 1 Hari');
    if (_addonAntiBakteri) addonsList.add('Anti Bakteri');

    if (addonsList.isNotEmpty) {
      serviceNameWithAddons += ' (+${addonsList.join(", ")})';
    }

    final createdTx = await txProvider.createTransaction(
      customerId: _selectedCustomer!.id,
      customerNama: _selectedCustomer!.nama,
      jenisLayanan: serviceNameWithAddons,
      tipeLayanan: _selectedService!.tipe,
      berat: _selectedService!.tipe == ServiceType.kiloan ? _berat : null,
      qty: _selectedService!.tipe == ServiceType.satuan ? _qty : null,
      hargaSatuan: _selectedService!.harga,
      totalHarga: _grandTotal,
      metodePembayaran: _metodePembayaran,
      statusPembayaran: _statusPembayaran,
      estimasiHari: _effectiveEstimasiHari,
      createdBy: auth.currentUser?.nama ?? 'Kasir',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (createdTx != null) {
      final savedCustomer = _selectedCustomer;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.statusSuccess.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.statusSuccess,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transaksi Berhasil!',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nota: ${createdTx.nomorNota}',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.signatureColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pelanggan: ${createdTx.customerNama}',
                style: GoogleFonts.inter(fontSize: 13),
              ),
              Text(
                'Total: ${AppFormatters.rupiah(createdTx.totalHarga)} (${createdTx.metodePembayaran} • ${createdTx.statusPembayaran.label})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Apakah Anda ingin langsung mencetak nota struk transaksi ini?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                await ReceiptService.printReceipt(
                  context,
                  createdTx,
                  customer: savedCustomer,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.signatureColor(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(
                'Cetak Nota Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            txProvider.errorMessage ?? 'Gagal membuat transaksi',
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Input Transaksi Baru',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Data Pelanggan ──────────────────────────────
                  _buildSectionHeader('Data Pelanggan', isDark),
                  const SizedBox(height: 8),
                  _buildCustomerSection(context, isDark),
                  const SizedBox(height: 20),

                  // ── Paket Layanan ───────────────────────────────
                  _buildSectionHeader('Paket Layanan', isDark),
                  const SizedBox(height: 8),
                  _buildServiceSection(context, isDark, services),
                  const SizedBox(height: 20),

                  // ── Berat / Qty Stepper ──────────────────────────
                  if (_selectedService != null) ...[
                    _buildSectionHeader(
                      _selectedService!.tipe == ServiceType.kiloan
                          ? 'Timbangan Berat (kg)'
                          : 'Jumlah Potong (pcs)',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildQuantitySection(context, isDark),
                    const SizedBox(height: 20),

                    // ── Layanan Tambahan (Add-ons) ──────────────────
                    _buildSectionHeader('Layanan Ekstra / Add-ons', isDark),
                    const SizedBox(height: 8),
                    _buildAddonsSection(context, isDark),
                    const SizedBox(height: 20),
                  ],

                  // ── Metode Pembayaran (HANYA Tunai & QRIS) ───────
                  _buildSectionHeader('Metode Pembayaran', isDark),
                  const SizedBox(height: 8),
                  _buildPaymentMethodSection(context, isDark),
                  const SizedBox(height: 20),

                  // ── Status Pembayaran (Lunas / Belum Bayar) ───────
                  _buildSectionHeader('Status Pembayaran', isDark),
                  const SizedBox(height: 8),
                  _buildPaymentStatusSection(context, isDark),
                  const SizedBox(height: 24),

                  // ── 7. Real-time Calculation Card ─────────────────
                  _buildCalculationCard(context, isDark),
                  const SizedBox(height: 24),

                  // ── 8. Submit Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSaveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ctaColor(context),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
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
                                const Icon(Icons.print_outlined,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Simpan & Buat Nota Transaksi',
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

  Widget _buildCustomerSection(BuildContext context, bool isDark) {
    return SignatureAccentCard(
      onTap: _showCustomerPickerSheet,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.signatureColor(context)
                  .withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              Icons.person_pin_circle_outlined,
              color: AppTheme.signatureColor(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _selectedCustomer == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Pelanggan...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Cari nama atau no. WhatsApp',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextHint
                              : AppTheme.lightTextHint,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCustomer!.noHp,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.lightTextHint,
          ),
        ],
      ),
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
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Belum ada layanan di katalog. Tambahkan di menu Owner.',
                  style: GoogleFonts.inter(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : DropdownButtonFormField<ServiceModel>(
              initialValue: _selectedService,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    final isKiloan = _selectedService!.tipe == ServiceType.kiloan;

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
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.signatureColor(context)
                      .withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  isKiloan
                      ? 'Tarif @ ${AppFormatters.rupiah(_selectedService!.harga)} / kg'
                      : 'Tarif @ ${AppFormatters.rupiah(_selectedService!.harga)} / pcs',
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            title: Text(
              'Parfum Premium Extra Wangi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '+${AppFormatters.rupiah(_hargaParfum)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.statusSuccess,
                fontWeight: FontWeight.w600,
              ),
            ),
            dense: true,
            activeColor: AppTheme.signatureColor(context),
            onChanged: (val) => setState(() => _addonParfum = val ?? false),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            value: _addonExpress,
            title: Text(
              'Layanan Express (1 Hari Selesai)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '+${AppFormatters.rupiah(_hargaExpress)} (Prioritas)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.ctaColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            dense: true,
            activeColor: AppTheme.ctaColor(context),
            onChanged: (val) => setState(() => _addonExpress = val ?? false),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            value: _addonAntiBakteri,
            title: Text(
              'Cairan Anti Bakteri & Tungau',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '+${AppFormatters.rupiah(_hargaAntiBakteri)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.signatureColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            dense: true,
            activeColor: AppTheme.signatureColor(context),
            onChanged: (val) =>
                setState(() => _addonAntiBakteri = val ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDark
              ? const Color(0xFF38BDF8).withAlpha(60)
              : const Color(0xFF38BDF8).withAlpha(90),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppTheme.lightShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
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
                'Rincian Biaya Transaksi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.signatureColor(context)
                      .withAlpha(isDark ? 40 : 25),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Auto-Calculate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.signatureColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Paket Dasar
          _buildCalcRow(
            'Biaya Paket (${_selectedService?.namaLayanan ?? "Belum dipilih"})',
            AppFormatters.rupiah(_baseTotal),
            isDark,
          ),
          if (_addonsTotal > 0) ...[
            const SizedBox(height: 6),
            _buildCalcRow(
              'Biaya Layanan Tambahan (Add-ons)',
              '+${AppFormatters.rupiah(_addonsTotal)}',
              isDark,
            ),
          ],
          const SizedBox(height: 6),
          _buildCalcRow(
            'Metode Pembayaran',
            _metodePembayaran,
            isDark,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL PEMBAYARAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                AppFormatters.rupiah(_grandTotal),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppTheme.darkPrimary
                      : AppTheme.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Estimasi Selesai Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0284C7).withAlpha(40)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF0284C7).withAlpha(80)
                    : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppTheme.lightPrimaryVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimasi Selesai: ${AppFormatters.date(_estimatedCompletionDate)} ($_effectiveEstimasiHari Hari)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Opsi 1: Tunai
        Expanded(
          child: _buildPaymentMethodOption(
            context: context,
            isDark: isDark,
            title: 'Tunai',
            subtitle: 'Cash saat bayar/ambil',
            icon: Icons.payments_outlined,
            isSelected: _metodePembayaran == 'Tunai',
            accentColor: AppTheme.statusSuccess,
            onTap: () => setState(() => _metodePembayaran = 'Tunai'),
          ),
        ),
        const SizedBox(width: 12),
        // Opsi 2: QRIS
        Expanded(
          child: _buildPaymentMethodOption(
            context: context,
            isDark: isDark,
            title: 'QRIS',
            subtitle: 'Scan QR e-Wallet/Bank',
            icon: Icons.qr_code_scanner_rounded,
            isSelected: _metodePembayaran == 'QRIS',
            accentColor: AppTheme.signatureColor(context),
            onTap: () => setState(() => _metodePembayaran = 'QRIS'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusSection(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Opsi 1: Lunas
        Expanded(
          child: _buildPaymentMethodOption(
            context: context,
            isDark: isDark,
            title: 'Lunas',
            subtitle: 'Sudah dibayar sekarang',
            icon: Icons.check_circle_outline_rounded,
            isSelected: _statusPembayaran == PaymentStatus.lunas,
            accentColor: const Color(0xFF10B981),
            onTap: () =>
                setState(() => _statusPembayaran = PaymentStatus.lunas),
          ),
        ),
        const SizedBox(width: 12),
        // Opsi 2: Belum Bayar
        Expanded(
          child: _buildPaymentMethodOption(
            context: context,
            isDark: isDark,
            title: 'Belum Bayar',
            subtitle: 'Bayar nanti / saat ambil',
            icon: Icons.schedule_rounded,
            isSelected: _statusPembayaran == PaymentStatus.belumBayar,
            accentColor: const Color(0xFFF59E0B),
            onTap: () =>
                setState(() => _statusPembayaran = PaymentStatus.belumBayar),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withAlpha(isDark ? 45 : 25)
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withAlpha(isDark ? 60 : 30)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? accentColor
                        : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: accentColor,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.lightPrimary)
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
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
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
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
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
