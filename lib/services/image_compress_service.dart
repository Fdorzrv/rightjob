import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Servicio de compresión de imágenes para web
/// Usa Canvas para redimensionar y comprimir antes de guardar en Firestore
class ImageCompressService {
  // Límites máximos
  static const int _maxWidthPx = 600;      // Máximo 600px de ancho
  static const int _maxHeightPx = 600;     // Máximo 600px de alto
  static const double _jpegQuality = 0.75; // 75% calidad JPEG
  static const int _maxFileSizeBytes = 400 * 1024; // 400 KB máximo
  static const int _maxPdfSizeBytes = 2 * 1024 * 1024; // 2 MB máximo para PDF

  /// Comprime una imagen desde un File de HTML y devuelve base64
  static Future<String?> compressImageFile(html.File file) async {
    try {
      // Leer el archivo como Data URL
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      final dataUrl = reader.result as String;

      // Comprimir usando Canvas
      return await compressDataUrl(dataUrl);
    } catch (e) {
      return null;
    }
  }

  /// Comprime una imagen desde un Data URL (base64) usando Canvas
  static Future<String?> compressDataUrl(String dataUrl) async {
    try {
      // Crear elemento imagen en el DOM temporal
      final img = html.ImageElement();
      img.src = dataUrl;
      await img.onLoad.first;

      final origWidth = img.naturalWidth ?? 800;
      final origHeight = img.naturalHeight ?? 800;

      // Calcular nuevas dimensiones manteniendo proporción
      double newWidth = origWidth.toDouble();
      double newHeight = origHeight.toDouble();

      if (newWidth > _maxWidthPx || newHeight > _maxHeightPx) {
        final ratioX = _maxWidthPx / newWidth;
        final ratioY = _maxHeightPx / newHeight;
        final ratio = ratioX < ratioY ? ratioX : ratioY;
        newWidth = (newWidth * ratio).floorToDouble();
        newHeight = (newHeight * ratio).floorToDouble();
      }

      // Dibujar en canvas con nuevas dimensiones
      final canvas = html.CanvasElement(
        width: newWidth.toInt(),
        height: newHeight.toInt(),
      );
      final ctx = canvas.context2D;
      ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);

      // Exportar como JPEG comprimido
      final compressedDataUrl = canvas.toDataUrl('image/jpeg', _jpegQuality);

      // Verificar tamaño final
      final base64Part = compressedDataUrl.split(',').last;
      final sizeBytes = base64Part.length * 3 ~/ 4;

      if (sizeBytes > _maxFileSizeBytes) {
        // Si aún es muy grande, comprimir más agresivamente
        return canvas.toDataUrl('image/jpeg', 0.5);
      }

      return compressedDataUrl;
    } catch (e) {
      return null;
    }
  }

  /// Valida que un PDF no exceda el tamaño máximo
  static bool isPdfSizeValid(Uint8List bytes) {
    return bytes.length <= _maxPdfSizeBytes;
  }

  /// Devuelve el tamaño legible de un base64
  static String getReadableSize(String base64Data) {
    final bytes = base64Data.length * 3 ~/ 4;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Valida que una imagen base64 no exceda el límite
  static bool isImageSizeValid(String base64DataUrl) {
    final base64Part = base64DataUrl.split(',').last;
    final bytes = base64Part.length * 3 ~/ 4;
    return bytes <= _maxFileSizeBytes;
  }
}