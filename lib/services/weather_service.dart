import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

/// Service untuk mengambil data cuaca dari API resmi BMKG (Badan Meteorologi,
/// Klimatologi, dan Geofisika Indonesia).
///
/// Endpoint: https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4={kode_wilayah}
///
/// Kode wilayah level IV (ADM4) untuk beberapa kota pertanian:
/// - Surabaya (Genteng): 35.78.15.1001
/// - Malang Kota: 35.73.13.1001
/// - Banyuwangi: 35.10.03.2001
/// - Jombang: 35.17.01.2001
/// - Kediri: 35.71.01.1001
class WeatherService {
  static const String _bmkgBaseUrl =
      'https://api.bmkg.go.id/publik/prakiraan-cuaca';

  // Open-Meteo fallback untuk getCurrentWeather (lat/lng based)
  static const String _openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';

  // Pemetaan kode ADM4 BMKG – daftar kota pertanian Jawa Timur
  static const Map<String, String> cityAdm4Codes = {
    'Surabaya': '35.78.15.1001',
    'Malang': '35.73.13.1001',
    'Banyuwangi': '35.10.03.2001',
    'Jombang': '35.17.01.2001',
    'Kediri': '35.71.01.1001',
    'Jember': '35.09.04.2001',
    'Sidoarjo': '35.15.01.2001',
    'Mojokerto': '35.76.01.1001',
    'Pasuruan': '35.14.02.2001',
    'Probolinggo': '35.79.01.1001',
  };

  static const String _defaultAdm4 = '35.78.15.1001'; // Surabaya Genteng

  // ──────────────────────────────────────────────
  // COMPATIBILITY: Digunakan oleh halaman-halaman lama (monitoring, add_land)
  // Mengembalikan format Map yang sama seperti Open-Meteo sebelumnya.
  // ──────────────────────────────────────────────

  /// Fetch cuaca berdasarkan koordinat (lat/long).
  /// Mengembalikan Map dengan key 'current' berisi data suhu, kelembapan, angin.
  Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_openMeteoUrl?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m'
        '&timezone=auto',
      );
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[WeatherService.getCurrentWeather] Error: $e');
      return null;
    }
  }

  /// Fetch data prakiraan cuaca dari BMKG berdasarkan kode ADM4.
  Future<BmkgWeatherData?> getWeatherByAdm4(String adm4Code) async {
    try {
      final url = Uri.parse('$_bmkgBaseUrl?adm4=$adm4Code');
      debugPrint('[WeatherService] Fetching BMKG: $url');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final weather = BmkgWeatherData.fromJson(data);
        debugPrint(
            '[WeatherService] Success – ${weather.allEntries.length} entries');
        return weather;
      } else {
        debugPrint('[WeatherService] HTTP ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      debugPrint('[WeatherService] Error: $e\n$st');
      return null;
    }
  }

  /// Fetch data cuaca untuk kota berdasarkan nama kota.
  Future<BmkgWeatherData?> getWeatherByCity(String cityName) async {
    final code = cityAdm4Codes[cityName] ?? _defaultAdm4;
    return getWeatherByAdm4(code);
  }

  /// Fetch data cuaca default (Surabaya).
  Future<BmkgWeatherData?> getDefaultWeather() async {
    return getWeatherByAdm4(_defaultAdm4);
  }

  /// Daftar nama kota yang tersedia.
  static List<String> get availableCities => cityAdm4Codes.keys.toList();
}