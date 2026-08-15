import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/service_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data locale tanggal Indonesia ('id_ID')
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('⚠️ Gagal inisialisasi locale date formatting id_ID: $e');
  }

  // Inisialisasi Firebase dengan graceful fallback
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('✅ Firebase berhasil diinisialisasi');
  } catch (e) {
    debugPrint('⚠️ Firebase gagal diinisialisasi: $e');
    debugPrint('   App akan berjalan tanpa fitur Firebase.');
  }

  runApp(LaundryKuApp(firebaseReady: firebaseReady));
}

class LaundryKuApp extends StatelessWidget {
  final bool firebaseReady;

  const LaundryKuApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'LaundryKu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: firebaseReady
                ? const AuthWrapper()
                : const _FirebaseErrorScreen(),
          );
        },
      ),
    );
  }
}

/// Ditampilkan jika Firebase gagal diinisialisasi.
class _FirebaseErrorScreen extends StatelessWidget {
  const _FirebaseErrorScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  color: AppTheme.statusError.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 40,
                  color: AppTheme.statusError,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Koneksi Firebase Gagal',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Pastikan konfigurasi Firebase sudah benar\ndan perangkat terhubung ke internet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
