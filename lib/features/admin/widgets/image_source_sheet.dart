import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/aziz_colors.dart';

/// Vrai uniquement sur Android et iOS natifs : la caméra n'est pas
/// disponible sur le Web de bureau ni sous Windows / macOS / Linux.
bool get deviceHasCamera =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Feuille de choix « caméra / galerie » partagée par les sélecteurs d'image.
/// Sans caméra, retourne directement [ImageSource.gallery].
Future<ImageSource?> showImageSourceSheet(BuildContext context) async {
  if (!deviceHasCamera) return ImageSource.gallery;

  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AzizColors.backgroundMedium,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AzizColors.saffron.withValues(alpha: 0.18),
          ),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AzizColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _SheetOption(
              icon: Icons.camera_alt_rounded,
              label: 'Prendre une photo',
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choisir dans la galerie',
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

/// Ligne d'action d'une feuille modale (icône ronde + libellé).
class ImageSheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ImageSheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AzizColors.saffron,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AzizColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: color == AzizColors.saffron
                      ? AzizColors.textPrimary
                      : color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
      ImageSheetAction(icon: icon, label: label, onTap: onTap);
}