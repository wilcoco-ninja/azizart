import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../theme/admin_colors.dart';
import '../../../widgets/optimized_image.dart';

const double kAdminAppBarHeight = 56.0;

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showLogo;
  final bool isInstagramStyle;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.showLogo = true,
    this.isInstagramStyle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kAdminAppBarHeight);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: kAdminAppBarHeight + topPadding,
          padding: EdgeInsets.only(top: topPadding) +
              const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AdminColors.surface.withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(color: AdminColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AdminColors.text,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onBack,
                )
              else if (showLogo)
                _Logo(
                  onTap: onBack ?? () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                ),

              // Espace entre le logo (ou le bouton retour) et le titre.
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.text,
                    fontSize: isInstagramStyle ? 18 : 15,
                    letterSpacing: isInstagramStyle ? -0.3 : 0.1,
                    fontWeight:
                        isInstagramStyle ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),

              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final VoidCallback? onTap;
  const _Logo({this.onTap});

  /// ⚠️ Logo ADMIN — fichier distinct du logo public.
  /// Servi depuis R2 (`azizart-media/logo/logo0.png`), centralisé dans
  /// `AppConfig.logoAdminUrl` pour synchroniser les fichiers qui affichent
  /// ce logo (barre admin, barre latérale, écran de connexion).
  static final String _logoUrl = AppConfig.logoAdminUrl;

  /// Hauteur du logo : la barre admin fait 56 px, le logo en occupe ~75 %.
  static const double _logoSize = 42;

  /// Largeur réservée au logo : une boîte de taille fixe évite tout saut de
  /// mise en page pendant le chargement. À ajuster si le logo est plus large
  /// ou plus étroit (le logo est aligné à gauche, sans déformation).
  static const double _logoWidth = 96;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'AZIZART',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: OptimizedImage(
            url: _logoUrl,
            folder: 'logo',
            width: _logoWidth,
            height: _logoSize,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            placeholder: _placeholder,
            errorWidget: _error,
          ),
        ),
      ),
    );
  }

  static const Widget _placeholder = SizedBox(
    height: _logoSize,
    width: _logoWidth,
    child: Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 26,
        width: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AdminColors.accent,
        ),
      ),
    ),
  );

  static const Widget _error = SizedBox(
    height: _logoSize,
    width: _logoWidth,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'AC',
        style: TextStyle(
          color: AdminColors.accent,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}