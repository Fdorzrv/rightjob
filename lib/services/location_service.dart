// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationResult {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
  });

  String get displayCity => city.isNotEmpty ? city : state;
}

class LocationService {
  /// Solicita permiso GPS al navegador y retorna la ciudad detectada.
  /// Retorna null si el usuario rechaza o hay error.
  static Future<LocationResult?> requestLocation() {
    final completer = Completer<LocationResult?>();

    try {
      html.window.navigator.geolocation.getCurrentPosition(
        timeout: const Duration(seconds: 10),
      ).then((pos) async {
        final lat = pos.coords!.latitude!.toDouble();
        final lng = pos.coords!.longitude!.toDouble();
        final result = await _reverseGeocode(lat, lng);
        completer.complete(result);
      }).catchError((_) {
        completer.complete(null);
      });
    } catch (_) {
      completer.complete(null);
    }

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => null,
    );
  }

  /// Convierte coordenadas a ciudad usando Nominatim (OpenStreetMap, gratuito)
  static Future<LocationResult?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=es',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'RightJobApp/1.0',
      });

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};

      final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'] ??
              '')
          .toString();

      return LocationResult(
        latitude: lat,
        longitude: lng,
        city: city,
        state: (address['state'] ?? '').toString(),
        country: (address['country'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }
}