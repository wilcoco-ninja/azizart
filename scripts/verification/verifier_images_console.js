// ════════════════════════════════════════════════════════════════════════════
// VÉRIFICATION DES IMAGES DU SITE — à coller dans la console du navigateur
//
// 1. Ouvrez VOTRE SITE déployé (ex. https://azizart.vercel.app) dans Chrome.
// 2. Touche F12 → onglet « Console » → collez tout ce fichier → Entrée.
//    (Si Chrome demande de taper « allow pasting », faites-le d'abord.)
//
// Le script lit les chemins d'images réellement enregistrés dans Supabase
// (galerie, atelier, médias, événements d'accueil, page À propos, logo),
// puis demande chaque fichier à Cloudflare R2 DEPUIS VOTRE SITE : le résultat
// reflète donc exactement ce que verra un visiteur (y compris le CORS).
//
// Lecture seule : rien n'est modifié. Seule la clé publique (publishable) de
// l'application est utilisée ; les contenus non publiés ne sont pas visibles.
// ════════════════════════════════════════════════════════════════════════════
(async () => {
  const SUPABASE_URL = 'https://nqzrynteyovxzvahonpx.supabase.co';
  const SUPABASE_KEY = 'sb_publishable_JiIWJ1SGBT7DoBM9ZiIolg_nd3qoLI3';
  const R2 = 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev';

  const toUrl = (v) => {
    const s = String(v || '').trim();
    if (!s) return null;
    return /^https?:\/\//i.test(s) ? s : `${R2}/${s.replace(/^\/+/, '')}`;
  };

  const rest = async (table, select) => {
    try {
      const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}?select=${select}`, {
        headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
      });
      if (!r.ok) return { error: `HTTP ${r.status}`, rows: [] };
      return { rows: await r.json() };
    } catch (e) {
      return { error: String(e), rows: [] };
    }
  };

  // [page du site, dossier R2 attendu, URL]
  const items = [];
  const add = (page, dossier, value) => {
    const url = toUrl(value);
    if (url) items.push({ page, dossier, url });
  };

  const notes = [];
  const art = await rest('artworks', 'image_path,image_url');
  const ate = await rest('atelier_photos', 'image_path,image_url');
  const med = await rest('media_items', 'thumbnail_path,thumbnail_url');
  const evt = await rest('home_events', 'image_url');
  const abt = await rest('about_content', 'avatar_path,avatar_url,banner_url');
  [['artworks', art], ['atelier_photos', ate], ['media_items', med],
   ['home_events', evt], ['about_content', abt]].forEach(([t, r]) => {
    if (r.error) notes.push(`⚠ Table ${t} illisible : ${r.error}`);
    else if (!r.rows.length) notes.push(`ℹ Table ${t} : aucune ligne publiée (rien à afficher sur cette page)`);
  });

  art.rows.forEach((r) => add('Galerie / Accueil', 'gallery/', r.image_path || r.image_url));
  ate.rows.forEach((r) => add('Atelier', 'atelier/', r.image_path || r.image_url));
  med.rows.forEach((r) => add('Médias', 'media/', r.thumbnail_path || r.thumbnail_url));
  evt.rows.forEach((r) => add('Accueil (événements)', 'home_events/', r.image_url));
  abt.rows.forEach((r) => {
    add('À propos (profil)', 'about_avatars/', r.avatar_path || r.avatar_url);
    add('À propos (couverture)', 'about_banners/', r.banner_url);
  });
  add('Logo public', 'logo/', 'logo/logo.png');
  add('Logo admin', 'logo/', 'logo/logo0.png');

  const rows = [];
  for (const it of items) {
    let statut, type = '-', ko = '-';
    try {
      const r = await fetch(it.url, { method: 'HEAD', mode: 'cors', cache: 'no-store' });
      statut = r.status;
      type = r.headers.get('content-type') || '-';
      const len = Number(r.headers.get('content-length'));
      ko = len ? Math.round(len / 1024) : '-';
    } catch (e) {
      statut = 'BLOQUÉ (CORS ou réseau)';
    }
    const ok = statut === 200 && /^image\//.test(type);
    rows.push({
      résultat: ok ? '✅ OK' : '❌',
      page: it.page,
      dossier: it.dossier,
      fichier: it.url.replace(R2 + '/', ''),
      statut,
      type,
      'taille (Ko)': ko,
    });
  }

  console.clear();
  console.log(`Site testé : ${location.origin}`);
  notes.forEach((n) => console.log(n));
  console.table(rows);
  const bad = rows.filter((r) => r.résultat !== '✅ OK');
  console.log(bad.length
    ? `❌ ${bad.length} image(s) sur ${rows.length} ne s'affichent pas. Statut 404 = fichier absent du bucket ; ` +
      `« BLOQUÉ » = règle CORS à corriger ; 403 = accès public désactivé.`
    : `✅ Les ${rows.length} images répondent correctement depuis ce site.`);
})();