import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

/// Tombol toggle mode gelap/terang untuk dipasang di AppBar.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: child.key == const ValueKey('dark')
              ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
              : Tween<double>(begin: 0.25, end: 1.0).animate(anim),
          child: ScaleTransition(scale: anim, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
          key: ValueKey(isDark ? 'dark' : 'light'),
          color: Theme.of(context).appBarTheme.foregroundColor ??
              Theme.of(context).colorScheme.onSurface,
          size: 22,
        ),
      ),
      tooltip: isDark ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }
}
