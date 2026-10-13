import 'package:flutter/material.dart';
import '../theme/aziz_colors.dart';
import 'optimized_image.dart';

/// Nom affiché en filigrane sur les œuvres.
const String kWatermarkText = 'AZIZART COLORS';

class ProtectedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double watermarkOpacity;
  final double watermarkFontSize;
  final Color watermarkColor;
  final Widget? errorWidget;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ProtectedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.watermarkOpacity = 0.3,
    this.watermarkFontSize = 14,
    this.watermarkColor = Colors.white,
    this.errorWidget,
    this.placeholder,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = OptimizedImage(
      url: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 900,
      borderRadius: borderRadius,
      placeholder: placeholder ??
          Container(
            color: AzizColors.lightSurface,
            child: const Center(
              child: CircularProgressIndicator(
                color: AzizColors.gold,
                strokeWidth: 2,
              ),
            ),
          ),
      errorWidget: errorWidget ??
          Container(
            color: AzizColors.lightSurface,
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AzizColors.lightTextMuted,
              ),
            ),
          ),
    );

    return Stack(
      children: [imageWidget, _buildWatermark(), _buildProtectionOverlay()],
    );
  }

  Widget _buildWatermark() {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Transform.rotate(
        angle: -0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: watermarkColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            kWatermarkText,
            style: TextStyle(
              fontSize: watermarkFontSize,
              fontWeight: FontWeight.w600,
              color: watermarkColor.withValues(alpha: watermarkOpacity),
              letterSpacing: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionOverlay() {
    return Positioned.fill(
      child: MouseRegion(
        cursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onTap,
          onSecondaryTap: () {}, // Bloque le menu contextuel du clic droit
          onLongPress: () {},
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class ProtectedImageGrid extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double watermarkOpacity;
  final Widget? errorWidget;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ProtectedImageGrid({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.watermarkOpacity = 0.3,
    this.errorWidget,
    this.placeholder,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = OptimizedImage(
      url: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 500,
      borderRadius: borderRadius,
      placeholder: placeholder ?? Container(color: AzizColors.lightSurface),
      errorWidget: errorWidget ?? Container(color: AzizColors.lightSurface),
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          imageWidget,
          Positioned(
            right: 6,
            bottom: 6,
            child: Text(
              kWatermarkText,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: watermarkOpacity),
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onSecondaryTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}