import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ayotani/providers/auth_provider.dart';
import 'package:ayotani/providers/cart_provider.dart';
import 'package:ayotani/routes/app_routes.dart';
import 'package:ayotani/theme/app_colors.dart';

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
