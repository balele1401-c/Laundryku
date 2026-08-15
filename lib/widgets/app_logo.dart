import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable SVG Logo Icon (hanya icon mesin cuci) untuk AppBar.
class AppLogoIcon extends StatelessWidget {
  final double size;
  final double radius;

  const AppLogoIcon({
    super.key,
    this.size = 30,
    this.radius = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SvgPicture.asset(
        'assets/icon/laundryku_icon.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Logo Icon besar dengan bayangan halus untuk Splash / Modal.
class AppLogoBadge extends StatelessWidget {
  final double size;
  final double radius;

  const AppLogoBadge({
    super.key,
    this.size = 72,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withAlpha(65),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SvgPicture.asset(
          'assets/icon/laundryku_icon.svg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Logo Lengkap (Icon + Tulisan "LaundryKu" + Tagline) untuk Login & Registrasi.
class AppLogoFull extends StatelessWidget {
  final double width;
  final double? height;

  const AppLogoFull({
    super.key,
    this.width = 280,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icon/laundryku_logo_full.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
