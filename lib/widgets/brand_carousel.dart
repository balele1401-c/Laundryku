import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class CarouselBannerItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String tag;

  const CarouselBannerItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.tag,
  });
}

/// Carousel gambar bergulir ke samping untuk Dashboard LaundryKu.
/// Menggunakan auto-scroll horizontal, rounded corner 24dp, overlay gradient,
/// foto operasional nyata, dan line/bar progress indicator.
class BrandCarousel extends StatefulWidget {
  const BrandCarousel({super.key});

  @override
  State<BrandCarousel> createState() => _BrandCarouselState();
}

class _BrandCarouselState extends State<BrandCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  static const List<CarouselBannerItem> _items = [
    CarouselBannerItem(
      title: 'Cucian Bersih & Higienis',
      subtitle: 'Standar pencucian higienis dengan detergen ramah serat pakaian',
      imageUrl:
          'https://images.unsplash.com/photo-1545173168-9f1947eebb7f?auto=format&fit=crop&w=1000&q=80',
      tag: 'KUALITAS PRIMA',
    ),
    CarouselBannerItem(
      title: 'Rapi & Wangi Tahan Lama',
      subtitle: 'Setrika uap bertekanan tinggi dengan pelicin aroma eksklusif',
      imageUrl:
          'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?auto=format&fit=crop&w=1000&q=80',
      tag: 'FINISHING RAPI',
    ),
    CarouselBannerItem(
      title: 'Operasional Cepat & Akurat',
      subtitle: 'Pantau status nota pelanggan secara real-time langsung dari HP',
      imageUrl:
          'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?auto=format&fit=crop&w=1000&q=80',
      tag: 'SISTEM DIGITAL',
    ),
    CarouselBannerItem(
      title: 'Pelayanan Antar-Jemput',
      subtitle: 'Tingkatkan kepuasan pelanggan dengan kurir pick-up & delivery',
      imageUrl:
          'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1000&q=80',
      tag: 'PRAKTIS & CEPAT',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: _items.length,
          options: CarouselOptions(
            height: 185,
            viewportFraction: 0.88,
            enlargeCenterPage: true,
            enlargeFactor: 0.18,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final item = _items[index];
            return _buildCarouselCard(item, isDark);
          },
        ),
        const SizedBox(height: 12),
        // Line Progress Indicator (bukan dot biasa)
        _buildLineIndicator(isDark),
      ],
    );
  }

  Widget _buildCarouselCard(CarouselBannerItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Shimmer Loader
            CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                highlightColor:
                    isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                child: const Icon(
                  Icons.local_laundry_service_outlined,
                  size: 48,
                  color: AppTheme.lightPrimaryVariant,
                ),
              ),
            ),

            // Gradient Overlay from Transparent to Deep Slate Navy
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.15, 0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x7A0F172A), // Slate 900 @ 48%
                    Color(0xF50F172A), // Slate 900 @ 96%
                  ],
                ),
              ),
            ),

            // Content Text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppTheme.lightAccent.withAlpha(210),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      item.tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFCBD5E1), // Slate 300
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_items.length, (index) {
        final isActive = _currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 28 : 8,
          height: 4,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimaryVariant)
                : (isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
