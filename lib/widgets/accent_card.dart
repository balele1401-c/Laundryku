import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card dengan signature border kiri warna Sky Blue (2-3.5dp).
/// Menjadi visual anchor khas aplikasi LaundryKu.
class SignatureAccentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool showAccentBar;

  const SignatureAccentCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.accentColor,
    this.showAccentBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccentColor =
        accentColor ?? AppTheme.signatureColor(context);

    final cardContent = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.borderColor(context),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppTheme.lightShadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );

    Widget decoratedCard;
    if (showAccentBar) {
      decoratedCard = ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            cardContent,
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: AppTheme.signatureAccentWidth,
              child: Container(
                color: effectiveAccentColor,
              ),
            ),
          ],
        ),
      );
    } else {
      decoratedCard = cardContent;
    }

    if (margin != null) {
      decoratedCard = Padding(padding: margin!, child: decoratedCard);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: decoratedCard,
        ),
      );
    }

    return decoratedCard;
  }
}
