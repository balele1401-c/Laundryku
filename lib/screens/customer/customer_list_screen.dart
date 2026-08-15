import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/accent_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/skeleton_loading.dart';
import 'add_edit_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCustomer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditCustomerScreen(),
      ),
    );
  }

  void _openDetailCustomer(CustomerModel customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );
  }

  void _openEditCustomer(CustomerModel customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditCustomerScreen(customer: customer),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, CustomerModel customer) {
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
              'Hapus Pelanggan?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data pelanggan "${customer.nama}"? Tindakan ini tidak dapat dibatalkan.',
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
    final customerProvider = context.watch<CustomerProvider>();
    final customers = customerProvider.customers;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Data Pelanggan',
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
        onPressed: _openAddCustomer,
        backgroundColor: AppTheme.ctaColor(context),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          'Tambah Pelanggan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Summary Bar ──────────────────────────────
            _buildSearchAndFilterBar(context, isDark, customerProvider),

            // ── Customer List or Empty State ──────────────────────
            Expanded(
              child: customerProvider.isLoading && customers.isEmpty
                  ? const SkeletonLoadingList(itemCount: 6, itemHeight: 88)
                  : customers.isEmpty
                      ? _buildEmptyState(context, isDark,
                          customerProvider.searchQuery.isNotEmpty)
                      : RefreshIndicator(
                          onRefresh: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 300));
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: 90,
                            ),
                            itemCount: customers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              return _buildCustomerItem(
                                context,
                                customer,
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

  Widget _buildSearchAndFilterBar(
    BuildContext context,
    bool isDark,
    CustomerProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
        children: [
          // Search Input
          TextField(
            controller: _searchController,
            onChanged: (val) => provider.setSearchQuery(val),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari nama atau nomor HP...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Customer Count Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pelanggan Terdaftar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
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
                  '${provider.customers.length} Orang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.signatureColor(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(
    BuildContext context,
    CustomerModel customer,
    bool isDark,
  ) {
    final nameParts = customer.nama.trim().split(' ');
    String initials = '';
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials += nameParts[0][0].toUpperCase();
    }
    if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
      initials += nameParts[1][0].toUpperCase();
    }

    return Dismissible(
      key: Key(customer.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDelete(context, customer),
      onDismissed: (_) {
        context.read<CustomerProvider>().deleteCustomer(customer.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer.nama} berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.statusError,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      child: SignatureAccentCard(
        onTap: () => _openDetailCustomer(customer),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Hero Avatar with Initials
            Hero(
              tag: 'cust_avatar_${customer.id}',
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0369A1), const Color(0xFF0284C7)]
                        : [AppTheme.lightPrimary, AppTheme.lightPrimaryVariant],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name & Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.nama,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customer.noHp,
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

            // Total Transactions Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.borderColor(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_laundry_service_outlined,
                    size: 12,
                    color: AppTheme.signatureColor(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.totalTransaksi}x',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // WhatsApp Quick Button
            IconButton(
              icon: const Icon(
                Icons.chat_outlined,
                color: AppTheme.statusSuccess,
                size: 20,
              ),
              tooltip: 'Chat WhatsApp',
              onPressed: () => _launchWhatsApp(customer.noHp),
            ),

            // Popup Options (Edit/Delete)
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
                if (value == 'detail') {
                  _openDetailCustomer(customer);
                } else if (value == 'edit') {
                  _openEditCustomer(customer);
                } else if (value == 'delete') {
                  final confirmed =
                      await _confirmDelete(context, customer);
                  if (confirmed == true && context.mounted) {
                    context
                        .read<CustomerProvider>()
                        .deleteCustomer(customer.id);
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Lihat Riwayat & Profil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Edit Data'),
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
                      Text('Hapus Pelanggan',
                          style: TextStyle(color: AppTheme.statusError)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    bool isSearching,
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
                isSearching
                    ? Icons.person_search_outlined
                    : Icons.people_outline_rounded,
                size: 40,
                color: AppTheme.signatureColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching
                  ? 'Pelanggan Tidak Ditemukan'
                  : 'Belum Ada Data Pelanggan',
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
              isSearching
                  ? 'Coba gunakan kata kunci nama atau nomor HP lainnya.'
                  : 'Catat data kontak pelanggan untuk mempermudah notifikasi nota & status cucian.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!isSearching)
              ElevatedButton.icon(
                onPressed: _openAddCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ctaColor(context),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Tambah Pelanggan Sekarang',
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
