import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ayotani/routes/app_routes.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: 'https://placeholder.supabase.co',
    anonKey: 'placeholder_key',
  );

  // Suppress GoogleFonts async errors that occur after test completion
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exception.toString();
      if (msg.contains('GoogleFonts') || msg.contains('google_fonts')) {
        return; // Suppress font loading errors in CI
      }
      originalOnError?.call(details);
    };
  });

  // ============================================================
  // AUTH FLOW E2E TESTS
  // ============================================================
  group('E2E: Auth Flow', () {
    testWidgets('Splash screen shows app name and navigates to login',
        (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.splash));
      await tester.pump();

      // Verify splash screen content
      expect(find.text('Ayo Tani'), findsOneWidget);
      expect(find.byIcon(Icons.agriculture), findsOneWidget);

      // Wait for splash to auto-navigate (2 seconds + settle)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should navigate to login (since no user is authenticated)
      expect(find.text('Login'), findsNWidgets(2));
    });

    testWidgets('Login page shows all required elements', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Verify login page UI elements
      expect(find.text('Login'), findsNWidgets(2));
      expect(find.byType(TextField), findsNWidgets(2)); // email + password
      expect(find.text('Lupa Password?'), findsOneWidget);
      expect(find.text('Belum punya akun?'), findsOneWidget);
      expect(find.text('Atau lanjut dengan'), findsOneWidget);
    });

    testWidgets('Login shows validation error for empty fields',
        (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Tap login without entering anything
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(
        find.text('Email dan password tidak boleh kosong'),
        findsOneWidget,
      );
    });

    testWidgets('Login shows error for invalid email format', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Enter invalid email
      await tester.enterText(find.byType(TextField).first, 'notanemail');
      await tester.enterText(find.byType(TextField).last, 'password123');

      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('Login shows error for short password', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, '123');

      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
    });

    testWidgets('Navigate from login to signup page', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Tap "Belum punya akun?"
      await tester.tap(find.text('Belum punya akun?'));
      await tester.pumpAndSettle();

      // Should be on signup page
      expect(find.text('Daftar dulu gasih?'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(4)); // username, email, pass, confirm
    });

    testWidgets('Signup page validates empty fields', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.signup));
      await tester.pumpAndSettle();

      // Tap register without filling anything
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Semua field harus diisi'), findsOneWidget);
    });

    testWidgets('Signup validates password mismatch', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.signup));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'testuser'); // username
      await tester.enterText(textFields.at(1), 'test@example.com'); // email
      await tester.enterText(textFields.at(2), 'password123'); // password
      await tester.enterText(textFields.at(3), 'differentpass'); // confirm

      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Password tidak cocok'), findsOneWidget);
    });

    testWidgets('Signup validates terms not agreed', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.signup));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'testuser');
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password123');

      // Don't check the terms checkbox
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui Syarat dan Ketentuan'), findsOneWidget);
    });

    testWidgets('Navigate from signup back to login', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.signup));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sudah punya akun?'));
      await tester.pumpAndSettle();

      // Should be back on login page
      expect(find.text('Login'), findsNWidgets(2));
    });

    testWidgets('Password visibility toggle works on login', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Password field should be obscured by default
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Should now show visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  // ============================================================
  // HOME SCREEN E2E TESTS
  // ============================================================
  group('E2E: Home Screen', () {
    testWidgets('Home screen shows bottom navigation bar', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify bottom nav items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Plant'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Bottom nav switches between tabs', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap Shop tab
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();

      // Tap Plant tab
      await tester.tap(find.text('Plant'));
      await tester.pumpAndSettle();

      // Tap Profil tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
    });
  });

  // ============================================================
  // MARKETPLACE E2E TESTS
  // ============================================================
  group('E2E: Marketplace Flow', () {
    testWidgets('Marketplace screen loads', (tester) async {
      await tester
          .pumpWidget(const TestApp(initialRoute: AppRoutes.marketplace));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Marketplace should render without crashing
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Cart screen is accessible', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.cart));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  // ============================================================
  // EDUCATION E2E TESTS
  // ============================================================
  group('E2E: Educational Content', () {
    testWidgets('Educational list screen loads', (tester) async {
      await tester
          .pumpWidget(const TestApp(initialRoute: AppRoutes.educational));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  // ============================================================
  // PROFILE E2E TESTS
  // ============================================================
  group('E2E: Profile', () {
    testWidgets('Profile page loads', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.profile));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  // ============================================================
  // MONITORING E2E TESTS
  // ============================================================
  group('E2E: Monitoring & Land Management', () {
    testWidgets('Land list screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.landList));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Add land screen loads', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.addLand));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
