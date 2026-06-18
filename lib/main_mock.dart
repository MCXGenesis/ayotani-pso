import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'providers/theme_provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

void main() {
  final mockClient = MockHttpClientWeb();

  http.runWithClient(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Setup HttpOverrides to mock all network calls (Supabase API, Weather, Images)
    HttpOverrides.global = MockHttpOverrides();

    // Initialize Supabase client with dummy placeholder credentials and our web-compatible httpClient
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder_key',
      httpClient: mockClient,
    );

    // Setup Flutter error filtering for image loading/codec issues in mock mode
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionStr = details.exception.toString();
      if (exceptionStr.contains('Codec failed') ||
          exceptionStr.contains('image codec') ||
          exceptionStr.contains('ImageCodecException') ||
          exceptionStr.contains('Image resource service')) {
        return; // Suppress image codec/loading exceptions
      }
      originalOnError?.call(details);
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const App(),
      ),
    );
  }, () => mockClient);
}

/// HttpOverrides to inject the MockHttpClient
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

/// A Mock HttpClient that intercepts weather API, Supabase Auth/Rest APIs, and images
class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #open || 
        name == #openUrl ||
        name == #getUrl || 
        name == #get ||
        name == #post ||
        name == #postUrl ||
        name == #put ||
        name == #putUrl ||
        name == #delete ||
        name == #deleteUrl ||
        name == #head ||
        name == #headUrl) {
      Uri? uri;
      for (final arg in invocation.positionalArguments) {
        if (arg is Uri) {
          uri = arg;
          break;
        }
      }
      return Future.value(_MockHttpClientRequest(uri: uri));
    }
    if (name == #userAgent) return 'MockUserAgent';
    return null;
  }
}

/// Mock HttpClientRequest
class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final Uri uri;
  _MockHttpClientRequest({Uri? uri}) : uri = uri ?? Uri.parse('https://placeholder.supabase.co');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #headers) {
      return _MockHttpHeaders(uri: uri);
    }
    if (name == #close) {
      return Future.value(_MockHttpClientResponse(uri: uri));
    }
    if (name == #done) {
      return Future<void>.value();
    }
    if (name == #flush) {
      return Future<void>.value();
    }
    if (name == #addStream) {
      return Future<void>.value();
    }
    return null;
  }
}

/// Mock HttpHeaders
class _MockHttpHeaders implements HttpHeaders {
  final Uri uri;
  _MockHttpHeaders({required this.uri});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #chunkedTransferEncoding) return false;
    if (name == #contentLength) return -1;
    if (name == #persistentConnection) return true;
    if (name == #contentType) {
      if (uri != null && (uri!.host.contains('open-meteo.com') ||
                          uri!.host.contains('supabase.co') ||
                          uri!.host.contains('bmkg.go.id') ||
                          uri!.host.contains('api.bmkg.go.id'))) {
        return ContentType.parse('application/json');
      }
      return ContentType.parse('image/png');
    }
    return null;
  }
}

/// Mock HttpClientResponse serving mock databases and authentication
class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri uri;
  _MockHttpClientResponse({required this.uri});

  static final List<int> _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='
  );

  static final List<int> _weatherJsonBytes = utf8.encode(
    '{"current": {"temperature_2m": 28.2, "relative_humidity_2m": 78, "precipitation": 0.0, "wind_speed_10m": 8.5}, "current_weather": {"temperature": 28.2, "windspeed": 8.5, "winddirection": 120, "weathercode": 2}}'
  );

  // Mock Supabase Auth signup/signin payload
  static final List<int> _supabaseAuthBytes = utf8.encode(jsonEncode({
    "access_token": "mock-access-token-123456",
    "token_type": "bearer",
    "expires_in": 3600,
    "refresh_token": "mock-refresh-token",
    "user": {
      "id": "mock-user-uuid-1111-2222-3333-444444444444",
      "aud": "authenticated",
      "role": "authenticated",
      "email": "petani@ayotani.com",
      "email_confirmed_at": "2026-06-09T00:00:00Z",
      "phone": "",
      "confirmed_at": "2026-06-09T00:00:00Z",
      "last_sign_in_at": "2026-06-09T00:00:00Z",
      "app_metadata": {
        "provider": "email",
        "providers": ["email"]
      },
      "user_metadata": {},
      "identities": [],
      "created_at": "2026-06-09T00:00:00Z",
      "updated_at": "2026-06-09T00:00:00Z"
    }
  }));

  // Mock Profile database record
  static final List<int> _supabaseProfileBytes = utf8.encode(jsonEncode([
    {
      "id": "mock-user-uuid-1111-2222-3333-444444444444",
      "username": "Pak Petani Makmur",
      "avatar_url": null,
      "level": 3,
      "gems": 250,
      "updated_at": "2026-06-09T00:00:00Z"
    }
  ]));

  // Mock Lands database records
  static final List<int> _supabaseLandsBytes = utf8.encode(jsonEncode([
    {
      "id": 1,
      "user_id": "mock-user-uuid-1111-2222-3333-444444444444",
      "name": "Sawah Padi Sentosa",
      "location": "Nganjuk, Jawa Timur",
      "plant_type": "Padi",
      "planting_date": "2026-05-15T00:00:00Z",
      "harvest_date": "2026-09-15T00:00:00Z",
      "area_size": 2.4,
      "modal_per_kg": 4200,
      "target_profit_percentage": 25,
      "target_harvest_kg": 1500,
      "created_at": "2026-05-15T00:00:00Z"
    },
    {
      "id": 2,
      "user_id": "mock-user-uuid-1111-2222-3333-444444444444",
      "name": "Kebun Jagung Manis",
      "location": "Batu, Malang",
      "plant_type": "Jagung",
      "planting_date": "2026-06-01T00:00:00Z",
      "harvest_date": "2026-08-30T00:00:00Z",
      "area_size": 1.2,
      "modal_per_kg": 3500,
      "target_profit_percentage": 30,
      "target_harvest_kg": 800,
      "created_at": "2026-06-01T00:00:00Z"
    }
  ]));

  // Mock Land Progress Logs
  static final List<int> _supabaseProgressLogsBytes = utf8.encode(jsonEncode([
    {
      "id": 1,
      "land_id": 1,
      "water_amount_liters": 12.5,
      "plant_height_cm": 15.0,
      "notes": "Pertumbuhan awal sangat subur",
      "log_date": "2026-05-25T08:00:00Z"
    },
    {
      "id": 2,
      "land_id": 1,
      "water_amount_liters": 15.0,
      "plant_height_cm": 28.5,
      "notes": "Daun mulai lebat dan hijau segar",
      "log_date": "2026-06-05T08:00:00Z"
    }
  ]));

  // Mock Land Tasks
  static final List<int> _supabaseLandTasksBytes = utf8.encode(jsonEncode([
    {
      "id": 1,
      "land_id": 1,
      "title": "Penyiraman Pagi",
      "description": "Siram secara merata di area sawah",
      "due_date": DateTime.now().toIso8601String(),
      "repeat_type": "daily",
      "is_completed": false
    },
    {
      "id": 2,
      "land_id": 1,
      "title": "Pemupukan Susulan",
      "description": "Gunakan pupuk NPK",
      "due_date": DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      "repeat_type": "none",
      "is_completed": false
    }
  ]));

  // Mock IoT Readings
  static final List<int> _supabaseIotBytes = utf8.encode(jsonEncode([
    {
      "id": 1,
      "device_id": "DEV-001",
      "user_id": "mock-user-uuid-1111-2222-3333-444444444444",
      "soil_moisture": 62.0,
      "water_level": 75.0,
      "plant_growth": 14.8,
      "temperature": 27.8,
      "humidity": 68.0,
      "created_at": DateTime.now().toIso8601String()
    }
  ]));

  // Mock Daily Tasks
  static final List<int> _supabaseDailyTasksBytes = utf8.encode(jsonEncode([
    {
      "id": 1,
      "title": "Siram Lahan",
      "description": "Lakukan penyiraman pada lahan Anda pagi ini.",
      "reward_gems": 10,
      "category": "watering",
      "created_at": "2026-06-09T00:00:00Z"
    },
    {
      "id": 2,
      "title": "Periksa IoT",
      "description": "Buka dashboard IoT dan periksa tingkat kelembaban tanah.",
      "reward_gems": 5,
      "category": "monitoring",
      "created_at": "2026-06-09T00:00:00Z"
    },
    {
      "id": 3,
      "title": "Baca Artikel Edukasi",
      "description": "Baca satu artikel tentang cara pencegahan hama tanaman.",
      "reward_gems": 15,
      "category": "education",
      "created_at": "2026-06-09T00:00:00Z"
    }
  ]));

  // Mock User Tasks list with nested daily tasks details
  static final List<int> _supabaseUserTasksBytes = utf8.encode(jsonEncode([
    {
      "id": 101,
      "profile_id": "mock-user-uuid-1111-2222-3333-444444444444",
      "daily_task_id": 1,
      "status": "pending",
      "completed_at": null,
      "daily_tasks": {
        "id": 1,
        "title": "Siram Lahan",
        "description": "Lakukan penyiraman pada lahan Anda pagi ini.",
        "reward_gems": 10,
        "category": "watering",
        "created_at": "2026-06-09T00:00:00Z"
      }
    },
    {
      "id": 102,
      "profile_id": "mock-user-uuid-1111-2222-3333-444444444444",
      "daily_task_id": 2,
      "status": "pending",
      "completed_at": null,
      "daily_tasks": {
        "id": 2,
        "title": "Periksa IoT",
        "description": "Buka dashboard IoT dan periksa tingkat kelembaban tanah.",
        "reward_gems": 5,
        "category": "monitoring",
        "created_at": "2026-06-09T00:00:00Z"
      }
    }
  ]));

  // Mock Educational Content
  static final List<int> _supabaseEducationalBytes = utf8.encode(jsonEncode([
    {
      "id": 1,
      "title": "Teknik Pemupukan Organik Modern",
      "description": "Pelajari cara memupuk tanaman padi menggunakan bahan organik secara efisien untuk hasil panen maksimal.",
      "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "thumbnail_url": "https://images.unsplash.com/photo-1593113630400-ea4288922497",
      "difficulty": "beginner",
      "content_type": "video",
      "content_body": null,
      "author": "Ir. Budi Santoso",
      "published_at": "2026-06-01T08:00:00Z"
    },
    {
      "id": 2,
      "title": "Pengenalan Sistem Irigasi Tetes",
      "description": "Artikel ini membahas dasar-dasar instalasi irigasi tetes (drip irrigation) di lahan sempit.",
      "video_url": null,
      "thumbnail_url": "https://images.unsplash.com/photo-1463936575829-25148e1db1b8",
      "difficulty": "intermediate",
      "content_type": "article",
      "content_body": "Irigasi tetes adalah metode irigasi yang menghemat air dan pupuk dengan membiarkan air menetes pelan-pelan ke akar tanaman, baik melalui permukaan tanah atau langsung ke zona akar. Sistem ini dirancang untuk mendistribusikan air secara merata ke seluruh tanaman...",
      "author": "Dr. Siti Aminah",
      "published_at": "2026-06-03T10:00:00Z"
    }
  ]));

  // Mock single items created or updated
  static final List<int> _supabaseSingleOrderBytes = utf8.encode(jsonEncode({
    "id": 999,
    "user_id": "mock-user-uuid-1111-2222-3333-444444444444",
    "total_price": 50000.0,
    "status": "pending",
    "shipping_address": "Surabaya",
    "payment_method": "COD",
    "created_at": "2026-06-09T00:00:00Z"
  }));

  static final List<int> _supabaseSingleOrderItemBytes = utf8.encode(jsonEncode({
    "id": 888,
    "order_id": 999,
    "product_id": 1,
    "quantity": 1,
    "price_at_purchase": 50000.0,
    "created_at": "2026-06-09T00:00:00Z"
  }));

  static final List<int> _emptyArrayBytes = utf8.encode('[]');
  static final List<int> _emptyObjectBytes = utf8.encode('{}');

  // Mock BMKG API response
  static final List<int> _bmkgWeatherBytes = utf8.encode(jsonEncode({
    "lokasi": {
      "adm1": "35", "adm2": "35.78", "adm3": "35.78.15", "adm4": "35.78.15.1001",
      "provinsi": "Jawa Timur", "kotkab": "Kota Surabaya",
      "kecamatan": "Genteng", "desa": "Genteng",
      "lon": 112.7378, "lat": -7.2576, "timezone": "+0700"
    },
    "data": [{
      "lokasi": {
        "adm1": "35", "adm2": "35.78", "adm3": "35.78.15", "adm4": "35.78.15.1001",
        "provinsi": "Jawa Timur", "kotkab": "Kota Surabaya",
        "kecamatan": "Genteng", "desa": "Genteng",
        "lon": 112.7378, "lat": -7.2576, "timezone": "+0700", "type": "adm4"
      },
      "cuaca": [[
        {
          "datetime": "2026-06-18T02:00:00Z", "t": 30, "tcc": 5, "tp": 0.0,
          "weather": 0, "weather_desc": "Cerah", "weather_desc_en": "Sunny",
          "wd_deg": 86, "wd": "NE", "wd_to": "SW", "ws": 7.2, "hu": 62,
          "vs": 14000, "vs_text": "> 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-am.svg",
          "utc_datetime": "2026-06-18 02:00:00",
          "local_datetime": "2026-06-18 09:00:00"
        },
        {
          "datetime": "2026-06-18T05:00:00Z", "t": 33, "tcc": 10, "tp": 0.0,
          "weather": 0, "weather_desc": "Cerah", "weather_desc_en": "Sunny",
          "wd_deg": 38, "wd": "N", "wd_to": "S", "ws": 8.3, "hu": 55,
          "vs": 15000, "vs_text": "> 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-am.svg",
          "utc_datetime": "2026-06-18 05:00:00",
          "local_datetime": "2026-06-18 12:00:00"
        },
        {
          "datetime": "2026-06-18T08:00:00Z", "t": 31, "tcc": 20, "tp": 0.1,
          "weather": 1, "weather_desc": "Cerah Berawan", "weather_desc_en": "Partly Cloudy",
          "wd_deg": 13, "wd": "N", "wd_to": "S", "ws": 11.7, "hu": 68,
          "vs": 9850, "vs_text": "< 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-berawan-am.svg",
          "utc_datetime": "2026-06-18 08:00:00",
          "local_datetime": "2026-06-18 15:00:00"
        },
        {
          "datetime": "2026-06-18T11:00:00Z", "t": 28, "tcc": 8, "tp": 0.0,
          "weather": 0, "weather_desc": "Cerah", "weather_desc_en": "Sunny",
          "wd_deg": 39, "wd": "N", "wd_to": "S", "ws": 9.0, "hu": 72,
          "vs": 12000, "vs_text": "> 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-pm.svg",
          "utc_datetime": "2026-06-18 11:00:00",
          "local_datetime": "2026-06-18 18:00:00"
        }
      ],[
        {
          "datetime": "2026-06-18T17:00:00Z", "t": 27, "tcc": 15, "tp": 0.0,
          "weather": 1, "weather_desc": "Cerah Berawan", "weather_desc_en": "Partly Cloudy",
          "wd_deg": 165, "wd": "SE", "wd_to": "NW", "ws": 6.1, "hu": 77,
          "vs": 9500, "vs_text": "< 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-pm.svg",
          "utc_datetime": "2026-06-18 17:00:00",
          "local_datetime": "2026-06-19 00:00:00"
        },
        {
          "datetime": "2026-06-18T23:00:00Z", "t": 26, "tcc": 0, "tp": 0.0,
          "weather": 0, "weather_desc": "Cerah", "weather_desc_en": "Sunny",
          "wd_deg": 101, "wd": "E", "wd_to": "W", "ws": 4.1, "hu": 80,
          "vs": 10000, "vs_text": "> 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-am.svg",
          "utc_datetime": "2026-06-18 23:00:00",
          "local_datetime": "2026-06-19 06:00:00"
        }
      ],[
        {
          "datetime": "2026-06-19T05:00:00Z", "t": 32, "tcc": 0, "tp": 0.0,
          "weather": 0, "weather_desc": "Cerah", "weather_desc_en": "Sunny",
          "wd_deg": 26, "wd": "N", "wd_to": "S", "ws": 9.3, "hu": 52,
          "vs": 16000, "vs_text": "> 10 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-am.svg",
          "utc_datetime": "2026-06-19 05:00:00",
          "local_datetime": "2026-06-19 12:00:00"
        },
        {
          "datetime": "2026-06-19T11:00:00Z", "t": 29, "tcc": 40, "tp": 0.2,
          "weather": 2, "weather_desc": "Cerah Berawan", "weather_desc_en": "Partly Cloudy",
          "wd_deg": 64, "wd": "NE", "wd_to": "SW", "ws": 3.1, "hu": 78,
          "vs": 8000, "vs_text": "< 9 km",
          "image": "https://api-apps.bmkg.go.id/storage/icon/cuaca/cerah-berawan-pm.svg",
          "utc_datetime": "2026-06-19 11:00:00",
          "local_datetime": "2026-06-19 18:00:00"
        }
      ]]
    }]
  }));

  List<int> _getResponseBody() {
    final path = uri.path;
    final host = uri.host;

    if (host.contains('api.bmkg.go.id') || host.contains('bmkg.go.id')) {
      return _adjustBmkgWeatherBytes(_bmkgWeatherBytes);
    }

    if (host.contains('open-meteo.com')) {
      return _weatherJsonBytes;
    }

    if (host.contains('supabase.co') || host.contains('supabase')) {
      if (path.contains('/auth/v1/token') || path.contains('/auth/v1/signup')) {
        return _supabaseAuthBytes;
      }
      if (path.contains('/auth/v1/logout')) {
        return _emptyObjectBytes;
      }
      if (path.contains('/rest/v1/profiles')) {
        return _supabaseProfileBytes;
      }
      if (path.contains('/rest/v1/lands')) {
        return _supabaseLandsBytes;
      }
      if (path.contains('/rest/v1/land_progress_logs')) {
        return _supabaseProgressLogsBytes;
      }
      if (path.contains('/rest/v1/land_tasks')) {
        return _supabaseLandTasksBytes;
      }
      if (path.contains('/rest/v1/iot_readings')) {
        return _supabaseIotBytes;
      }
      if (path.contains('/rest/v1/daily_tasks')) {
        return _supabaseDailyTasksBytes;
      }
      if (path.contains('/rest/v1/user_tasks')) {
        return _supabaseUserTasksBytes;
      }
      if (path.contains('/rest/v1/educational_content')) {
        return _supabaseEducationalBytes;
      }
      if (path.contains('/rest/v1/orders')) {
        return _supabaseSingleOrderBytes;
      }
      if (path.contains('/rest/v1/order_items')) {
        return _supabaseSingleOrderItemBytes;
      }
      return _emptyArrayBytes;
    }

    // Default to image mock for network image fetches
    return _transparentPng;
  }

  Future<List<int>> _fetchRealBmkg() async {
    final currentOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      final client = HttpClient();
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final bytes = await resp.reduce((a, b) => [...a, ...b]);
      return bytes;
    } catch (e) {
      print('[MockHttpClient] Real BMKG request failed: $e, falling back to mock');
      return _getResponseBody();
    } finally {
      HttpOverrides.global = currentOverrides;
    }
  }

  Future<List<int>> _fetchRealNetwork() async {
    final currentOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    try {
      final client = HttpClient();
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final bytes = await resp.reduce((a, b) => [...a, ...b]);
      return bytes;
    } catch (e) {
      print('[MockHttpClient] Real network request failed for $uri: $e');
      return _getResponseBody();
    } finally {
      HttpOverrides.global = currentOverrides;
    }
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    Stream<List<int>> stream;
    final host = uri.host;
    final isBmkg = host.contains('api.bmkg.go.id') || host.contains('bmkg.go.id');
    final isMockTarget = host.contains('supabase.co') || 
                         host.contains('open-meteo.com') ||
                         host.contains('placeholder.supabase.co');

    if (isBmkg) {
      stream = Stream.fromFuture(_fetchRealBmkg());
    } else if (!isMockTarget) {
      stream = Stream.fromFuture(_fetchRealNetwork());
    } else {
      stream = Stream.value(_getResponseBody());
    }
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    final bytes = _getResponseBody();
    if (name == #statusCode) {
      return 200;
    }
    if (name == #contentLength) {
      return bytes.length;
    }
    if (name == #headers) {
      return _MockHttpHeaders(uri: uri);
    }
    if (name == #compressionState) {
      return HttpClientResponseCompressionState.notCompressed;
    }
    if (name == #isRedirect) {
      return false;
    }
    if (name == #persistentConnection) {
      return true;
    }
    if (name == #reasonPhrase) {
      return 'OK';
    }
    if (name == #cookies) {
      return const <Cookie>[];
    }
    if (name == #redirects) {
      return const <RedirectInfo>[];
    }
    return null;
  }
}

/// A Web-compatible mock http Client that overrides all http requests on the Web platform.
class MockHttpClientWeb extends http.BaseClient {
  List<int> _getResponseBody(Uri uri) {
    final path = uri.path;
    final host = uri.host;

    if (host.contains('api.bmkg.go.id') || host.contains('bmkg.go.id')) {
      return _adjustBmkgWeatherBytes(_MockHttpClientResponse._bmkgWeatherBytes);
    }

    if (host.contains('open-meteo.com')) {
      return _MockHttpClientResponse._weatherJsonBytes;
    }

    if (host.contains('supabase.co') || host.contains('supabase')) {
      if (path.contains('/auth/v1/token') || path.contains('/auth/v1/signup')) {
        return _MockHttpClientResponse._supabaseAuthBytes;
      }
      if (path.contains('/auth/v1/logout')) {
        return _MockHttpClientResponse._emptyObjectBytes;
      }
      if (path.contains('/rest/v1/profiles')) {
        return _MockHttpClientResponse._supabaseProfileBytes;
      }
      if (path.contains('/rest/v1/lands')) {
        return _MockHttpClientResponse._supabaseLandsBytes;
      }
      if (path.contains('/rest/v1/land_progress_logs')) {
        return _MockHttpClientResponse._supabaseProgressLogsBytes;
      }
      if (path.contains('/rest/v1/land_tasks')) {
        return _MockHttpClientResponse._supabaseLandTasksBytes;
      }
      if (path.contains('/rest/v1/iot_readings')) {
        return _MockHttpClientResponse._supabaseIotBytes;
      }
      if (path.contains('/rest/v1/daily_tasks')) {
        return _MockHttpClientResponse._supabaseDailyTasksBytes;
      }
      if (path.contains('/rest/v1/user_tasks')) {
        return _MockHttpClientResponse._supabaseUserTasksBytes;
      }
      if (path.contains('/rest/v1/educational_content')) {
        return _MockHttpClientResponse._supabaseEducationalBytes;
      }
      if (path.contains('/rest/v1/orders')) {
        return _MockHttpClientResponse._supabaseSingleOrderBytes;
      }
      if (path.contains('/rest/v1/order_items')) {
        return _MockHttpClientResponse._supabaseSingleOrderItemBytes;
      }
      return _MockHttpClientResponse._emptyArrayBytes;
    }

    return _MockHttpClientResponse._transparentPng;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('[MockHttpClientWeb] send: ${request.method} ${request.url}');
    final host = request.url.host;
    
    // Check if it is a request to BMKG (which we want to attempt live first, then fallback to mock)
    final isBmkg = host.contains('api.bmkg.go.id') || host.contains('bmkg.go.id');
    
    // Check if it is other mock targets (Supabase or Open-Meteo)
    final isMockTarget = host.contains('supabase.co') || 
                         host.contains('open-meteo.com') ||
                         host.contains('placeholder.supabase.co');

    if (isBmkg) {
      try {
        final response = await Zone.root.run(() async {
          final client = http.Client();
          return await client.send(request);
        });
        print('[MockHttpClientWeb] BMKG request success!');
        return response;
      } catch (e) {
        print('[MockHttpClientWeb] BMKG request failed: $e, falling back to mock');
      }
    } else if (!isMockTarget) {
      // For any other domains (like Google Fonts, unsplash images), load them for real!
      try {
        final response = await Zone.root.run(() async {
          final client = http.Client();
          return await client.send(request);
        });
        return response;
      } catch (e) {
        print('[MockHttpClientWeb] Real network request failed for ${request.url}: $e');
      }
    }

    final bytes = _getResponseBody(request.url);
    final headers = <String, String>{};
    if (request.url.host.contains('open-meteo.com') ||
        request.url.host.contains('supabase.co') ||
        request.url.host.contains('bmkg.go.id') ||
        request.url.host.contains('api.bmkg.go.id')) {
      headers['content-type'] = 'application/json';
    } else {
      headers['content-type'] = 'image/png';
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      contentLength: bytes.length,
      request: request,
      headers: headers,
    );
  }
}

/// Helper function to dynamically adjust BMKG weather dates to match real-time
List<int> _adjustBmkgWeatherBytes(List<int> originalBytes) {
  try {
    final rawJson = utf8.decode(originalBytes);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final adjustedJson = rawJson
        .replaceAll('2026-06-18', todayStr)
        .replaceAll('2026-06-19', tomorrowStr);
    return utf8.encode(adjustedJson);
  } catch (_) {
    return originalBytes;
  }
}
