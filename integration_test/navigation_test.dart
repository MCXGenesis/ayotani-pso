import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ayotani/routes/app_routes.dart';

import 'helpers/test_app.dart';

/// E2E tests for app navigation and screen transitions.
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
        return;
      }
      originalOnError?.call(details);
    };
  });

  group('E2E: Screen Navigation', () {
    testWidgets('All main screens load without crashes', (tester) async {
      // Test each major screen can be rendered independently
      final routes = [
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.home,
        AppRoutes.marketplace,
        AppRoutes.cart,
        AppRoutes.educational,
        AppRoutes.profile,
        AppRoutes.landList,
        AppRoutes.addLand,
        AppRoutes.articleList,
      ];

      for (final route in routes) {
        await tester.pumpWidget(TestApp(initialRoute: route));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Each screen should render at least one Scaffold
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: 'Route "$route" failed to render a Scaffold',
        );
      }
    });

    testWidgets('Home bottom nav has correct number of items',
        (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should have 5 bottom nav items
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.items.length, 5);
    });

    testWidgets('Home bottom nav tab switching works', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.home));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap each tab and verify no crash
      final tabs = ['Home', 'Shop', 'Plant', 'Community', 'Profil'];

      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Should still show bottom nav (app didn't crash)
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      }
    });

    testWidgets('Checkout flow screens are accessible', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.checkout));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Payment done screen loads', (tester) async {
      await tester
          .pumpWidget(const TestApp(initialRoute: AppRoutes.paymentDone));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Profile sub-screens load', (tester) async {
      // Edit profile
      await tester
          .pumpWidget(const TestApp(initialRoute: AppRoutes.editProfile));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);

      // Change password
      await tester
          .pumpWidget(const TestApp(initialRoute: AppRoutes.changePassword));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);

      // Notifications
      await tester
          .pumpWidget(const TestApp(initialRoute: AppRoutes.notifications));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);

      // Terms
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.terms));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
