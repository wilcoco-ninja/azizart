import 'package:flutter/material.dart';

import '../theme/aziz_colors.dart';
import 'optimized_image.dart';
import 'protected_image.dart' show kWatermarkText;

class WatermarkedImage extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final BoxFit fit;
  final double watermarkOpacity;
  final double watermarkFontSize;
  final Color watermarkColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;

  const WatermarkedImage.network(
    this.imageUrl, {
    this.imagePath,
    this.fit = BoxFit.cover,
    this.watermarkOpacity = 0.35,
    this.watermarkFontSize = 13,
    this.watermarkColor = Colors.white,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    super.key,
  });

  const WatermarkedImage.asset(
    this.imagePath, {
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.watermarkOpacity = 0.35,
    this.watermarkFontSize = 13,
    this.watermarkColor = Colors.white,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    super.key,
  });

  Widget _fallback() =>
      errorWidget ??
      Container(
        color: AzizColors.lightSurface,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AzizColors.lightTextSecondary,
            size: 28,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final direct = (imageUrl ?? '').trim();
    final assetPath = (imagePath ?? '').trim();
    final isLocalAsset = direct.isEmpty && assetPath.startsWith('assets/');

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isLocalAsset)
          Image.asset(
            assetPath,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          )
        else
          OptimizedImage(
            url: direct,
            path: assetPath,
            fit: fit,
            memCacheWidth: memCacheWidth,
            placeholder:
                placeholder ?? Container(color: AzizColors.lightSurface),
            errorWidget: _fallback(),
          ),
        _WatermarkOverlay(
          opacity: watermarkOpacity,
          fontSize: watermarkFontSize,
          color: watermarkColor,
        ),
      ],
    );
  }
}

class _WatermarkOverlay extends StatelessWidget {
  final double opacity;
  final double fontSize;
  final Color color;

  const _WatermarkOverlay({
    required this.opacity,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            kWatermarkText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1.2,
              fontFamily: 'Georgia',
            ),
          ),
        ),
      ),
    );
  }
}