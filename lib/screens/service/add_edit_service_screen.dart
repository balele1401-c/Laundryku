import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/service_model.dart';
import '../../models/enums.dart';
import '../../providers/service_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class AddEditServiceScreen extends StatefulWidget {
  final ServiceModel? service;

  const AddEditServiceScreen({super.key, this.service});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _hargaController;
  late ServiceType _tipe;
  late int _estimasiHari;
  bool _isSaving = false;

  bool get isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    _namaController =
        TextEditingController(text: widget.service?.namaLayanan ?? '');

    final initialHarga = widget.service?.harga ?? 0;
    _hargaController = TextEditingController(
      text: initialHarga > 0 ? AppFormatters.number(initialHarga) : '',
    );

    _tipe = widget.service?.tipe ?? ServiceType.kiloan;
    _estimasiHari = widget.service?.estimasiHari ?? 2;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rawHarga = AppFormatters.parseRupiah(_hargaController.text);
    if (rawHarga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga layanan harus lebih dari Rp 0'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ServiceProvider>();

    bool success;
    if (isEdit) {
      success = await provider.updateService(
        id: widget.service!.id,
        namaLayanan: _namaController.text,
        tipe: _tipe,
        harga: rawHarga,
        estimasiHari: _estimasiHari,
      );
    } else {
      success = await provider.addService(
        namaLayanan: _namaController.text,
        tipe: _tipe,
        harga: rawHarga,
        estimasiHari: _estimasiHari,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                isEdit
                    ? 'Layanan berhasil diperbarui!'
                    : 'Layanan baru berhasil ditambahkan!',
                style: GoogleFonts.inter(),
              ),
            ],
          ),
          backgroundColor: AppTheme.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.errorMessage ?? 'Gagal menyimpan layanan',
                  style: GoogleFonts.inter(),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.statusError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Layanan' : 'Tambah Layanan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Form Container Card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: AppTheme.borderColor(context),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: AppTheme.lightShadow,
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.signatureColor(context)
                                    .withAlpha(isDark ? 40 : 25),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall),
                              ),
                              child: Icon(
                                isEdit
                                    ? Icons.edit_note_rounded
                                    : Icons.dry_cleaning_outlined,
                                color: AppTheme.signatureColor(context),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit
                                        ? 'Perbarui Data Layanan'
                                        : 'Informasi Layanan & Tarif',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Atur jenis satuan, harga, & estimasi selesai',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
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
                        const SizedBox(height: 24),

                        // 1. Nama Layanan Field
                        Text(
                          'Nama Layanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _namaController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Cuci Komplit Reguler',
                            prefixIcon: Icon(
                              Icons.local_offer_outlined,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama layanan wajib diisi';
                            }
                            if (value.trim().length < 3) {
                              return 'Nama layanan minimal 3 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 2. Tipe Layanan (Kiloan / Satuan)
                        Text(
                          'Tipe / Satuan Layanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTypeOption(
                                label: 'Kiloan (/kg)',
                                icon: Icons.scale_outlined,
                                isSelected: _tipe == ServiceType.kiloan,
                                onTap: () => setState(
                                    () => _tipe = ServiceType.kiloan),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTypeOption(
                                label: 'Satuan (/pcs)',
                                icon: Icons.checkroom_outlined,
                                isSelected: _tipe == ServiceType.satuan,
                                onTap: () => setState(
                                    () => _tipe = ServiceType.satuan),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. Harga Layanan (Formatted)
                        Text(
                          'Tarif Harga (Rupiah)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _hargaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _RupiahInputFormatter(),
                          ],
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '7.000',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                  left: 14, right: 8, top: 13),
                              child: Text(
                                'Rp',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.signatureColor(context),
                                ),
                              ),
                            ),
                            suffixText: _tipe == ServiceType.kiloan
                                ? '/ kg'
                                : '/ pcs',
                            suffixStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tarif harga wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. Estimasi Waktu Selesai (Hari)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimasi Waktu Pengerjaan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.lightPrimaryVariant
                                    .withAlpha(isDark ? 40 : 20),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall),
                              ),
                              child: Text(
                                '$_estimasiHari Hari Selesai',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.darkPrimary
                                      : AppTheme.lightPrimaryVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Stepper / Quick Chips for Days
                        Row(
                          children: [1, 2, 3, 4, 5].map((day) {
                            final isSelected = _estimasiHari == day;
                            return Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _estimasiHari = day),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSmall),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                              ? AppTheme.darkPrimary
                                              : AppTheme.lightPrimary)
                                          : (isDark
                                              ? AppTheme.darkInputFill
                                              : AppTheme.lightInputFill),
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : AppTheme.borderColor(context),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$day H',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? (isDark
                                                  ? const Color(0xFF0F172A)
                                                  : Colors.white)
                                              : (isDark
                                                  ? AppTheme.darkTextSecondary
                                                  : AppTheme
                                                      .lightTextSecondary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Action Buttons ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
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
                                const Icon(Icons.check_rounded,
                                    size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  isEdit
                                      ? 'Simpan Perubahan'
                                      : 'Simpan Layanan',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF0369A1).withAlpha(80)
                  : const Color(0xFFE0F2FE))
              : (isDark
                  ? AppTheme.darkInputFill
                  : AppTheme.lightInputFill),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppTheme.signatureColor(context)
                : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
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
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightPrimary)
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
}

/// Formatter otomatis saat user mengetik angka tarif Rupiah.
class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final rawNumber = int.tryParse(newValue.text.replaceAll('.', ''));
    if (rawNumber == null) return oldValue;

    final formatted = AppFormatters.number(rawNumber);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
