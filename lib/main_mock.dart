import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'providers/theme_provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup HttpOverrides to mock all network calls (Supabase API, Weather, Images) on native platforms
  if (!kIsWeb) {
    HttpOverrides.global = MockHttpOverrides();
  }

  // Initialize Supabase client with dummy placeholder credentials and custom httpClient for cross-platform (Web) support
  await Supabase.initialize(
    url: 'https://placeholder.supabase.co',
    anonKey: 'placeholder_key',
    httpClient: MockSupabaseHttpClient(),
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
      if (uri != null && uri!.host.contains('open-meteo.com')) {
        return ContentType.parse('application/json');
      }
      if (uri != null && uri!.host.contains('supabase.co')) {
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

  List<int> _getResponseBody() {
    final path = uri.path;
    final host = uri.host;

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

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final bytes = _getResponseBody();
    return Stream<List<int>>.fromIterable([bytes]).listen(
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

/// Cross-platform mock HTTP client for Supabase that works on Web
class MockSupabaseHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    final responseHelper = _MockHttpClientResponse(uri: uri);
    final bytes = responseHelper._getResponseBody();
    
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
      },
    );
  }
}
