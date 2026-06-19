import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ayotani/providers/auth_provider.dart';
import 'package:ayotani/providers/cart_provider.dart';
import 'package:ayotani/routes/app_routes.dart';
import 'package:ayotani/theme/app_colors.dart';

/// Call this in setUp() or at the top of main() in each test file
/// to suppress GoogleFonts async errors that fire after tests complete.
void suppressGoogleFontsErrors() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// A test wrapper that sets up the app with providers and optional initial route.
/// This avoids requiring real Supabase initialization for E2E widget tests.
class TestApp extends StatelessWidget {
  final String initialRoute;

  const TestApp({
    super.key,
    this.initialRoute = '/splash',
  });

  @override
  Widget build(BuildContext context) {
    HttpOverrides.global = TestHttpOverrides();
    GoogleFonts.config.allowRuntimeFetching = false;
    
    // Ignore image loading / codec exceptions and GoogleFonts errors in tests to prevent flakiness
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final exceptionStr = details.exception.toString();
      if (exceptionStr.contains('Codec failed') ||
          exceptionStr.contains('image codec') ||
          exceptionStr.contains('ImageCodecException') ||
          exceptionStr.contains('Image resource service') ||
          exceptionStr.contains('GoogleFonts') ||
          exceptionStr.contains('google_fonts')) {
        return;
      }
      originalOnError?.call(details);
    };

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ayo Tani - Test',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
          fontFamily: 'Inter',
        ),
        initialRoute: initialRoute,
        routes: AppRoutes.routes,
      ),
    );
  }
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

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
      final isWeather = uri != null && uri.host.contains('open-meteo.com');
      return Future.value(_MockHttpClientRequest(isWeather: isWeather));
    }
    if (name == #userAgent) return 'MockUserAgent';
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  final bool isWeather;
  _MockHttpClientRequest({this.isWeather = false});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #headers) {
      return _MockHttpHeaders(isWeather: isWeather);
    }
    if (name == #close) {
      return Future.value(_MockHttpClientResponse(isWeather: isWeather));
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

class _MockHttpHeaders implements HttpHeaders {
  final bool isWeather;
  _MockHttpHeaders({this.isWeather = false});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #chunkedTransferEncoding) return false;
    if (name == #contentLength) return -1;
    if (name == #persistentConnection) return true;
    if (name == #contentType) {
      return ContentType.parse(isWeather ? 'application/json' : 'image/png');
    }
    return null;
  }
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final bool isWeather;
  _MockHttpClientResponse({this.isWeather = false});

  static final List<int> _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='
  );

  static final List<int> _weatherJsonBytes = utf8.encode(
    '{"current": {"temperature_2m": 27.5, "relative_humidity_2m": 80, "precipitation": 0.0, "wind_speed_10m": 12.0}, "current_weather": {"temperature": 27.5, "windspeed": 12.0, "winddirection": 90, "weathercode": 1}}'
  );

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final bytes = isWeather ? _weatherJsonBytes : _transparentPng;
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
    final bytes = isWeather ? _weatherJsonBytes : _transparentPng;
    if (name == #statusCode) {
      return 200;
    }
    if (name == #contentLength) {
      return bytes.length;
    }
    if (name == #headers) {
      return _MockHttpHeaders(isWeather: isWeather);
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
