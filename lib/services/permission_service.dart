import 'package:flutter/foundation.dart';

class PermissionService {
  // En web siempre retorna true — los permisos los maneja el navegador
  static Future<bool> requestGallery() async => true;
  static Future<bool> requestCamera() async => true;
  static Future<bool> requestStorage() async => true;
  static Future<bool> requestNotifications() async => true;
  static Future<bool> hasGalleryPermission() async => true;
  static Future<bool> hasCameraPermission() async => true;
}