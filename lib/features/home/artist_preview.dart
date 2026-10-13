import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_data_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../atelier/models/atelier_model.dart';
import 'shared_components.dart';

class ArtistPreviewSection extends StatefulWidget {
  final Function(int) onNavigate;
  final List<AtelierPhoto> atelierPhotos;

  const ArtistPreviewSection({
    super.key,
    required this.onNavigate,
    this.atelierPhotos = const [],
  });

  @override
  State<ArtistPreviewSection> createState() => _ArtistPreviewSectionState();
}

class _ArtistPreviewSectionState extends State<ArtistPreviewSection> {
  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final data = context.select<AppDataProvider, Map<String, dynamic>?>(
      (p) => p.aboutContent,
    );
    final photos = _ArtistPhotos(
      atelierPhotos: widget.atelierPhotos,
      data: data,
      isMobile: isMobile,
    );
    final bio = _ArtistBio(
      data: data,
      onNavigate: widget.onNavigate,
      isMobile: isMobile,
    );
    return HomeBand(
      color: AzizColors.lightBackground,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [bio, const SizedBox(height: 48), photos],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: photos),
                SizedBox(width: homeColumnGap(context)),
                Expanded(flex: 6, child: bio),
              ],
            ),
    );
  }
}

class _ArtistPhotos extends StatelessWidget {
  final List<AtelierPhoto> atelierPhotos;
  final Map<String, dynamic>? data;
  final bool isMobile;

  const _ArtistPhotos({
    required this.atelierPhotos,
    required this.data,
    required this.isMobile,
  });

  /// Photo de profil de « À propos » (R2, dossier `about_avatars/`) ; à défaut
  /// la première photo d'atelier, puis une image de secours.
  ({String url, String? folder}) _source() {
    final avatar = data?['avatar_path'];
    if (avatar is String && avatar.trim().isNotEmpty) {
      return (url: avatar.trim(), folder: 'about_avatars');
    }
    if (atelierPhotos.isNotEmpty) {
      final url = atelierPhotos.first.displayImage;
      if (url.isNotEmpty) return (url: url, folder: null);
    }
    return (url: 'atelier/profil.jpeg', folder: null);
  }

  @override
  Widget build(BuildContext context) {
    final source = _source();
    const placeholder =
        SizedBox.expand(child: ColoredBox(color: AzizColors.lightSurface));

    return SizedBox(
      height: isMobile ? 380 : 500,
      child: HomeMat(
        raised: true,
        padding: isMobile ? 10 : 14,
        child: OptimizedImage(
          url: source.url,
          folder: source.folder,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 900,
          placeholder: placeholder,
          errorWidget: placeholder,
        ),
      ),
    );
  }
}

class _ArtistBio extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(int) onNavigate;
  final bool isMobile;

  const _ArtistBio({
    this.data,
    required this.onNavigate,
    required this.isMobile,
  });

  String _str(String key) {
    final value = data?[key];
    return value is String ? value.trim() : '';
  }

  /// `<base>_fr` / `<base>_en` selon la langue, puis `<base>` en repli.
  String _localized(String base, bool isEn) {
    final primary = _str('${base}_${isEn ? 'en' : 'fr'}');
    return primary.isNotEmpty ? primary : _str(base);
  }

  @override
  Widget build(BuildContext context) {
    final isEn = homeIsEn(context);

    // `artist_name` est le champ modifié dans l'admin ; les colonnes _fr/_en
    // ne servent que de repli.
    final name = _str('artist_name').isNotEmpty
        ? _str('artist_name')
        : _localized('artist_name', isEn);
    final displayName = name.isNotEmpty ? name : 'Olga Indigo';

    final title = _localized('artist_title', isEn);
    final displayTitle = title.isNotEmpty
        ? title
        : (isEn ? 'Artist & batik master' : 'Artiste créatrice et maître batik');

    final defaultBio = isEn
        ? "Step into the world of textile art. Each creation is a unique piece, hand-shaped using traditional batik techniques, blending organic pigments with contemporary patterns that tell a story."
        : "Plongez dans l'univers de l'art textile. Chaque création est une pièce unique, façonnée à la main selon les techniques traditionnelles du batik, mêlant pigments organiques et motifs contemporains qui racontent une histoire.";

    // Texte d'introduction, sinon biographie, sinon texte par défaut.
    final intro = _localized('intro_text', isEn);
    final bio = _localized('bio', isEn);
    final displayBioText =
        intro.isNotEmpty ? intro : (bio.isNotEmpty ? bio : defaultBio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          displayName,
          style: homeSerif(
            size: isMobile ? 38 : 54,
            color: AzizColors.lightTextPrimary,
            height: 1.08,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          displayTitle,
          style: homeSerif(
            size: 18,
            color: AzizColors.lightTextMuted,
            style: FontStyle.italic,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            displayBioText,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: homeSans(size: 16, height: 1.8),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GhostBtn(
              label: isEn ? 'Visit the studio' : 'Visiter l’atelier',
              leading: const Icon(HomeIcons.studio),
              onTap: () => onNavigate(2),
            ),
            TextLinkBtn(
              label: isEn ? 'About the artist' : 'Découvrir l’artiste',
              onTap: () => onNavigate(4),
            ),
          ],
        ),
      ],
    );
  }
}