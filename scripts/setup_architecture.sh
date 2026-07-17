#!/bin/bash
set -e

PROJECT_ROOT=$(pwd)
LIB="$PROJECT_ROOT/lib"

echo "🚀 Démarrage de la migration AzizArt..."

create_file_if_missing() {
  local filepath="$1"
  local content="$2"
  if [ ! -f "$filepath" ]; then
    mkdir -p "$(dirname "$filepath")"
    printf '%s\n' "$content" > "$filepath"
    echo "  ✅ Créé : $filepath"
  else
    echo "  ⏭️  Ignoré : $filepath"
  fi
}

echo ""
echo "📦 [1/6] lib/core/..."

create_file_if_missing "$LIB/core/constants/api_keys.dart" \
'class ApiKeys {
  ApiKeys._();
  static String get firebaseApiKey =>
      const String.fromEnvironment("FIREBASE_API_KEY");
  static String get stripePublishableKey =>
      const String.fromEnvironment("STRIPE_PUBLISHABLE_KEY");
}'

create_file_if_missing "$LIB/core/constants/app_constants.dart" \
'class AppConstants {
  AppConstants._();
  static const String appName = "AzizArt";
  static const String appVersion = "1.0.0";
  static const int connectTimeoutMs = 5000;
  static const int receiveTimeoutMs = 10000;
  static const int defaultPageSize = 20;
}'

create_file_if_missing "$LIB/core/utils/validators.dart" \
'class Validators {
  Validators._();
  static bool isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email.trim());
  }
  static String? requiredField(String? value, {int maxLength = 255}) {
    if (value == null || value.trim().isEmpty) return "Ce champ est requis.";
    if (value.length > maxLength) return "Maximum $maxLength caractères.";
    return null;
  }
}'

create_file_if_missing "$LIB/core/utils/sanitizers.dart" \
'class Sanitizers {
  Sanitizers._();
  static String stripHtmlTags(String input) =>
      input.replaceAll(RegExp(r"<[^>]*>"), "").trim();
  static String sanitizeTextField(String input, {int maxLength = 500}) {
    final cleaned = stripHtmlTags(input);
    return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
  }
}'

create_file_if_missing "$LIB/core/utils/crypto_utils.dart" \
'import "package:flutter_secure_storage/flutter_secure_storage.dart";
class CryptoUtils {
  CryptoUtils._();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  static Future<String?> read(String key) => _storage.read(key: key);
  static Future<void> delete(String key) => _storage.delete(key: key);
  static Future<void> deleteAll() => _storage.deleteAll();
}'

create_file_if_missing "$LIB/core/services/auth_service.dart" \
'import "package:firebase_auth/firebase_auth.dart";
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  Future<UserCredential> signInWithEmail({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<UserCredential> registerWithEmail({required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> signOut() => _auth.signOut();
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}'

create_file_if_missing "$LIB/core/services/storage_service.dart" \
'import "../utils/crypto_utils.dart";
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();
  Future<void> saveSecure(String key, String value) => CryptoUtils.write(key, value);
  Future<String?> readSecure(String key) => CryptoUtils.read(key);
  Future<void> deleteSecure(String key) => CryptoUtils.delete(key);
  Future<void> clearAll() => CryptoUtils.deleteAll();
}'

create_file_if_missing "$LIB/core/services/payment_service.dart" \
'class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();
  Future<String> createPaymentIntent({
    required int amountInCents,
    required String currency,
  }) async {
    throw UnimplementedError("Implémenter avec Firebase Cloud Functions");
  }
}'

create_file_if_missing "$LIB/core/services/api_service.dart" \
'import "package:dio/dio.dart";
import "../constants/app_constants.dart";
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  late final Dio _dio;
  void initialize({required String baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {"Content-Type": "application/json"},
    ));
    _dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  }
  Dio get client => _dio;
}'

create_file_if_missing "$LIB/core/errors/app_exceptions.dart" \
'sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}
class NetworkException extends AppException {
  const NetworkException([super.message = "Erreur réseau."]);
}
class AuthException extends AppException {
  const AuthException([super.message = "Erreur authentification."]);
}
class NotFoundException extends AppException {
  const NotFoundException([super.message = "Ressource introuvable."]);
}
class PaymentException extends AppException {
  const PaymentException([super.message = "Erreur paiement."]);
}
class ValidationException extends AppException {
  const ValidationException([super.message = "Données invalides."]);
}'

echo ""
echo "📦 [2/6] lib/features/..."

mkdir -p "$LIB/features/home/models"
mkdir -p "$LIB/features/home/services"
mkdir -p "$LIB/features/home/widgets"
create_file_if_missing "$LIB/features/home/home_page.dart" \
'import "package:flutter/material.dart";
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("AzizArt - Accueil")));
}'

create_file_if_missing "$LIB/features/gallery/models/artwork.dart" \
'import "package:cloud_firestore/cloud_firestore.dart";
class Artwork {
  final String id;
  final String title;
  final String artistId;
  final String imageUrl;
  final String? description;
  final double? price;
  final bool isForSale;
  final DateTime createdAt;
  const Artwork({required this.id, required this.title, required this.artistId,
    required this.imageUrl, this.description, this.price,
    required this.isForSale, required this.createdAt});
  factory Artwork.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Artwork(
      id: doc.id, title: d["title"] as String, artistId: d["artistId"] as String,
      imageUrl: d["imageUrl"] as String, description: d["description"] as String?,
      price: (d["price"] as num?)?.toDouble(), isForSale: d["isForSale"] as bool? ?? false,
      createdAt: (d["createdAt"] as Timestamp).toDate());
  }
  Map<String, dynamic> toFirestore() => {
    "title": title, "artistId": artistId, "imageUrl": imageUrl,
    "description": description, "price": price, "isForSale": isForSale,
    "createdAt": Timestamp.fromDate(createdAt)};
}'

create_file_if_missing "$LIB/features/gallery/services/gallery_service.dart" \
'import "package:cloud_firestore/cloud_firestore.dart";
import "../models/artwork.dart";
class GalleryService {
  GalleryService._();
  static final GalleryService instance = GalleryService._();
  final _col = FirebaseFirestore.instance.collection("artworks");
  Stream<List<Artwork>> watchArtworks() => _col
      .orderBy("createdAt", descending: true)
      .snapshots()
      .map((s) => s.docs.map(Artwork.fromFirestore).toList());
  Future<Artwork?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Artwork.fromFirestore(doc) : null;
  }
}'

create_file_if_missing "$LIB/features/gallery/widgets/artwork_card.dart" \
'import "package:flutter/material.dart";
import "../models/artwork.dart";
class ArtworkCard extends StatelessWidget {
  final Artwork artwork;
  final VoidCallback? onTap;
  const ArtworkCard({super.key, required this.artwork, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Card(clipBehavior: Clip.antiAlias, child: Column(children: [
      Expanded(child: Image.network(artwork.imageUrl, fit: BoxFit.cover, width: double.infinity)),
      Padding(padding: const EdgeInsets.all(8),
        child: Text(artwork.title, style: Theme.of(context).textTheme.titleSmall)),
    ])));
}'

create_file_if_missing "$LIB/features/gallery/gallery_page.dart" \
'import "package:flutter/material.dart";
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Galerie")));
}'

mkdir -p "$LIB/features/atelier/models"
mkdir -p "$LIB/features/atelier/services"
mkdir -p "$LIB/features/atelier/widgets"
create_file_if_missing "$LIB/features/atelier/atelier_page.dart" \
'import "package:flutter/material.dart";
class AtelierPage extends StatelessWidget {
  const AtelierPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Atelier")));
}'

create_file_if_missing "$LIB/features/boutique/models/product.dart" \
'import "package:cloud_firestore/cloud_firestore.dart";
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String imageUrl;
  final int stock;
  const Product({required this.id, required this.name, required this.description,
    required this.price, required this.currency, required this.imageUrl, required this.stock});
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Product(id: doc.id, name: d["name"] as String, description: d["description"] as String,
      price: (d["price"] as num).toDouble(), currency: d["currency"] as String? ?? "EUR",
      imageUrl: d["imageUrl"] as String, stock: d["stock"] as int? ?? 0);
  }
}'

create_file_if_missing "$LIB/features/boutique/services/cart_service.dart" \
'import "dart:convert";
import "../models/product.dart";
import "../../../core/services/storage_service.dart";
class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}
class CartService {
  CartService._();
  static final CartService instance = CartService._();
  static const _cartKey = "azizart_cart";
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (s, i) => s + i.product.price * i.quantity);
  void addProduct(Product product) {
    final existing = _items.where((i) => i.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    _persist();
  }
  void removeProduct(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    _persist();
  }
  void clear() {
    _items.clear();
    StorageService.instance.deleteSecure(_cartKey);
  }
  Future<void> _persist() async {
    final data = _items.map((i) => {"productId": i.product.id, "qty": i.quantity}).toList();
    await StorageService.instance.saveSecure(_cartKey, jsonEncode(data));
  }
}'

mkdir -p "$LIB/features/boutique/widgets"
create_file_if_missing "$LIB/features/boutique/widgets/product_grid.dart" \
'import "package:flutter/material.dart";
import "../models/product.dart";
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onAddToCart;
  const ProductGrid({super.key, required this.products, required this.onAddToCart});
  @override
  Widget build(BuildContext context) => GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
    itemCount: products.length,
    itemBuilder: (_, i) {
      final p = products[i];
      return Card(child: Column(children: [
        Expanded(child: Image.network(p.imageUrl, fit: BoxFit.cover)),
        Text(p.name),
        Text("${p.price.toStringAsFixed(2)} ${p.currency}"),
        TextButton(onPressed: () => onAddToCart(p), child: const Text("Ajouter")),
      ]));
    });
}'

create_file_if_missing "$LIB/features/boutique/boutique_page.dart" \
'import "package:flutter/material.dart";
class BoutiquePage extends StatelessWidget {
  const BoutiquePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Boutique")));
}'

mkdir -p "$LIB/features/media/models"
mkdir -p "$LIB/features/media/services"
mkdir -p "$LIB/features/media/widgets"
create_file_if_missing "$LIB/features/media/media_page.dart" \
'import "package:flutter/material.dart";
class MediaPage extends StatelessWidget {
  const MediaPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Medias")));
}'

mkdir -p "$LIB/features/about"
create_file_if_missing "$LIB/features/about/about_page.dart" \
'import "package:flutter/material.dart";
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("A propos")));
}'

mkdir -p "$LIB/features/contact/widgets"
create_file_if_missing "$LIB/features/contact/contact_page.dart" \
'import "package:flutter/material.dart";
import "../../core/utils/validators.dart";
import "../../core/utils/sanitizers.dart";
class ContactPage extends StatefulWidget {
  const ContactPage({super.key});
  @override
  State<ContactPage> createState() => _ContactPageState();
}
class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  @override
  void dispose() { _emailCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final msg = Sanitizers.sanitizeTextField(_msgCtrl.text);
    debugPrint("Message : $msg");
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Contact")),
    body: Padding(padding: const EdgeInsets.all(16), child: Form(key: _formKey,
      child: Column(children: [
        TextFormField(controller: _emailCtrl,
          decoration: const InputDecoration(labelText: "Email"),
          validator: (v) => Validators.isValidEmail(v ?? "") ? null : "Email invalide"),
        const SizedBox(height: 16),
        TextFormField(controller: _msgCtrl,
          decoration: const InputDecoration(labelText: "Message"),
          maxLines: 5,
          validator: (v) => Validators.requiredField(v, maxLength: 500)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _submit, child: const Text("Envoyer")),
      ]))));
}'

echo ""
echo "📦 [3/6] lib/routes/..."

create_file_if_missing "$LIB/routes/app_router.dart" \
'import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../core/services/auth_service.dart";
import "../features/home/home_page.dart";
import "../features/gallery/gallery_page.dart";
import "../features/atelier/atelier_page.dart";
import "../features/boutique/boutique_page.dart";
import "../features/media/media_page.dart";
import "../features/about/about_page.dart";
import "../features/contact/contact_page.dart";
class AppRouter {
  AppRouter._();
  static final GoRouter router = GoRouter(
    initialLocation: "/",
    redirect: _guard,
    routes: [
      GoRoute(path: "/", builder: (_, __) => const HomePage()),
      GoRoute(path: "/gallery", builder: (_, __) => const GalleryPage()),
      GoRoute(path: "/atelier", builder: (_, __) => const AtelierPage()),
      GoRoute(path: "/boutique", builder: (_, __) => const BoutiquePage()),
      GoRoute(path: "/media", builder: (_, __) => const MediaPage()),
      GoRoute(path: "/about", builder: (_, __) => const AboutPage()),
      GoRoute(path: "/contact", builder: (_, __) => const ContactPage()),
    ],
  );
  static String? _guard(BuildContext context, GoRouterState state) {
    const protected = ["/boutique"];
    if (protected.contains(state.matchedLocation) && !AuthService.instance.isAuthenticated) {
      return "/";
    }
    return null;
  }
}'

echo ""
echo "📦 [4/6] lib/widgets/..."

mkdir -p "$LIB/widgets/common"
create_file_if_missing "$LIB/widgets/common/app_scaffold.dart" \
'import "package:flutter/material.dart";
class AppScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  const AppScaffold({super.key, required this.child, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)), body: child);
}'

mkdir -p "$LIB/widgets/secure"
create_file_if_missing "$LIB/widgets/secure/auth_wrapper.dart" \
'import "package:flutter/material.dart";
import "../../core/services/auth_service.dart";
class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;
  const AuthWrapper({super.key, required this.authenticatedChild, required this.unauthenticatedChild});
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: AuthService.instance.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return snapshot.hasData ? authenticatedChild : unauthenticatedChild;
    });
}'

echo ""
echo "📦 [5/6] lib/main.dart..."

create_file_if_missing "$LIB/main.dart" \
'import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "routes/app_router.dart";
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AzizArtApp());
}
class AzizArtApp extends StatelessWidget {
  const AzizArtApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: "AzizArt",
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A2E)),
      useMaterial3: true,
    ),
    routerConfig: AppRouter.router,
  );
}'

echo ""
echo "📦 [6/6] Assets, .env, .gitignore..."

mkdir -p "$PROJECT_ROOT/assets/images"
mkdir -p "$PROJECT_ROOT/assets/fonts"
mkdir -p "$PROJECT_ROOT/assets/translations"
mkdir -p "$PROJECT_ROOT/test/core"
mkdir -p "$PROJECT_ROOT/test/features"

create_file_if_missing "$PROJECT_ROOT/.env" \
'FIREBASE_API_KEY=your_firebase_api_key_here
STRIPE_PUBLISHABLE_KEY=your_stripe_key_here'

GITIGNORE="$PROJECT_ROOT/.gitignore"
touch "$GITIGNORE"
for line in ".env" "*.jks" "*.keystore" "key.properties" "google-services.json" "GoogleService-Info.plist"; do
  grep -qxF "$line" "$GITIGNORE" || echo "$line" >> "$GITIGNORE"
done

echo ""
echo "=============================================="
echo "✅ Migration terminée ! Lance : flutter pub get"
echo "=============================================="
