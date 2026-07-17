import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

// ══════════════════════════════════════════════════════════════════════════
// Configuration Supabase pour AZIZART
// ══════════════════════════════════════════════════════════════════════════

// URL de base du projet UNIQUEMENT — jamais de /rest/v1/ ni aucun autre
// chemin à la fin. Le SDK construit lui-même les URLs de l'API REST, de
// l'authentification, du stockage et du temps réel à partir de cette
// racine ; lui donner une URL déjà "augmentée" casse tout (BDD, connexion
// admin, upload d'images, temps réel) en même temps.
// Dashboard Supabase → Settings (engrenage) → API → "Project URL"
const String supabaseUrl = 'https://nqzrynteyovxzvahonpx.supabase.co';

// À FAIRE, OBLIGATOIRE : cette valeur est actuellement VIDE, ce qui
// empêche toute connexion à Supabase (lecture ET écriture). Sans elle,
// rien de ce que vous ajoutez depuis l'admin n'est réellement enregistré.
// Dashboard Supabase → Settings (engrenage) → API → "anon public"
// (parfois affichée sous le nom "Publishable key")
const String supabaseAnonKey = 'sb_publishable_VDrfelc-eo9dTwxeKftXQA_1f9m-QPk';

void main() async {
  // Initialisation minimale et rapide
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation Supabase (remplace Firebase.initializeApp()).
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey, // anonKey est déprécié depuis peu
  );

  runApp(const AzizArtApp());
}
