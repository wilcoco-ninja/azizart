/*
 * Developed by Wilcoco
 * Application: AzizArt
 * Description: Éditeur générique de listes dynamiques pour l'admin.
 */

import 'package:flutter/material.dart';
import '../../../theme/aziz_colors.dart';

class ListEditorWidget<T> extends StatefulWidget {
  final List<T> items;
  final ValueChanged<List<T>> onChanged;
  final String Function(T item) itemTitle;
  final String Function(T item)? itemSubtitle;
  final IconData Function(T item)? itemIcon;
  final IconData fallbackIcon;
  final Widget Function(
    BuildContext context,
    T initial,
    ValueChanged<T> onSave,
  ) editorBuilder;
  final T Function() createEmpty;
  final Key Function(T item, int index)? itemKey;
  final String addButtonLabel;
  final String emptyStateLabel;
  final String sheetTitleAdd;
  final String sheetTitleEdit;
  final int? maxItems;

  const ListEditorWidget({
    super.key,
    required this.items,
    required this.onChanged,
    required this.itemTitle,
    required this.editorBuilder,
    required this.createEmpty,
    this.itemSubtitle,
    this.itemIcon,
    this.fallbackIcon = Icons.label_outline,
    this.itemKey,
    this.addButtonLabel = 'Ajouter',
    this.emptyStateLabel = 'Aucun élément pour le moment',
    this.sheetTitleAdd = 'Ajouter',
    this.sheetTitleEdit = 'Modifier',
    this.maxItems,
  });

  @override
  State<ListEditorWidget<T>> createState() => _ListEditorWidgetState<T>();
}

class _ListEditorWidgetState<T> extends State<ListEditorWidget<T>> {
  bool get _reachedMax =>
      widget.maxItems != null && widget.items.length >= widget.maxItems!;

  void _openEditor({T? initial, int? indexToReplace}) {
    // Calculé une seule fois : le builder du sheet est rappelé à chaque
    // changement du clavier et ne doit pas recréer un élément vide.
    final seed = initial ?? widget.createEmpty();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              // La hauteur disponible exclut le clavier (padding ci-dessus).
              maxHeight: (MediaQuery.sizeOf(sheetContext).height -
                      MediaQuery.viewInsetsOf(sheetContext).bottom) *
                  0.88,
            ),
            decoration: const BoxDecoration(
              color: AzizColors.backgroundMedium,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AzizColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  initial == null
                      ? widget.sheetTitleAdd
                      : widget.sheetTitleEdit,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 17,
                    color: AzizColors.saffron,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: widget.editorBuilder(
                      sheetContext,
                      seed,
                      (result) {
                        final updated = List<T>.from(widget.items);
                        if (indexToReplace != null) {
                          updated[indexToReplace] = result;
                        } else {
                          updated.add(result);
                        }
                        widget.onChanged(updated);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AzizColors.surface,
        title: const Text(
          'Supprimer cet élément ?',
          style: TextStyle(color: AzizColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          widget.itemTitle(widget.items[index]),
          style: const TextStyle(color: AzizColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AzizColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final updated = List<T>.from(widget.items)..removeAt(index);
      widget.onChanged(updated);
    }
  }

  /// Flutter 3.41+ : `onReorderItem` fournit déjà un newIndex ajusté.
  /// NE PAS soustraire 1 — l'API le fait déjà pour nous.
  void _reorder(int oldIndex, int newIndex) {
    final updated = List<T>.from(widget.items);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            child: Text(
              widget.emptyStateLabel,
              style: const TextStyle(
                color: AzizColors.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: widget.items.length,
            onReorderItem: _reorder,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final icon =
                  widget.itemIcon?.call(item) ?? widget.fallbackIcon;
              final subtitle = widget.itemSubtitle?.call(item);

              return Container(
                // Clé stable (identité de l'élément) : une clé basée sur
                // l'index décale l'état après un réordonnancement. Pour des
                // éléments égaux par valeur (ex. String), fournir `itemKey`.
                key: widget.itemKey?.call(item, index) ?? ObjectKey(item),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AzizColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AzizColors.cardBorder.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AzizColors.backgroundMedium,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: AzizColors.saffron, size: 20),
                    ),
                  ),
                  title: Text(
                    widget.itemTitle(item),
                    style: const TextStyle(
                      color: AzizColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: subtitle != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              color: AzizColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: AzizColors.textPrimary,
                        ),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        onPressed: () => _openEditor(
                          initial: item,
                          indexToReplace: index,
                        ),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: AzizColors.error,
                        ),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        onPressed: () => _confirmDelete(index),
                        tooltip: 'Supprimer',
                      ),
                      const SizedBox(width: 4),
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.drag_handle_rounded,
                            color: AzizColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        if (!_reachedMax)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AzizColors.saffron.withValues(alpha: 0.1),
              foregroundColor: AzizColors.saffron,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              widget.addButtonLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            onPressed: () => _openEditor(),
          ),
      ],
    );
  }
}