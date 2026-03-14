import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'image_compress_service.dart';

/// Servicio para subir archivos a Firebase Storage
/// Reemplaza el almacenamiento de base64 en Firestore
class StorageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── SUBIR FOTO DE PERFIL ────────────────────────────────────────────────
  /// Sube la foto de perfil a Storage y devuelve la URL pública
  static Future<String?> uploadProfileImage(String base64DataUrl) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Comprimir antes de subir
      final compressed = await ImageCompressService.compressDataUrl(base64DataUrl);
      if (compressed == null) return null;

      // Convertir base64 a bytes
      final base64Data = compressed.split(',').last;
      final bytes = base64Decode(base64Data);

      // Subir a Storage en profiles/{uid}/profile.jpg
      final ref = _storage.ref().child('profiles/$uid/profile.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': uid},
      );

      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return null;
    }
  }

  // ── SUBIR IMAGEN EN CHAT ────────────────────────────────────────────────
  /// Sube una imagen del chat y devuelve la URL pública
  static Future<String?> uploadChatImage(String base64DataUrl, String chatId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Comprimir antes de subir
      final compressed = await ImageCompressService.compressDataUrl(base64DataUrl);
      if (compressed == null) return null;

      final base64Data = compressed.split(',').last;
      final bytes = base64Decode(base64Data);

      // Nombre único por timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('chats/$chatId/$uid/$timestamp.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': uid, 'chatId': chatId},
      );

      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── SUBIR PDF EN CHAT ───────────────────────────────────────────────────
  /// Sube un PDF del chat y devuelve la URL pública
  static Future<String?> uploadChatPdf(Uint8List bytes, String fileName, String chatId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      // Validar tamaño
      if (!ImageCompressService.isPdfSizeValid(bytes)) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = _storage.ref().child('chats/$chatId/$uid/${timestamp}_$safeName');
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {'uploadedBy': uid, 'originalName': fileName},
      );

      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── ELIMINAR ARCHIVOS AL BORRAR CUENTA ─────────────────────────────────
  /// Elimina todos los archivos de un usuario de Storage
  static Future<void> deleteUserFiles(String uid) async {
    try {
      final profileRef = _storage.ref().child('profiles/$uid');
      final items = await profileRef.listAll();
      for (final item in items.items) {
        await item.delete();
      }
    } catch (_) {}
  }
}