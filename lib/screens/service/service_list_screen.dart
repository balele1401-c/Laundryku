import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/enums.dart';
import '../../models/service_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/accent_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/skeleton_loading.dart';
import 'add_edit_service_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  void _openAddService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditServiceScreen(),
      ),
    );
  }

  void _openEditService(ServiceModel service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditServiceScreen(service: service),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, ServiceModel service) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: AppTheme.statusError, size: 24),
            const SizedBox(width: 10),
            Text(
              'Hapus Layanan?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus layanan "${service.namaLayanan}" dari katalog tarif?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    // ── ROLE GUARD: Hanya Owner yang boleh akses screen ini ──────────
    if (auth.currentUser?.role != UserRole.owner) {
      return _buildAccessDeniedScreen(context, isDark);
    }

    final serviceProvider = context.watch<ServiceProvider>();
    final services = serviceProvider.services;
    final currentFilter = serviceProvider.filterType;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Layanan & Tarif',
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
        onPressed: _openAddService,
        backgroundColor: AppTheme.ctaColor(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Layanan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Filter Segmented Tabs ─────────────────────────────
            _buildFilterSegment(context, isDark, serviceProvider, currentFilter),

            // ── Service List or Empty State ───────────────────────
            Expanded(
              child: serviceProvider.isLoading && services.isEmpty
                  ? const SkeletonLoadingList(itemCount: 6, itemHeight: 92)
                  : services.isEmpty
                      ? _buildEmptyState(
                          context, isDark, currentFilter != null)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 12,
                              bottom: 90,
                            ),
                            itemCount: services.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final service = services[index];
                              return _buildServiceItem(
                                context,
                                service,
                                isDark,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSegment(
    BuildContext context,
    bool isDark,
    ServiceProvider provider,
    ServiceType? currentFilter,
  ) {
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
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Semua Layanan (${provider.allServices.length})',
            isSelected: currentFilter == null,
            onTap: () => provider.setFilterType(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Kiloan',
            isSelected: currentFilter == ServiceType.kiloan,
            onTap: () => provider.setFilterType(ServiceType.kiloan),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Satuan',
            isSelected: currentFilter == ServiceType.satuan,
            onTap: () => provider.setFilterType(ServiceType.satuan),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppTheme.darkPrimary
                  : AppTheme.lightPrimary)
              : (isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.borderColor(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    ServiceModel service,
    bool isDark,
  ) {
    final isKiloan = service.tipe == ServiceType.kiloan;
    final typeColor = isKiloan
        ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimaryVariant)
        : (isDark ? const Color(0xFFC084FC) : const Color(0xFF9333EA));

    return SignatureAccentCard(
      accentColor: typeColor,
      onTap: () => _openEditService(service),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(isDark ? 40 : 20),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  isKiloan
                      ? Icons.local_laundry_service_outlined
                      : Icons.dry_cleaning_outlined,
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Type Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.namaLayanan,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Tipe Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withAlpha(isDark ? 50 : 25),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            service.tipe.label.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Estimasi Waktu Tag
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${service.estimasiHari} Hari Selesai',
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
                  ],
                ),
              ),

              // Options Menu (Edit/Delete)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: isDark
                      ? AppTheme.darkTextHint
                      : AppTheme.lightTextHint,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _openEditService(service);
                  } else if (value == 'delete') {
                    final confirmed =
                        await _confirmDelete(context, service);
                    if (confirmed == true && context.mounted) {
                      context
                          .read<ServiceProvider>()
                          .deleteService(service.id);
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit Layanan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppTheme.statusError),
                        SizedBox(width: 10),
                        Text('Hapus Layanan',
                            style: TextStyle(color: AppTheme.statusError)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(
            color: AppTheme.borderColor(context),
            height: 1,
          ),
          const SizedBox(height: 10),

          // Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tarif Layanan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppFormatters.rupiah(service.harga),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightPrimary,
                    ),
                  ),
                  Text(
                    isKiloan ? ' / kg' : ' / pcs',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
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
                Icons.dry_cleaning_outlined,
                size: 40,
                color: AppTheme.signatureColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'Tidak Ada Layanan pada Kategori Ini'
                  : 'Katalog Layanan Masih Kosong',
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
                  ? 'Coba pilih kategori filter layanan yang lain.'
                  : 'Buat paket layanan cuci kiloan atau satuan untuk mempermudah transaksi kasir.',
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
                onPressed: _openAddService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ctaColor(context),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Tambah Layanan Baru',
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

  Widget _buildAccessDeniedScreen(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.statusError.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: const Icon(
                  Icons.lock_person_outlined,
                  size: 40,
                  color: AppTheme.statusError,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Akses Terbatas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur Manajemen Layanan & Tarif hanya dapat diakses oleh akun dengan role Owner.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
