import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final CustomerModel? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _noHpController;
  bool _isSaving = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _namaController =
        TextEditingController(text: widget.customer?.nama ?? '');
    _noHpController =
        TextEditingController(text: widget.customer?.noHp ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<CustomerProvider>();

    bool success;
    if (isEdit) {
      success = await provider.updateCustomer(
        id: widget.customer!.id,
        nama: _namaController.text,
        noHp: _noHpController.text,
      );
    } else {
      success = await provider.addCustomer(
        nama: _namaController.text,
        noHp: _noHpController.text,
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
                    ? 'Data pelanggan berhasil diperbarui!'
                    : 'Pelanggan baru berhasil ditambahkan!',
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
                  provider.errorMessage ?? 'Gagal menyimpan data',
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
          isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
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
                        // Card Header Badge
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
                                    : Icons.person_add_outlined,
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
                                        ? 'Perbarui Data Kontak'
                                        : 'Informasi Pelanggan Baru',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Pastikan nama & nomor WhatsApp aktif',
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

                        // 1. Nama Lengkap Field
                        Text(
                          'Nama Lengkap',
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
                            hintText: 'Contoh: Ibu Rina Melati',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                            ),
                          ),
                          validator: AppValidators.validateName,
                        ),
                        const SizedBox(height: 20),

                        // 2. Nomor HP / WhatsApp Field
                        Text(
                          'Nomor WhatsApp / HP',
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
                          controller: _noHpController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSave(),
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: '081234567890',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              size: 20,
                            ),
                          ),
                          validator: AppValidators.validatePhone,
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
                                      : 'Simpan Pelanggan',
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
}
