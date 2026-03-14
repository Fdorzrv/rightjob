import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show FileUploadInputElement;
import '../services/image_compress_service.dart';
import '../services/storage_upload_service.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Abre la galería y devuelve la imagen en base64 comprimida (compatible web + móvil)
  static Future<String?> pickFromGallery() async {
    try {
      if (kIsWeb) {
        // En web: usar FileUploadInputElement + compresión con Canvas
        final input = html.FileUploadInputElement()
          ..accept = 'image/*'
          ..click();
        await input.onChange.first;
        final file = input.files?.first;
        if (file == null) return null;
        // Comprimir antes de guardar
        return await ImageCompressService.compressImageFile(file);
      } else {
        // En móvil: image_picker ya comprime
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 600,
          maxHeight: 600,
          imageQuality: 75,
        );
        if (file == null) return null;
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final mimeType = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
        return 'data:$mimeType;base64,$base64';
      }
    } catch (_) {
      return null;
    }
  }

  /// Sube imagen a Firebase Storage y devuelve la URL
  static Future<String?> pickAndUploadProfileImage() async {
    final base64 = await pickFromGallery();
    if (base64 == null) return null;
    // Subir a Storage y obtener URL pública
    final url = await StorageUploadService.uploadProfileImage(base64);
    // Si falla Storage, usar base64 como fallback
    return url ?? base64;
  }

  /// Widget de avatar tappable reutilizable
  static Widget buildAvatarPicker({
    required String? imageData,
    required bool isCompany,
    required double radius,
    required VoidCallback onTap,
    bool showEditBadge = true,
  }) {
    final bool hasImage = imageData != null && imageData.isNotEmpty;
    final bool isBase64 = hasImage && imageData.startsWith('data:');
    final bool isUrl = hasImage && (imageData.startsWith('http://') || imageData.startsWith('https://'));

    ImageProvider? imageProvider;
    if (isBase64) {
      final base64Data = imageData.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Data));
    } else if (isUrl) {
      imageProvider = NetworkImage(imageData);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(isCompany ? Icons.business : Icons.person,
                      size: radius * 1.0, color: const Color(0xFF1976D2))
                  : null,
            ),
          ),
          if (showEditBadge)
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  /// Bottom sheet para seleccionar foto
  static Future<String?> showPickerSheet(BuildContext context, {String? currentImage, required bool isCompany}) async {
    String? result = currentImage;
    final TextEditingController urlCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final bool hasPreview = result != null && result!.isNotEmpty;
          final bool isBase64 = hasPreview && result!.startsWith('data:');
          final bool isUrl = hasPreview && (result!.startsWith('http://') || result!.startsWith('https://'));
          ImageProvider? preview;
          if (isBase64) preview = MemoryImage(base64Decode(result!.split(',').last));
          else if (isUrl) preview = NetworkImage(result!);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text("Cambiar foto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Preview
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: preview,
                    child: preview == null
                        ? Icon(isCompany ? Icons.business : Icons.person, size: 52, color: Colors.blue)
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // Botón galería
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final picked = await ImagePickerHelper.pickFromGallery();
                        if (picked != null) setSheet(() => result = picked);
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Elegir de la Galería", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // O separador
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("o pega una URL", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ]),
                  const SizedBox(height: 12),

                  // Campo URL
                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(
                      hintText: "https://...",
                      prefixIcon: const Icon(Icons.link, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Colors.blue),
                        onPressed: () {
                          if (urlCtrl.text.isNotEmpty) setSheet(() => result = urlCtrl.text.trim());
                        },
                      ),
                    ),
                    onSubmitted: (v) { if (v.isNotEmpty) setSheet(() => result = v.trim()); },
                  ),
                  const SizedBox(height: 16),

                  // Confirmar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Guardar Foto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );

    return result;
  }
}