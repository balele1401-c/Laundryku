import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import 'login_screen.dart';
import '../dashboard/owner_dashboard_screen.dart';
import '../dashboard/kasir_dashboard_screen.dart';

/// AuthWrapper — memantau AuthState dari AuthProvider
/// dan mengarahkan ke LoginScreen atau Dashboard sesuai kondisi.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final state = auth.authState;

    // Masih loading
    if (state == AuthState.unknown ||
        state == AuthState.authenticatedLoading) {
      return const _SplashLoading();
    }

    // Belum login
    if (state == AuthState.unauthenticated) {
      return const LoginScreen();
    }

    // Sudah login & data user tersedia
    final user = auth.currentUser;
    if (user == null) return const LoginScreen();

    return user.role == UserRole.owner
        ? const OwnerDashboardScreen()
        : const KasirDashboardScreen();
  }
}

/// Splash / loading screen sederhana saat cek auth state.
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogoBadge(size: 76, radius: 20),
            const SizedBox(height: 24),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
