import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ayotani/routes/app_routes.dart';
import 'package:ayotani/pages/auth/signup_page.dart';

import 'helpers/test_app.dart';

/// Dedicated E2E tests for the complete authentication user journey.
/// Tests the login → signup → validation → navigation flows.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: 'https://placeholder.supabase.co',
    anonKey: 'placeholder_key',
  );

  group('E2E: Full Auth User Journey', () {
    testWidgets('Complete signup validation flow', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.signup));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      // Step 1: Try with invalid username (too short)
      await tester.enterText(textFields.at(0), 'ab'); // too short
      await tester.enterText(textFields.at(1), 'test@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Username 3-20 karakter, alphanumeric dan underscore'),
        findsOneWidget,
      );

      // Step 2: Fix username, try invalid email
      await tester.enterText(textFields.at(0), 'validuser');
      await tester.enterText(textFields.at(1), 'not-an-email');
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);

      // Step 3: Fix email, try short password
      tester.widget<TextField>(textFields.at(1)).controller?.text = 'valid@email.com';
      tester.widget<TextField>(textFields.at(2)).controller?.text = '123';
      tester.widget<TextField>(textFields.at(3)).controller?.text = '123';
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Password minimal 6 karakter'), findsOneWidget);

      // Step 4: Fix password, mismatch confirm
      tester.widget<TextField>(textFields.at(2)).controller?.text = 'password123';
      tester.widget<TextField>(textFields.at(3)).controller?.text = 'different456';
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Password tidak cocok'), findsOneWidget);

      // Step 5: Fix confirm, but don't agree to terms
      tester.widget<TextField>(textFields.at(3)).controller?.text = 'password123';
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui Syarat dan Ketentuan'), findsOneWidget);
    });

    testWidgets('Login form interaction flow', (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'user@test.com');
      await tester.enterText(find.byType(TextField).last, 'mypassword');

      // Toggle password visibility
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Toggle back
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Toggle "remember me"
      await tester.tap(find.text('Ingatkan saya'));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation between login and signup preserves context',
        (tester) async {
      await tester.pumpWidget(const TestApp(initialRoute: AppRoutes.login));
      await tester.pumpAndSettle();

      // Go to signup
      await tester.tap(find.text('Belum punya akun?'));
      await tester.pumpAndSettle();
      expect(find.text('Daftar dulu gasih?'), findsOneWidget);

      // Go back to login
      await tester.tap(find.text('Sudah punya akun?'));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsNWidgets(2));
    });
  });
}
