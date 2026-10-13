<!DOCTYPE html>
<html lang="fr">
<head>
  <!-- Remplacé automatiquement par « flutter build web » (--base-href). -->
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="description" content="AZIZART COLORS — la galerie d'Olga Indigo, artiste batik : œuvres, atelier, médias et contact.">
  <meta name="theme-color" content="#F4F4F1">

  <!-- Partage (réseaux sociaux, messageries).
       À compléter après l'achat du nom de domaine :
       <meta property="og:url" content="https://VOTRE-DOMAINE">
       <meta property="og:image" content="https://VOTRE-DOMAINE/icons/Icon-512.png"> -->
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="AZIZART COLORS">
  <meta property="og:locale" content="fr_FR">
  <meta property="og:title" content="AZIZART COLORS — Olga Indigo">
  <meta property="og:description" content="Artiste batik : œuvres, atelier et actualités.">
  <meta name="twitter:card" content="summary">

  <!-- iOS / Android : mode application -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <meta name="apple-mobile-web-app-title" content="AZIZART COLORS">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <title>AZIZART COLORS — Olga Indigo</title>
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="manifest" href="manifest.json">

  <!-- Connexions anticipées : données, images, moteur Flutter (CanvasKit) et polices.
       Gagne plusieurs centaines de millisecondes sur réseau mobile. -->
  <link rel="preconnect" href="https://nqzrynteyovxzvahonpx.supabase.co" crossorigin>
  <link rel="preconnect" href="https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev" crossorigin>
  <link rel="preconnect" href="https://www.gstatic.com" crossorigin>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <!-- À décommenter UNIQUEMENT quand le domaine personnalisé du bucket R2
       (media.VOTRE-DOMAINE) est actif et que « nslookup media.VOTRE-DOMAINE »
       renvoie une adresse :
  <link rel="preconnect" href="https://media.VOTRE-DOMAINE" crossorigin>
  -->

  <style>
    html, body { margin: 0; height: 100%; background: #F4F4F1; }

    /* Écran d'attente affiché jusqu'à la première image de Flutter. */
    #splash {
      position: fixed; top: 0; right: 0; bottom: 0; left: 0; z-index: 10;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      box-sizing: border-box; text-align: center;
      padding: max(24px, env(safe-area-inset-top)) max(24px, env(safe-area-inset-right))
               max(24px, env(safe-area-inset-bottom)) max(24px, env(safe-area-inset-left));
      font-family: Georgia, serif; color: #152845; background: #F4F4F1;
      transition: opacity .3s ease;
    }
    #splash.hide { opacity: 0; pointer-events: none; }
    #splash-brand {
      max-width: 100%; letter-spacing: .3em; padding-left: .3em;
      font-size: 1.2rem; line-height: 1.4;
    }
    #splash-brand i {
      display: block; width: 36px; height: 2px; margin: 16px auto 0; background: #152845;
      animation: pulse 1.2s ease-in-out infinite;
    }
    #splash-msg {
      max-width: 34ch; margin: 28px 0 0; font-size: 1rem; line-height: 1.5; letter-spacing: normal;
    }
    #splash-retry {
      margin-top: 20px; padding: 12px 28px; min-height: 44px;
      font: inherit; font-size: 1rem; color: #F4F4F1; background: #152845;
      border: 0; border-radius: 2px; cursor: pointer;
    }
    #splash-retry:focus-visible { outline: 3px solid #152845; outline-offset: 3px; }
    #splash [hidden] { display: none; }
    @keyframes pulse { 0%, 100% { transform: scaleX(.3); } 50% { transform: scaleX(1); } }
    @media (prefers-reduced-motion: reduce) {
      #splash { transition: none; }
      #splash-brand i { animation: none; }
    }
  </style>
</head>
<body>
  <div id="splash" role="status" aria-live="polite">
    <div id="splash-brand">AZIZART COLORS<i></i></div>
    <p id="splash-msg" hidden></p>
    <button id="splash-retry" type="button" hidden>Recharger le site</button>
  </div>
  <noscript>
    <p style="font-family:Georgia,serif;text-align:center;padding:48px 24px;position:relative;z-index:20">
      AZIZART COLORS — Olga Indigo. Activez JavaScript pour afficher le site.
    </p>
  </noscript>

  <script>
    // Volontairement en ES5 : ce code doit pouvoir s'exécuter même sur un navigateur
    // trop ancien pour Flutter, afin de lui afficher un message clair.
    (function () {
      var SLOW_AFTER_MS = 8000;    // connexion lente : on rassure l'utilisateur
      var FAIL_AFTER_MS = 30000;   // échec probable : on propose de recharger

      var splash = document.getElementById('splash');
      var msg = document.getElementById('splash-msg');
      var retry = document.getElementById('splash-retry');
      var finished = false;
      var slowTimer = null;
      var failTimer = null;

      function showMessage(text, withRetry) {
        msg.textContent = text;
        msg.hidden = false;
        retry.hidden = !withRetry;
      }

      // Retire l'écran d'attente dès que Flutter a dessiné sa première image.
      function hideSplash() {
        if (finished) return;
        finished = true;
        clearTimeout(slowTimer);
        clearTimeout(failTimer);
        splash.classList.add('hide');
        setTimeout(function () {
          if (splash.parentNode) splash.parentNode.removeChild(splash);
        }, 400);
      }
      window.addEventListener('flutter-first-frame', hideSplash);
      document.addEventListener('flutter-first-frame', hideSplash);

      function fail(text) {
        if (finished) return;
        clearTimeout(slowTimer);
        clearTimeout(failTimer);
        showMessage(text, true);
      }

      // « Recharger » : supprime le service worker et les caches (souvent à l'origine
      // d'un écran blanc après une mise à jour du site), puis recharge la page.
      retry.addEventListener('click', function () {
        retry.disabled = true;
        var tasks = [];
        try {
          if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations) {
            tasks.push(navigator.serviceWorker.getRegistrations().then(function (list) {
              return Promise.all(list.map(function (r) { return r.unregister(); }));
            }));
          }
        } catch (e) {}
        try {
          if (window.caches && window.caches.keys) {
            tasks.push(window.caches.keys().then(function (keys) {
              return Promise.all(keys.map(function (k) { return window.caches.delete(k); }));
            }));
          }
        } catch (e) {}
        var reload = function () { window.location.reload(); };
        if (window.Promise) { Promise.all(tasks).then(reload, reload); } else { reload(); }
      });

      // Compatibilité : Flutter exige WebGL (1 ou 2) et un JavaScript récent.
      // Le contexte de test est libéré aussitôt (Safari limite le nombre de contextes).
      function supportsWebGL() {
        try {
          var canvas = document.createElement('canvas');
          var gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
          if (!gl) return false;
          var lose = gl.getExtension('WEBGL_lose_context');
          if (lose) lose.loseContext();
          return true;
        } catch (e) {
          return false;
        }
      }

      var supported = typeof Promise !== 'undefined' &&
                      typeof Promise.allSettled === 'function' &&
                      supportsWebGL();

      // Navigateur trop ancien : Flutter n'est JAMAIS chargé.
      if (!supported) {
        showMessage('Ce navigateur est trop ancien pour afficher le site. ' +
                    'Mettez-le à jour ou ouvrez le site avec un Chrome ou un Safari récent.',
                    false);
        return;
      }

      slowTimer = setTimeout(function () {
        if (!finished) showMessage('Connexion lente… le site arrive, merci de patienter.', false);
      }, SLOW_AFTER_MS);
      failTimer = setTimeout(function () {
        fail('Le chargement est plus long que prévu. Vérifiez votre connexion ou rechargez le site.');
      }, FAIL_AFTER_MS);

      // Chargement de Flutter.
      var script = document.createElement('script');
      script.src = 'flutter_bootstrap.js';
      script.async = true;
      script.onerror = function () {
        fail('Impossible de charger le site. Vérifiez votre connexion puis rechargez.');
      };
      document.head.appendChild(script);
    })();
  </script>
</body>
</html>