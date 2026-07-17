import '../../gallery/models/artwork.dart';

/// Données chargées par HomeService pour la page d'accueil.
class HomeData {
  final List<Artwork> featuredArtworks;
  const HomeData({this.featuredArtworks = const []});
  bool get isEmpty    => featuredArtworks.isEmpty;
  bool get hasArtworks => featuredArtworks.isNotEmpty;
}
