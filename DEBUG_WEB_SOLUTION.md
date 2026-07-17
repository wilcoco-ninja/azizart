# Solution au problème de connexion Flutter Web Debug

## Problème
```
Failed to establish connection with the web debug service: TimeoutException after 0:00:05.000000
```

## Solutions

### 1. Augmenter le timeout (Solution recommandée)
Exécutez avec un timeout plus long :
```bash
flutter run -d chrome --web-browser-flag "--remote-debugging-timeout=30"
```

Ou dans un fichier `web/index.html`, ajoutez avant la fermeture de `<head>` :
```html
<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="0">
```

### 2. Désactiver le debug mode (pour production)
```bash
flutter run -d chrome --release
```

### 3. Nettoyer et reconstruire
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### 4. Utiliser un autre navigateur
```bash
flutter run -d edge    # Microsoft Edge
flutter run -d chrome --no-sound-null-safety  # Chrome sans sound null safety
```

### 5. Vérifier les ports bloqués
Parfois le port 8080 ou 9100 est bloqué. Essayez :
```bash
flutter run -d chrome --web-port=8081
```

### 6. Mode web server au lieu de chrome
```bash
flutter run -d web-server --web-port=8080
```
Puis ouvrez http://localhost:8080 dans votre navigateur.

## Note importante
Le splash screen est configuré pour :
- Durée minimum : 2 secondes
- Durée maximum : 5 secondes (fallback timer)

Cela garantit que l'utilisateur verra toujours l'accueil, même en cas de chargement lent.