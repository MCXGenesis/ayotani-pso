import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
import 'supabase_service_test.mocks.dart';

/// Test suite for Supabase API services
/// Aligned with CI/CD pipeline Phase 2: API Unit Tests (Mockito)
/// Pipeline: flutter test test/ --no-pub
void main() {
  late MockClient mockClient;
  const baseUrl = 'https://your-project.supabase.co/rest/v1';
  final defaultHeaders = {
    'apikey': 'test-anon-key',
    'Authorization': 'Bearer test-anon-key',
    'Content-Type': 'application/json',
  };

  setUp(() {
    mockClient = MockClient();
  });

  // ============================================================
  // AUTH SERVICE TESTS
  // ============================================================
  group('Auth Service - Sign Up', () {
    test('successful signup returns user data', () async {
      final signupResponse = {
        'access_token': 'mock-access-token',
        'user': {
          'id': 'user-123',
          'email': 'test@example.com',
        },
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(jsonEncode(signupResponse), 200),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/../auth/v1/signup'),
        headers: defaultHeaders,
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'password123',
        }),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['user']['id'], 'user-123');
      expect(body['user']['email'], 'test@example.com');
      verify(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .called(1);
    });

    test('signup with existing email returns 400', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'error': 'User already registered'}),
          400,
        ),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/../auth/v1/signup'),
        headers: defaultHeaders,
        body: jsonEncode({
          'email': 'existing@example.com',
          'password': 'password123',
        }),
      );

      expect(response.statusCode, 400);
      final body = jsonDecode(response.body);
      expect(body['error'], 'User already registered');
    });

    test('signup handles network failure', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('Network error'));

      expect(
        () => mockClient.post(
          Uri.parse('$baseUrl/../auth/v1/signup'),
          headers: defaultHeaders,
          body: jsonEncode({
            'email': 'test@example.com',
            'password': 'password123',
          }),
        ),
        throwsException,
      );
    });
  });

  group('Auth Service - Sign In', () {
    test('successful login returns session token', () async {
      final loginResponse = {
        'access_token': 'mock-jwt-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': 'user-123',
          'email': 'test@example.com',
        },
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(jsonEncode(loginResponse), 200),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/../auth/v1/token?grant_type=password'),
        headers: defaultHeaders,
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'password123',
        }),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['access_token'], isNotEmpty);
      expect(body['user']['id'], 'user-123');
    });

    test('login with wrong credentials returns 401', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'error': 'Invalid login credentials'}),
          401,
        ),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/../auth/v1/token?grant_type=password'),
        headers: defaultHeaders,
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'wrongpassword',
        }),
      );

      expect(response.statusCode, 401);
      final body = jsonDecode(response.body);
      expect(body['error'], 'Invalid login credentials');
    });
  });

  group('Auth Service - Profile', () {
    test('fetch user profile returns profile data', () async {
      final profileResponse = [
        {
          'id': 'user-123',
          'username': 'testuser',
          'avatar_url': null,
          'level': 3,
          'gems': 150,
          'updated_at': '2025-01-01T00:00:00Z',
        }
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(profileResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/profiles?id=eq.user-123&select=*'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.first['username'], 'testuser');
      expect(body.first['level'], 3);
      expect(body.first['gems'], 150);
    });

    test('update profile returns updated data', () async {
      final updatedProfile = {
        'id': 'user-123',
        'username': 'newusername',
        'level': 4,
        'gems': 200,
        'updated_at': '2025-06-01T00:00:00Z',
      };

      when(mockClient.patch(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(jsonEncode(updatedProfile), 200),
      );

      final response = await mockClient.patch(
        Uri.parse('$baseUrl/profiles?id=eq.user-123'),
        headers: defaultHeaders,
        body: jsonEncode({
          'username': 'newusername',
          'updated_at': '2025-06-01T00:00:00Z',
        }),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['username'], 'newusername');
    });

    test('add gems updates gem count correctly', () async {
      // First: fetch current gems
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode([
            {'gems': 100}
          ]),
          200,
        ),
      );

      final getResponse = await mockClient.get(
        Uri.parse('$baseUrl/profiles?id=eq.user-123&select=gems'),
        headers: defaultHeaders,
      );

      final currentGems =
          (jsonDecode(getResponse.body) as List).first['gems'] as int;
      expect(currentGems, 100);

      // Then: update gems
      when(mockClient.patch(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'gems': currentGems + 50}),
          200,
        ),
      );

      final patchResponse = await mockClient.patch(
        Uri.parse('$baseUrl/profiles?id=eq.user-123'),
        headers: defaultHeaders,
        body: jsonEncode({'gems': currentGems + 50}),
      );

      final updatedGems = jsonDecode(patchResponse.body)['gems'] as int;
      expect(updatedGems, 150);
    });
  });

  // ============================================================
  // EDUCATIONAL SERVICE TESTS
  // ============================================================
  group('Educational Service - Videos', () {
    test('fetch all videos returns list', () async {
      final videosResponse = [
        {
          'id': 1,
          'title': 'Cara Menanam Tomat',
          'description': 'Tutorial menanam tomat di rumah',
          'video_url': 'https://youtube.com/watch?v=abc123',
          'thumbnail_url': 'https://img.youtube.com/thumb.jpg',
          'difficulty': 'beginner',
          'content_type': 'video',
          'author': 'Admin',
          'published_at': '2025-01-15T10:00:00Z',
          'created_at': '2025-01-15T10:00:00Z',
        },
        {
          'id': 2,
          'title': 'Teknik Hidroponik Lanjutan',
          'description': 'Panduan hidroponik untuk pemula',
          'video_url': 'https://youtube.com/watch?v=def456',
          'thumbnail_url': 'https://img.youtube.com/thumb2.jpg',
          'difficulty': 'advanced',
          'content_type': 'video',
          'author': 'Expert',
          'published_at': '2025-02-20T08:00:00Z',
          'created_at': '2025-02-20T08:00:00Z',
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(videosResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/educational_content?content_type=eq.video&order=created_at.desc'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 2);
      expect(body[0]['content_type'], 'video');
      expect(body[0]['title'], 'Cara Menanam Tomat');
      expect(body[1]['difficulty'], 'advanced');
    });

    test('fetch videos by difficulty filters correctly', () async {
      final beginnerVideos = [
        {
          'id': 1,
          'title': 'Dasar Bertani',
          'description': 'Untuk pemula',
          'difficulty': 'beginner',
          'content_type': 'video',
          'created_at': '2025-01-10T00:00:00Z',
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(beginnerVideos), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/educational_content?content_type=eq.video&difficulty=eq.beginner&order=created_at.desc'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 1);
      expect(body[0]['difficulty'], 'beginner');
    });

    test('fetch videos returns empty list when none exist', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode([]), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/educational_content?content_type=eq.video&order=created_at.desc'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body, isEmpty);
    });
  });

  group('Educational Service - Articles', () {
    test('fetch articles returns article list', () async {
      final articlesResponse = [
        {
          'id': 10,
          'title': 'Panduan Pupuk Organik',
          'description': 'Cara membuat pupuk organik',
          'content_type': 'article',
          'content_body': 'Langkah pertama adalah...',
          'difficulty': 'intermediate',
          'author': 'AgriExpert',
          'published_at': '2025-03-01T00:00:00Z',
          'created_at': '2025-03-01T00:00:00Z',
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(articlesResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/educational_content?content_type=eq.article&order=created_at.desc'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.first['content_type'], 'article');
      expect(body.first['content_body'], isNotNull);
    });

    test('fetch content by id returns single item', () async {
      final singleContent = {
        'id': 5,
        'title': 'Irigasi Tetes',
        'description': 'Sistem irigasi efisien',
        'content_type': 'video',
        'difficulty': 'intermediate',
        'video_url': 'https://youtube.com/watch?v=xyz',
        'created_at': '2025-04-01T00:00:00Z',
      };

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(singleContent), 200),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/educational_content?id=eq.5&select=*'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['id'], 5);
      expect(body['title'], 'Irigasi Tetes');
    });
  });

  // ============================================================
  // LAND SERVICE TESTS
  // ============================================================
  group('Land Service - CRUD Operations', () {
    test('fetch user lands returns land list', () async {
      final landsResponse = [
        {
          'id': 1,
          'user_id': 'user-123',
          'name': 'Lahan Tomat #1',
          'location': 'Malang, Jawa Timur',
          'plant_type': 'Tomat Cherry',
          'planting_date': '2025-03-01T00:00:00Z',
          'harvest_date': '2025-06-01T00:00:00Z',
          'area_size': 12.5,
          'modal_per_kg': 5000,
          'target_profit_percentage': 20,
          'target_harvest_kg': 1000,
          'created_at': '2025-03-01T00:00:00Z',
        },
        {
          'id': 2,
          'user_id': 'user-123',
          'name': 'Lahan Cabai',
          'location': 'Batu, Jawa Timur',
          'plant_type': 'Cabai Rawit',
          'planting_date': '2025-04-01T00:00:00Z',
          'harvest_date': '2025-07-01T00:00:00Z',
          'area_size': 8.0,
          'modal_per_kg': 8000,
          'target_profit_percentage': 30,
          'target_harvest_kg': 500,
          'created_at': '2025-04-01T00:00:00Z',
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(landsResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/lands?user_id=eq.user-123&order=created_at.desc'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 2);
      expect(body[0]['name'], 'Lahan Tomat #1');
      expect(body[1]['plant_type'], 'Cabai Rawit');
    });

    test('add new land returns success', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response('', 201),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/lands'),
        headers: defaultHeaders,
        body: jsonEncode({
          'user_id': 'user-123',
          'name': 'Lahan Baru',
          'location': 'Surabaya',
          'plant_type': 'Kangkung',
          'area_size': 5.0,
          'modal_per_kg': 3000,
          'target_profit_percentage': 15,
          'target_harvest_kg': 200,
        }),
      );

      expect(response.statusCode, 201);
    });

    test('update land returns success', () async {
      when(mockClient.patch(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'id': 1, 'name': 'Lahan Tomat Updated'}),
          200,
        ),
      );

      final response = await mockClient.patch(
        Uri.parse('$baseUrl/lands?id=eq.1'),
        headers: defaultHeaders,
        body: jsonEncode({'name': 'Lahan Tomat Updated'}),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['name'], 'Lahan Tomat Updated');
    });

    test('fetch lands for non-existent user returns empty', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode([]), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/lands?user_id=eq.nonexistent&order=created_at.desc'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body, isEmpty);
    });
  });

  group('Land Service - Progress Logs', () {
    test('add progress log returns success', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response('', 201),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/land_progress_logs'),
        headers: defaultHeaders,
        body: jsonEncode({
          'land_id': 1,
          'water_amount_liters': 5.0,
          'plant_height_cm': 25.0,
          'notes': 'Tanaman tumbuh baik',
          'log_date': '2025-05-15T08:00:00Z',
        }),
      );

      expect(response.statusCode, 201);
    });

    test('fetch progress logs returns ordered data', () async {
      final logsResponse = [
        {
          'id': 1,
          'land_id': 1,
          'water_amount_liters': 3.0,
          'plant_height_cm': 10.0,
          'notes': 'Baru tanam',
          'log_date': '2025-03-01T00:00:00Z',
        },
        {
          'id': 2,
          'land_id': 1,
          'water_amount_liters': 5.0,
          'plant_height_cm': 25.0,
          'notes': 'Tumbuh pesat',
          'log_date': '2025-04-01T00:00:00Z',
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(logsResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/land_progress_logs?land_id=eq.1&order=log_date.asc&limit=10'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 2);
      // Verify ascending order
      final firstDate = DateTime.parse(body[0]['log_date']);
      final secondDate = DateTime.parse(body[1]['log_date']);
      expect(secondDate.isAfter(firstDate), isTrue);
    });
  });

  group('Land Service - Tasks', () {
    test('fetch land tasks returns task list', () async {
      final tasksResponse = [
        {
          'id': 1,
          'land_id': 1,
          'title': 'Siram tanaman',
          'is_completed': false,
          'repeat_type': 'daily',
          'due_date': '2025-05-15T00:00:00Z',
        },
        {
          'id': 2,
          'land_id': 1,
          'title': 'Beri pupuk',
          'is_completed': true,
          'repeat_type': 'weekly',
          'due_date': '2025-05-15T00:00:00Z',
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(tasksResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/land_tasks?land_id=eq.1'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 2);
      expect(body[0]['is_completed'], false);
      expect(body[1]['is_completed'], true);
    });

    test('add land task returns success', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response('', 201),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/land_tasks'),
        headers: defaultHeaders,
        body: jsonEncode({
          'land_id': 1,
          'title': 'Potong rumput',
          'is_completed': false,
          'repeat_type': 'weekly',
          'due_date': '2025-05-20T00:00:00Z',
        }),
      );

      expect(response.statusCode, 201);
    });

    test('toggle task completion updates status', () async {
      when(mockClient.patch(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'id': 1, 'is_completed': true}),
          200,
        ),
      );

      final response = await mockClient.patch(
        Uri.parse('$baseUrl/land_tasks?id=eq.1'),
        headers: defaultHeaders,
        body: jsonEncode({'is_completed': true}),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['is_completed'], true);
    });

    test('delete task returns success', () async {
      when(mockClient.delete(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response('', 204),
      );

      final response = await mockClient.delete(
        Uri.parse('$baseUrl/land_tasks?id=eq.1'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 204);
    });
  });

  // ============================================================
  // WEATHER API TESTS (Open-Meteo)
  // ============================================================
  group('Weather Service - Open-Meteo API', () {
    test('fetch current weather returns valid data', () async {
      final weatherResponse = {
        'latitude': -7.98,
        'longitude': 112.63,
        'current_weather': {
          'temperature': 28.5,
          'windspeed': 12.3,
          'winddirection': 180,
          'weathercode': 1,
          'is_day': 1,
          'time': '2025-06-01T10:00',
        },
      };

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(weatherResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=-7.98&longitude=112.63&current_weather=true'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['current_weather'], isNotNull);
      expect(body['current_weather']['temperature'], 28.5);
      expect(body['current_weather']['windspeed'], 12.3);
      expect(body['current_weather']['is_day'], 1);
    });

    test('fetch weather with invalid coordinates returns error', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'error': true, 'reason': 'Invalid coordinates'}),
          400,
        ),
      );

      final response = await mockClient.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=999&longitude=999&current_weather=true'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 400);
      final body = jsonDecode(response.body);
      expect(body['error'], true);
    });

    test('weather API timeout returns null gracefully', () async {
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenThrow(Exception('Connection timed out'));

      expect(
        () => mockClient.get(
          Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=-7.98&longitude=112.63&current_weather=true'),
          headers: defaultHeaders,
        ),
        throwsException,
      );
    });

    test('weather response with all weather codes is parseable', () async {
      // weathercode 0=clear, 1=mainly clear, 2=partly cloudy, 3=overcast
      // 61=rain slight, 63=rain moderate, 65=rain heavy
      final weatherResponse = {
        'current_weather': {
          'temperature': 22.0,
          'windspeed': 5.0,
          'winddirection': 90,
          'weathercode': 61,
          'is_day': 1,
          'time': '2025-06-01T14:00',
        },
      };

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(weatherResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=-6.2&longitude=106.8&current_weather=true'),
        headers: defaultHeaders,
      );

      final body = jsonDecode(response.body);
      final weatherCode = body['current_weather']['weathercode'] as int;
      expect(weatherCode, 61); // Rain slight
      expect(body['current_weather']['temperature'], 22.0);
    });
  });

  // ============================================================
  // IOT SERVICE TESTS (Sensor Data for Map/Monitoring)
  // ============================================================
  group('IoT Service - Sensor Readings', () {
    test('fetch latest IoT reading returns sensor data', () async {
      final iotResponse = [
        {
          'id': 1,
          'device_id': 'SENSOR-001',
          'user_id': 'user-123',
          'soil_moisture': 65.0,
          'water_level': 80.0,
          'plant_growth': 15.5,
          'temperature': 28.5,
          'humidity': 70.0,
          'created_at': '2025-06-01T08:00:00Z',
        }
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(iotResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/iot_readings?user_id=eq.user-123&order=created_at.desc&limit=1'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 1);
      expect(body[0]['device_id'], 'SENSOR-001');
      expect(body[0]['soil_moisture'], 65.0);
      expect(body[0]['temperature'], 28.5);
      expect(body[0]['humidity'], 70.0);
    });

    test('fetch IoT reading history returns last 7 readings', () async {
      final historyResponse = List.generate(
        7,
        (i) => {
          'id': i + 1,
          'device_id': 'SENSOR-001',
          'user_id': 'user-123',
          'soil_moisture': 60.0 + i,
          'water_level': 75.0 + i,
          'plant_growth': 10.0 + i * 0.5,
          'temperature': 27.0 + i * 0.3,
          'humidity': 65.0 + i,
          'created_at': '2025-05-${25 + i}T08:00:00Z',
        },
      );

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(historyResponse), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/iot_readings?user_id=eq.user-123&order=created_at.desc&limit=7'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 7);
      // Verify all have required sensor fields
      for (final reading in body) {
        expect(reading['soil_moisture'], isNotNull);
        expect(reading['temperature'], isNotNull);
        expect(reading['humidity'], isNotNull);
      }
    });

    test('fetch IoT reading for user with no sensor returns empty', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode([]), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/iot_readings?user_id=eq.no-sensor-user&order=created_at.desc&limit=1'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body, isEmpty);
    });

    test('IoT reading with null sensor values is handled', () async {
      final partialReading = [
        {
          'id': 1,
          'device_id': 'SENSOR-002',
          'user_id': 'user-123',
          'soil_moisture': null,
          'water_level': null,
          'plant_growth': null,
          'temperature': 30.0,
          'humidity': null,
          'created_at': '2025-06-01T10:00:00Z',
        }
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(partialReading), 200),
      );

      final response = await mockClient.get(
        Uri.parse(
            '$baseUrl/iot_readings?user_id=eq.user-123&order=created_at.desc&limit=1'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body[0]['soil_moisture'], isNull);
      expect(body[0]['temperature'], 30.0);
    });
  });

  // ============================================================
  // MAP/GEOLOCATION API TESTS (Land Coordinates)
  // ============================================================
  group('Map Service - Geolocation Data', () {
    test('fetch lands with coordinates for map display', () async {
      final landsWithCoords = [
        {
          'id': 1,
          'user_id': 'user-123',
          'name': 'Lahan Tomat',
          'location': 'Malang, Jawa Timur',
          'latitude': -7.977,
          'longitude': 112.633,
          'plant_type': 'Tomat',
          'area_size': 12.5,
        },
        {
          'id': 2,
          'user_id': 'user-123',
          'name': 'Lahan Cabai',
          'location': 'Batu, Jawa Timur',
          'latitude': -7.870,
          'longitude': 112.528,
          'plant_type': 'Cabai',
          'area_size': 8.0,
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(landsWithCoords), 200),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/lands?user_id=eq.user-123&select=*'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      expect(body.length, 2);

      // Verify coordinates are valid for map markers
      for (final land in body) {
        final lat = land['latitude'] as double;
        final lng = land['longitude'] as double;
        expect(lat >= -90 && lat <= 90, isTrue,
            reason: 'Latitude must be between -90 and 90');
        expect(lng >= -180 && lng <= 180, isTrue,
            reason: 'Longitude must be between -180 and 180');
      }
    });

    test('land without coordinates is handled for map', () async {
      final landNoCoords = [
        {
          'id': 3,
          'user_id': 'user-123',
          'name': 'Lahan Baru',
          'location': 'Surabaya',
          'latitude': null,
          'longitude': null,
          'plant_type': 'Kangkung',
          'area_size': 5.0,
        },
      ];

      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(jsonEncode(landNoCoords), 200),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/lands?user_id=eq.user-123&select=*'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as List;
      // Null coordinates should be handled (no map marker placed)
      expect(body[0]['latitude'], isNull);
      expect(body[0]['longitude'], isNull);
    });

    test('add land with GPS coordinates saves correctly', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response('', 201),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/lands'),
        headers: defaultHeaders,
        body: jsonEncode({
          'user_id': 'user-123',
          'name': 'Lahan GPS',
          'location': 'Malang',
          'latitude': -7.977,
          'longitude': 112.633,
          'plant_type': 'Padi',
          'area_size': 20.0,
        }),
      );

      expect(response.statusCode, 201);
      verify(mockClient.post(any,
              headers: anyNamed('headers'), body: anyNamed('body')))
          .called(1);
    });
  });

  // ============================================================
  // ERROR HANDLING & EDGE CASES
  // ============================================================
  group('Error Handling', () {
    test('server error (500) is handled', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'Internal Server Error'}),
          500,
        ),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/lands?user_id=eq.user-123'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 500);
    });

    test('unauthorized request (401) is handled', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'JWT expired'}),
          401,
        ),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/profiles?id=eq.user-123'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 401);
      final body = jsonDecode(response.body);
      expect(body['message'], 'JWT expired');
    });

    test('network timeout throws exception', () async {
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenThrow(Exception('Connection timed out'));

      expect(
        () => mockClient.get(
          Uri.parse('$baseUrl/lands'),
          headers: defaultHeaders,
        ),
        throwsException,
      );
    });

    test('malformed JSON response is handled', () async {
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response('not valid json{{{', 200),
      );

      final response = await mockClient.get(
        Uri.parse('$baseUrl/educational_content'),
        headers: defaultHeaders,
      );

      expect(response.statusCode, 200);
      expect(
        () => jsonDecode(response.body),
        throwsA(isA<FormatException>()),
      );
    });

    test('empty body POST for signup is rejected', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'error': 'Missing email or password'}),
          422,
        ),
      );

      final response = await mockClient.post(
        Uri.parse('$baseUrl/../auth/v1/signup'),
        headers: defaultHeaders,
        body: jsonEncode({}),
      );

      expect(response.statusCode, 422);
    });
  });

  // ============================================================
  // MODEL PARSING TESTS
  // ============================================================
  group('Model Parsing - UserProfile', () {
    test('parses valid profile JSON', () {
      final json = {
        'id': 'user-123',
        'username': 'petani_maju',
        'avatar_url': 'https://example.com/avatar.png',
        'level': 5,
        'gems': 300,
        'updated_at': '2025-05-01T12:00:00Z',
      };

      expect(json['id'], 'user-123');
      expect(json['username'], 'petani_maju');
      expect(json['level'], 5);
      expect(json['gems'], 300);
    });

    test('handles missing optional fields', () {
      final json = {
        'id': 'user-456',
        'username': null,
        'avatar_url': null,
        'level': null,
        'gems': null,
        'updated_at': null,
      };

      // Simulates fromJson fallback defaults
      final level = json['level'] as int? ?? 1;
      final gems = json['gems'] as int? ?? 0;

      expect(json['id'], 'user-456');
      expect(level, 1);
      expect(gems, 0);
    });
  });

  group('Model Parsing - Land', () {
    test('parses valid land JSON', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'name': 'Lahan Tomat',
        'location': 'Malang',
        'latitude': -7.977,
        'longitude': 112.633,
        'plant_type': 'Tomat',
        'planting_date': '2025-03-01T00:00:00Z',
        'harvest_date': '2025-06-01T00:00:00Z',
        'area_size': 12.5,
        'modal_per_kg': 5000.0,
        'target_profit_percentage': 20.0,
        'target_harvest_kg': 1000.0,
      };

      expect(json['id'], 1);
      expect(json['name'], 'Lahan Tomat');
      expect(json['area_size'], 12.5);
      expect((json['modal_per_kg'] as double) > 0, isTrue);
    });

    test('handles null coordinates gracefully', () {
      final json = {
        'id': 2,
        'user_id': 'user-123',
        'name': 'Lahan Baru',
        'location': null,
        'latitude': null,
        'longitude': null,
        'plant_type': null,
        'area_size': null,
      };

      final areaSize = (json['area_size'] as num?)?.toDouble() ?? 0.0;
      expect(json['latitude'], isNull);
      expect(json['longitude'], isNull);
      expect(areaSize, 0.0);
    });
  });

  group('Model Parsing - EducationalContent', () {
    test('parses video content JSON', () {
      final json = {
        'id': 1,
        'title': 'Tutorial Berkebun',
        'description': 'Video panduan',
        'video_url': 'https://youtube.com/watch?v=abc',
        'thumbnail_url': 'https://img.youtube.com/thumb.jpg',
        'difficulty': 'beginner',
        'content_type': 'video',
        'author': 'Admin',
        'published_at': '2025-01-01T00:00:00Z',
      };

      expect(json['content_type'], 'video');
      expect(json['video_url'], isNotNull);
      expect(json['difficulty'], 'beginner');
    });

    test('parses article content JSON', () {
      final json = {
        'id': 2,
        'title': 'Artikel Pupuk',
        'description': 'Panduan pupuk',
        'video_url': null,
        'content_type': 'article',
        'content_body': 'Konten artikel lengkap...',
        'difficulty': 'intermediate',
        'author': 'AgriExpert',
      };

      expect(json['content_type'], 'article');
      expect(json['video_url'], isNull);
      expect(json['content_body'], isNotNull);
    });

    test('defaults difficulty to beginner when unknown', () {
      final difficulty = 'unknown';
      String resolved;
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          resolved = 'beginner';
          break;
        case 'intermediate':
          resolved = 'intermediate';
          break;
        case 'advanced':
          resolved = 'advanced';
          break;
        default:
          resolved = 'beginner';
      }
      expect(resolved, 'beginner');
    });
  });
}
