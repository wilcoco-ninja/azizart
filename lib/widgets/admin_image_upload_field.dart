import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_compressor_service.dart';
import 'optimized_image.dart';

class AdminImageUploadField extends StatefulWidget {
  final String? initialImageUrl;
  final bool isBanner;

  /// Profil de compression. Par défaut : bannière si [isBanner], sinon œuvre
  /// (2400 px). Pour une photo de profil, passer `ImageTargetType.avatar`.
  final ImageTargetType? targetType;

  /// Dossier R2 pour résoudre un [initialImageUrl] relatif.
  final String? folder;

  /// Reçoit les octets compressés et un nom de fichier dont l'extension
  /// correspond au contenu réel.
  final Function(Uint8List bytes, String fileName) onImageSelected;

  const AdminImageUploadField({
    super.key,
    this.initialImageUrl,
    this.isBanner = false,
    this.targetType,
    this.folder,
    required this.onImageSelected,
  });

  @override
  State<AdminImageUploadField> createState() => _AdminImageUploadFieldState();
}

class _AdminImageUploadFieldState extends State<AdminImageUploadField> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _previewBytes;
  bool _isProcessing = false;

  ImageTargetType get _target =>
      widget.targetType ??
      (widget.isBanner ? ImageTargetType.banner : ImageTargetType.artwork);

  static String _baseName(String fileName) {
    final name = fileName.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    return base.isEmpty ? 'image' : base;
  }

  Future<void> _pickAndProcessImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      if (mounted) setState(() => _isProcessing = true);

      final rawBytes = await pickedFile.readAsBytes();
      final result = await ImageCompressorService.compress(
        rawBytes: rawBytes,
        type: _target,
        fileName: pickedFile.name,
      );

      if (!mounted) return;
      setState(() {
        _previewBytes = result.bytes;
        _isProcessing = false;
      });

      widget.onImageSelected(
        result.bytes,
        '${_baseName(pickedFile.name)}.${result.extension}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du traitement de l\'image : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialImageUrl;
    final hasInitial = initial != null && initial.trim().isNotEmpty;

    return MouseRegion(
      cursor: _isProcessing
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isProcessing ? null : _pickAndProcessImage,
        child: Container(
          height: widget.isBanner ? 180 : 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : _previewBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _previewBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : hasInitial
                      ? OptimizedImage(
                          url: initial,
                          folder: widget.folder,
                          borderRadius: BorderRadius.circular(12),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Cliquez pour ajouter une image'),
                          ],
                        ),
        ),
      ),
    );
  }
}