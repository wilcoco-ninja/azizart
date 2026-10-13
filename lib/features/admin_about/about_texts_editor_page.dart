import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';
import '../../theme/admin_colors.dart';
import '../about/about_page.dart';
// ⚠️ Ajustez ce chemin selon l'emplacement réel de admin_avatar_picker.dart
import '../admin/widgets/admin_avatar_picker.dart';
import 'services/about_content_service.dart';

const List<String> _langs = ['fr', 'en'];

/// Largeur maximale du contenu : lisible sur PC portable et grand écran.
const double _maxContentWidth = 760;

// ═══════════════════════════════════════════════════════════════════════════
// SPÉCIFICATIONS DES CHAMPS (alignées sur _aboutKeyToColumn de about_page.dart)
// ═══════════════════════════════════════════════════════════════════════════

class _Field {
  final String column;
  final String label;
  final String? trKey;
  final bool multiline;
  final bool perLang;
  final bool canHide;
  const _Field(
    this.column,
    this.label, {
    this.trKey,
    this.multiline = false,
    this.perLang = true,
    this.canHide = true,
  });
}

class _ItemField {
  final String key;
  final String label;
  final bool multiline;
  const _ItemField(this.key, this.label, {this.multiline = false});
}

class _ListSpec {
  final String column;
  final String label;
  final List<_ItemField> itemFields;
  final bool stringList;
  final bool canHide;
  const _ListSpec(
    this.column,
    this.label,
    this.itemFields, {
    this.stringList = false,
    this.canHide = true,
  });
}

class _Section {
  final String title;
  final List<_Field> fields;
  final List<_ListSpec> lists;
  const _Section(this.title,
      {this.fields = const [], this.lists = const []});
}

const List<_Section> _sections = [
  _Section('En-tête', fields: [
    _Field('hero_label', 'Étiquette au-dessus du nom', trKey: 'about.title'),
    _Field('artist_name', 'Nom de l\'artiste',
        trKey: 'about.name', perLang: false, canHide: false),
    _Field('heritage_line', 'Ligne d\'héritage', trKey: 'about.heritage'),
    _Field('heritage_badge', 'Badge d\'héritage',
        trKey: 'about.heritage_badge'),
  ]),
  _Section('Profil (barre de puces)', fields: [
    _Field('location', 'Lieu', canHide: false),
    _Field('career_start_year', 'Année de début de carrière',
        perLang: false, canHide: false),
  ], lists: [
    _ListSpec('disciplines', 'Disciplines', [_ItemField('value', 'Discipline')],
        stringList: true, canHide: false),
  ]),
  _Section('Introduction', fields: [
    _Field('intro_title', 'Titre', trKey: 'about.intro_title'),
    _Field('intro_text', 'Texte principal',
        trKey: 'about.intro_text', multiline: true),
    _Field('intro_text2', 'Texte secondaire',
        trKey: 'about.intro_text2', multiline: true),
  ]),
  _Section('Origines', fields: [
    _Field('origins_title', 'Titre', trKey: 'about.origins_title'),
    _Field('origins_text1', 'Paragraphe 1',
        trKey: 'about.origins_text1', multiline: true),
    _Field('origins_text2', 'Paragraphe 2',
        trKey: 'about.origins_text2', multiline: true),
  ]),
  _Section('Citation', fields: [
    _Field('quote', 'Citation', trKey: 'about.grandma_quote', multiline: true),
    _Field('quote_author', 'Auteur de la citation',
        trKey: 'about.grandma_author'),
  ]),
  _Section('Art & technique', fields: [
    _Field('art_title', 'Titre', trKey: 'about.art_title'),
    _Field('art_text1', 'Paragraphe 1',
        trKey: 'about.art_text1', multiline: true),
    _Field('art_text2', 'Paragraphe 2',
        trKey: 'about.art_text2', multiline: true),
  ], lists: [
    _ListSpec('technique_steps', 'Étapes de la technique', [
      _ItemField('title', 'Titre'),
      _ItemField('text', 'Texte', multiline: true),
    ]),
  ]),
  _Section('Teintures naturelles', fields: [
    _Field('dyes_title', 'Titre', trKey: 'about.dyes_title'),
  ], lists: [
    _ListSpec('natural_dyes', 'Cartes de teintures', [
      _ItemField('title', 'Titre'),
      _ItemField('text', 'Texte', multiline: true),
    ]),
  ]),
  _Section('Parcours (chronologie)', fields: [
    _Field('timeline_title', 'Titre', trKey: 'about.timeline_title'),
  ], lists: [
    _ListSpec('timeline_events', 'Événements', [
      _ItemField('year', 'Année'),
      _ItemField('title', 'Titre'),
      _ItemField('description', 'Description', multiline: true),
    ]),
  ]),
  _Section('Statistiques', lists: [
    _ListSpec('stats', 'Chiffres clés', [
      _ItemField('value', 'Valeur (ex : 30+)'),
      _ItemField('label', 'Libellé'),
    ]),
  ]),
  _Section('Représentation', fields: [
    _Field('representation_title', 'Titre',
        trKey: 'about.representation_title'),
    _Field('representation_text', 'Texte',
        trKey: 'about.representation_text', multiline: true),
  ]),
  _Section('Sections libres (nouveaux textes)', lists: [
    _ListSpec('custom_sections', 'Sections ajoutées', [
      _ItemField('title', 'Titre'),
      _ItemField('text', 'Texte', multiline: true),
    ]),
  ]),
];

// ═══════════════════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════════════════

class AboutTextsEditorPage extends StatelessWidget {
  const AboutTextsEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fournit un contexte « sans données » pour résoudre les textes par défaut
    // (traductions) exactement comme la page publique.
    return Provider<Map<String, dynamic>?>.value(
      value: null,
      child: const _TextsEditorBody(),
    );
  }
}

class _TextsEditorBody extends StatefulWidget {
  const _TextsEditorBody();

  @override
  State<_TextsEditorBody> createState() => _TextsEditorBodyState();
}

class _TextsEditorBodyState extends State<_TextsEditorBody> {
  final AboutContentService _service = AboutContentService();

  Map<String, dynamic>? _db;
  bool _loaded = false;
  bool _seeded = false;
  bool _saving = false;
  String _lang = 'fr';

  /// Images du hero (colonnes `banner_url` et `avatar_path`).
  String? _bannerUrl;
  String? _avatarUrl;

  final Map<String, TextEditingController> _text = {};
  final Map<String, List<Map<String, TextEditingController>>> _lists = {};
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final items in _lists.values) {
      for (final item in items) {
        for (final c in item.values) {
          c.dispose();
        }
      }
    }
    super.dispose();
  }

  Future<void> _loadFromDb() async {
    final data = await _service.getContent();
    if (!mounted) return;
    setState(() {
      _db = data;
      _loaded = true;
    });
  }

  String _k(String column, String lang) => '$column|$lang';

  String _str(Object? v) => v == null ? '' : v.toString();

  String? _clean(Object? v) {
    final t = v is String ? v.trim() : '';
    return t.isEmpty ? null : t;
  }

  // ── Initialisation des contrôleurs (une seule fois, contexte disponible) ──

  List<Map<String, String>> _defaultItems(BuildContext ctx, String column) {
    switch (column) {
      case 'technique_steps':
        return [
          for (var i = 1; i <= 3; i++)
            {
              'title': ctx.aboutTr('about.step${i}_title'),
              'text': ctx.aboutTr('about.step${i}_text'),
            },
        ];
      case 'natural_dyes':
        return [
          for (final n in ['indigo', 'cola', 'baobab', 'teck'])
            {
              'title': ctx.aboutTr('about.${n}_title'),
              'text': ctx.aboutTr('about.${n}_text'),
            },
        ];
      case 'timeline_events':
        return [
          for (var i = 1; i <= 4; i++)
            {
              'year': ctx.aboutTr('about.timeline_year$i'),
              'title': ctx.aboutTr('about.timeline_title$i'),
              'description': ctx.aboutTr('about.timeline_desc$i'),
            },
        ];
      case 'stats':
        return [
          for (final n in ['aho', 'dyes', 'handmade', 'heritage'])
            {
              'value': ctx.aboutTr('about.stat_$n'),
              'label': ctx.aboutTr('about.stat_${n}_label'),
            },
        ];
      default:
        return const [];
    }
  }

  void _seed(BuildContext ctx) {
    _seeded = true;
    final appLang = ctx.read<LanguageProvider>().languageCode;
    if (_langs.contains(appLang)) _lang = appLang;
    final db = _db ?? <String, dynamic>{};

    // Images du hero
    _bannerUrl = _clean(db['banner_url']);
    _avatarUrl = _clean(db['avatar_path']) ?? _clean(db['avatar_url']);

    final rawHidden = db['hidden_fields'];
    _hidden
      ..clear()
      ..addAll(rawHidden is List ? rawHidden.map((e) => e.toString()) : []);

    for (final section in _sections) {
      for (final f in section.fields) {
        final langs = f.perLang ? _langs : [''];
        for (final lang in langs) {
          var value = lang.isEmpty
              ? _str(db[f.column])
              : _str(db['${f.column}_$lang'] ?? db[f.column]);
          final isDefaultLang = lang.isEmpty || lang == appLang;
          if (value.trim().isEmpty && isDefaultLang && f.trKey != null) {
            value = ctx.aboutTr(f.trKey!);
          }
          _text[_k(f.column, lang)] = TextEditingController(text: value);
        }
      }

      for (final l in section.lists) {
        for (final lang in _langs) {
          final raw = db['${l.column}_$lang'] ?? db[l.column];
          final items = <Map<String, TextEditingController>>[];

          if (raw is List && raw.isNotEmpty) {
            for (final e in raw) {
              if (l.stringList) {
                items.add({'value': TextEditingController(text: _str(e))});
              } else if (e is Map) {
                items.add({
                  for (final f in l.itemFields)
                    f.key: TextEditingController(text: _str(e[f.key])),
                });
              }
            }
          } else if (lang == appLang) {
            for (final d in _defaultItems(ctx, l.column)) {
              items.add({
                for (final f in l.itemFields)
                  f.key: TextEditingController(text: d[f.key] ?? ''),
              });
            }
          }
          _lists[_k(l.column, lang)] = items;
        }
      }
    }
  }

  // ── Sauvegarde ────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);

    try {
      final fields = <String, dynamic>{};

      // Images : n'écrase la base que si une image est définie.
      if (_bannerUrl != null && _bannerUrl!.isNotEmpty) {
        fields['banner_url'] = _bannerUrl;
      }
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        fields['avatar_path'] = _avatarUrl;
      }

      for (final section in _sections) {
        for (final f in section.fields) {
          if (!f.perLang) {
            final text = _text[_k(f.column, '')]!.text.trim();
            if (f.column == 'career_start_year') {
              fields[f.column] = int.tryParse(text);
            } else {
              fields[f.column] = text;
            }
            continue;
          }
          for (final lang in _langs) {
            fields['${f.column}_$lang'] = _text[_k(f.column, lang)]!.text.trim();
          }
        }

        for (final l in section.lists) {
          for (final lang in _langs) {
            final items = _lists[_k(l.column, lang)]!;
            if (l.stringList) {
              fields['${l.column}_$lang'] = items
                  .map((i) => i['value']!.text.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            } else {
              fields['${l.column}_$lang'] = items
                  .map((i) => {
                        for (final f in l.itemFields)
                          f.key: i[f.key]!.text.trim(),
                      })
                  .where((m) => m.values.any((v) => v.isNotEmpty))
                  .toList();
            }
          }
        }
      }

      fields['hidden_fields'] = _hidden.toList();

      await _service.updateContent(fields);
      messenger.showSnackBar(
        const SnackBar(content: Text('Page À propos enregistrée.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec de l\'enregistrement : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Thème admin (palette indigo, identique au reste du back-office) ──────

  ThemeData _adminTheme(BuildContext context) {
    final base = Theme.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.accent,
        onPrimary: AdminColors.textOnAccent,
        secondary: AdminColors.current,
        surface: AdminColors.surface,
        onSurface: AdminColors.text,
        error: AdminColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AdminColors.text,
        displayColor: AdminColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.bg.withValues(alpha: 0.5),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle:
            const TextStyle(color: AdminColors.textMuted, fontSize: 14),
        border: border(AdminColors.border),
        enabledBorder: border(AdminColors.border),
        disabledBorder: border(AdminColors.border.withValues(alpha: 0.4)),
        focusedBorder: border(AdminColors.accent, 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AdminColors.accent
              : AdminColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AdminColors.accent.withValues(alpha: 0.35)
              : AdminColors.surfaceHi,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? AdminColors.textMuted.withValues(alpha: 0.4)
                : AdminColors.text,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? AdminColors.textMuted.withValues(alpha: 0.4)
                : AdminColors.accent,
          ),
        ),
      ),
    );
  }

  // ── Construction UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_seeded) _seed(context);

    return Theme(
      data: _adminTheme(context),
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_about_editor_save',
          onPressed: _saving ? null : _save,
          backgroundColor: AdminColors.accent,
          foregroundColor: AdminColors.textOnAccent,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AdminColors.textOnAccent,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              children: [
                // Sélecteur de langue FIXE : reste visible pendant le défilement.
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      _buildImagesSection(),
                      for (final s in _sections) _buildSection(s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AdminColors.bg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              foregroundColor: AdminColors.textSecondary,
              selectedForegroundColor: AdminColors.textOnAccent,
              selectedBackgroundColor: AdminColors.accent,
              side: const BorderSide(color: AdminColors.border),
            ),
            segments: const [
              ButtonSegment(value: 'fr', label: Text('Français')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),
          const SizedBox(height: 8),
          const Text(
            'Champ vide = texte par défaut. Pour retirer un contenu de la '
            'page publique, désactivez « Afficher ».',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdminColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Section « Images » : photo de couverture et photo de profil.
  Widget _buildImagesSection() {
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: AdminColors.text,
    );

    return _card('Images', [
      const Text(
        'Touchez une image pour la remplacer, puis appuyez sur '
        '« Enregistrer » pour la publier.',
        style: TextStyle(color: AdminColors.textMuted, fontSize: 12),
      ),
      const SizedBox(height: 16),
      const Text('Photo de couverture', style: labelStyle),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = (width * 0.4).clamp(140.0, 240.0);
          return AdminAvatarPicker(
            imageUrl: _bannerUrl,
            storagePath: 'about_banners/banner.jpg',
            width: width,
            height: height,
            borderRadius: BorderRadius.circular(16),
            onImageSelected: (url) => setState(() => _bannerUrl = url),
          );
        },
      ),
      const SizedBox(height: 24),
      const Text('Photo de profil', style: labelStyle),
      const SizedBox(height: 8),
      Center(
        child: AdminAvatarPicker(
          imageUrl: _avatarUrl,
          storagePath: 'about_avatars/avatar.jpg',
          size: 110,
          onImageSelected: (url) => setState(() => _avatarUrl = url),
        ),
      ),
    ]);
  }

  Widget _buildSection(_Section s) {
    return _card(s.title, [
      for (final f in s.fields) _buildField(f),
      for (final l in s.lists) _buildList(l),
    ]);
  }

  Widget _visibilityRow(String label, String column, bool canHide) {
    final hidden = _hidden.contains(column);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AdminColors.text,
            ),
          ),
        ),
        if (canHide) ...[
          const Text(
            'Afficher',
            style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
          ),
          Switch(
            value: !hidden,
            onChanged: (visible) => setState(() {
              if (visible) {
                _hidden.remove(column);
              } else {
                _hidden.add(column);
              }
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildField(_Field f) {
    final controller = _text[_k(f.column, f.perLang ? _lang : '')]!;
    final hidden = f.canHide && _hidden.contains(f.column);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _visibilityRow(f.label, f.column, f.canHide),
          TextField(
            controller: controller,
            enabled: !hidden,
            minLines: f.multiline ? 3 : 1,
            maxLines: f.multiline ? 12 : 1,
            keyboardType:
                f.column == 'career_start_year' ? TextInputType.number : null,
          ),
        ],
      ),
    );
  }

  Widget _buildList(_ListSpec l) {
    final items = _lists[_k(l.column, _lang)]!;
    final hidden = l.canHide && _hidden.contains(l.column);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _visibilityRow(l.label, l.column, l.canHide),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            _buildItem(l, items, i, hidden),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: hidden
                  ? null
                  : () => setState(() {
                        items.add({
                          for (final f in l.itemFields)
                            f.key: TextEditingController(),
                        });
                      }),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    _ListSpec l,
    List<Map<String, TextEditingController>> items,
    int index,
    bool hidden,
  ) {
    final item = items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        children: [
          // IconButton conserve sa zone tactile par défaut de 48 px.
          Row(
            children: [
              Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMuted,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Monter',
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: hidden || index == 0
                    ? null
                    : () => setState(() {
                          final moved = items.removeAt(index);
                          items.insert(index - 1, moved);
                        }),
              ),
              IconButton(
                tooltip: 'Descendre',
                icon: const Icon(Icons.arrow_downward, size: 20),
                onPressed: hidden || index == items.length - 1
                    ? null
                    : () => setState(() {
                          final moved = items.removeAt(index);
                          items.insert(index + 1, moved);
                        }),
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AdminColors.danger,
                onPressed: hidden
                    ? null
                    : () => setState(() {
                          final removed = items.removeAt(index);
                          for (final c in removed.values) {
                            c.dispose();
                          }
                        }),
              ),
            ],
          ),
          for (final f in l.itemFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: item[f.key],
                enabled: !hidden,
                minLines: f.multiline ? 3 : 1,
                maxLines: f.multiline ? 10 : 1,
                decoration: InputDecoration(labelText: f.label),
              ),
            ),
        ],
      ),
    );
  }
}