# 🚀 GUIDE DÉPLOIEMENT AZIZART — De zéro à la production

## RÉSUMÉ DU PLAN
```
Images optimisées → GitHub → Vercel (test) → Firebase Hosting (prod) → Domaine
```

---

## PARTIE 1 — IMAGES : FORMAT, CONVERSION ET STOCKAGE

### Quel format utiliser ?

| Format | Quand l'utiliser | Poids |
|--------|-----------------|-------|
| **WebP** | Toutes les photos (galerie, atelier, hero, media) | −70% vs JPEG |
| **SVG** | Logo uniquement (déjà en SVG ✅) | Aucun poids |
| **JPEG** | Fallback uniquement si WebP impossible | Référence |

> **Règle simple** : convertissez TOUT en WebP. Flutter supporte WebP nativement.

### Tailles cibles (avant déploiement)

| Usage | Largeur max | Poids max |
|-------|------------|-----------|
| Hero / bannière plein écran | 1920 px | 300 KB |
| Galerie (cards) | 800 px | 120 KB |
| Atelier (cards) | 800 px | 100 KB |
| Miniatures média | 600 px | 80 KB |
| Logo SVG | — | < 20 KB |

### Comment convertir (Windows, gratuit)

**Option A — Squoosh (navigateur, aucune installation)**
1. Allez sur https://squoosh.app
2. Glissez une image → choisissez **WebP** à droite
3. Quality : **80** pour photos, **90** pour œuvres d'art
4. Téléchargez → renommez `.webp`

**Option B — Script PowerShell (conversion en lot)**
```powershell
# Installer cwebp (Google) : https://developers.google.com/speed/webp/download
# Puis dans le dossier assets/images/ :

Get-ChildItem -Recurse -Include "*.jpg","*.jpeg","*.png" | ForEach-Object {
    $out = $_.FullName -replace '\.(jpg|jpeg|png)$', '.webp'
    & cwebp -q 82 $_.FullName -o $out
    Write-Host "✅ $($_.Name) → $([System.IO.Path]::GetFileName($out))"
}
```

**Option C — GIMP (interface graphique)**
Fichier → Exporter sous → `.webp` → Quality 82

### Où stocker les images

```
azizart/
└── assets/
    └── images/
        ├── atelier/     ← t1.webp, t2.webp… (remplace .jpg/.jpeg)
        ├── gallery/     ← 1.webp, a1.webp… 
        ├── new/         ← actu1.webp, a1.webp…
        ├── media/       ← 1.webp, 2.webp…
        └── logo/        ← logo.svg (déjà ok)
```

### Mettre à jour pubspec.yaml après conversion

Remplacez chaque ligne `.jpg` / `.jpeg` par `.webp` :
```yaml
# AVANT
- assets/images/atelier/t1.jpg
- assets/images/gallery/1.jpeg

# APRÈS
- assets/images/atelier/t1.webp
- assets/images/gallery/1.webp
```

Et dans tous les fichiers Dart qui référencent ces images :
```dart
// AVANT
assetPath: 'assets/images/atelier/t1.jpg'

// APRÈS
assetPath: 'assets/images/atelier/t1.webp'
```

> **Note** : les fichiers `atelier_photos.json`, `artworks.json`, `media_items.json`
> contiennent aussi des chemins d'image — pensez à les mettre à jour également.

### Taille totale visée pour le déploiement
- Objectif : **assets < 15 MB** au total pour Vercel/GitHub
- Vérifiez avec : `du -sh assets/images/` dans Git Bash

---

## PARTIE 2 — GITHUB : PUSH DU PROJET

### 1. Initialiser Git (une seule fois)
```bash
cd C:\Users\awilc\dev_app\azizart

git init
git add .
git commit -m "feat: initial commit — AZIZART v1.0"
```

### 2. Créer le repo GitHub
1. Allez sur https://github.com → **New repository**
2. Nom : `azizart` (ou `azizart-web`)
3. **Private** (recommandé pour ne pas exposer `firebase_options.dart`)
4. Ne pas initialiser avec README

### 3. Connecter et pousser
```bash
git remote add origin https://github.com/VOTRE_USERNAME/azizart.git
git branch -M main
git push -u origin main
```

### 4. Fichier .gitignore — IMPORTANT
Créez `.gitignore` à la racine si absent :
```gitignore
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
*.g.dart
*.freezed.dart

# Firebase — NE PAS EXPOSER les clés
.env
google-services.json
GoogleService-Info.plist

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
```

> **⚠️ IMPORTANT** : `firebase_options.dart` contient des clés API publiques
> (pour Flutter Web c'est normal — elles sont visibles dans le JS).
> Mais le fichier `.env` (clés privées) ne doit JAMAIS être pushé.

---

## PARTIE 3 — VERCEL : DÉPLOIEMENT TEST

### Pourquoi Vercel en premier ?
- Déploiement en 1 clic depuis GitHub
- HTTPS automatique, CDN mondial
- Prévisualisation de chaque commit
- Gratuit pour les projets personnels
- **Facile à migrer vers Firebase** ensuite

### 1. Builder Flutter Web pour Vercel

Vercel ne compile pas Flutter — vous devez lui fournir le build :

```bash
# Dans votre terminal Flutter
flutter clean
flutter pub get
flutter build web --release --base-href "/"
```

Le résultat est dans : `build/web/`

### 2. Option A — Déploiement via GitHub (recommandé)

1. Allez sur https://vercel.com → **New Project**
2. Importez votre repo GitHub `azizart`
3. **Framework Preset** : **Other** (pas Flutter dans la liste)
4. **Build Command** : (laisser vide — vous déployez le dossier build/)
5. **Output Directory** : `build/web`
6. **Install Command** : (laisser vide)

> **Astuce** : Pour que Vercel rebuild à chaque push, ajoutez un script.
> Créez `vercel.json` à la racine :

```json
{
  "buildCommand": "echo 'Flutter build must be done locally'",
  "outputDirectory": "build/web",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ],
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

> La règle `rewrites` est **essentielle** pour que Flutter Web fonctionne 
> (évite les 404 sur actualisation de page).

### 3. Option B — Déploiement manuel (plus simple pour commencer)

```bash
# Installer Vercel CLI
npm install -g vercel

# Dans le dossier du projet
flutter build web --release --base-href "/"
cd build/web
vercel --prod
```

Suivez les instructions → votre site est en ligne en 30 secondes.

### 4. Variables d'environnement sur Vercel
Dans Vercel Dashboard → Settings → Environment Variables :
```
FLUTTER_WEB_AUTO_DETECT=false
```
(Pas de secrets Firebase à mettre ici — ils sont dans `firebase_options.dart`)

---

## PARTIE 4 — FIREBASE HOSTING : PRODUCTION FINALE

### Pourquoi migrer de Vercel à Firebase ?
- Firebase Hosting est déjà utilisé pour Firestore/Auth/Storage
- Même compte, même console, tout centralisé
- CDN Google mondial (très rapide depuis l'Afrique)
- Gratuit jusqu'à 10 GB de stockage et 360 MB/jour de bande passante

### 1. Installer Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialiser Firebase Hosting dans le projet
```bash
cd C:\Users\awilc\dev_app\azizart
firebase init hosting
```

Répondez :
- **Use an existing project** → `azizart-ffda0`
- **Public directory** → `build/web`
- **Single-page app** → **Yes** (important pour Flutter)
- **Overwrite index.html** → **No**

Cela crée `firebase.json` et `.firebaserc`.

### 3. firebase.json recommandé
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ],
    "headers": [
      {
        "source": "/flutter.js",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=604800" }]
      },
      {
        "source": "/assets/**",
        "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }]
      },
      {
        "source": "**/*.wasm",
        "headers": [{ "key": "Content-Type", "value": "application/wasm" }]
      }
    ]
  }
}
```

### 4. Déployer sur Firebase
```bash
flutter build web --release --base-href "/"
firebase deploy --only hosting
```

Votre URL : `https://azizart-ffda0.web.app` (ou personnalisée)

### 5. Domaine personnalisé (plus tard)
Dans Firebase Console → Hosting → Add custom domain :
1. Entrez `www.azizartolga.com` (ou votre domaine)
2. Firebase vous donne 2 enregistrements DNS à ajouter chez votre registrar
3. Validation automatique + HTTPS gratuit (Let's Encrypt)

Registrars recommandés :
- **OVH** (Europe/Afrique, support FR) : ~12€/an pour `.com`
- **Namecheap** : ~10$/an
- **Gandi** : qualité premium, ~15€/an

---

## PARTIE 5 — WORKFLOW QUOTIDIEN (après déploiement)

### Ajouter une œuvre / photo / vidéo
1. Connectez-vous sur `https://votre-site.web.app/admin`
2. Utilisez le Hub admin pour publier
3. Les données vont dans Firestore → visibles immédiatement

### Mettre à jour le site (nouveau code)
```bash
# 1. Faire vos modifications dans VS Code
# 2. Builder
flutter build web --release --base-href "/"

# 3. Déployer
firebase deploy --only hosting   # → Firebase (prod)
# OU
vercel --prod                     # → Vercel (si encore en test)

# 4. Commiter sur GitHub
git add .
git commit -m "fix: description de la mise à jour"
git push
```

---

## PARTIE 6 — CHECKLIST AVANT MISE EN LIGNE

### Code
- [ ] `flutter analyze` → **0 erreurs** (warnings acceptables)
- [ ] `flutter build web --release` → build réussi
- [ ] Tester sur Chrome ET Edge en local (`flutter run -d chrome`)
- [ ] Vérifier la navbar sur mobile (< 600px)
- [ ] Vérifier que les images s'affichent (console navigateur = 0 erreurs 404)

### Images
- [ ] Toutes converties en WebP
- [ ] Poids total `assets/images/` < 15 MB
- [ ] `pubspec.yaml` mis à jour (.jpg → .webp)
- [ ] Chemins mis à jour dans les JSON et fichiers Dart

### Contenu
- [ ] Numéro WhatsApp correct : `wa.me/2290166495217`
- [ ] Email correct : `olga_indigo@yahoo.com`
- [ ] Lien YouTube : `youtube.com/@azizart-color`
- [ ] Lien Instagram : `instagram.com/indigoolga25`
- [ ] Lien TikTok : `tiktok.com/@olga.indigo` ← **à confirmer avec l'artiste**
- [ ] Liens Facebook : vérifier que le profil est public

### Firebase
- [ ] Règles Firestore configurées (lecture publique, écriture auth)
- [ ] Compte admin créé dans Firebase Auth
- [ ] Tester connexion admin `/admin`

---

## RÉSUMÉ RAPIDE DES COMMANDES

```bash
# Build
flutter clean && flutter pub get
flutter build web --release --base-href "/"

# Test local
flutter run -d chrome --release

# Déployer Vercel
vercel --prod

# Déployer Firebase
firebase deploy --only hosting

# Vérifier erreurs
flutter analyze
```