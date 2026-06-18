import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'theme/app_colors.dart';
import 'providers/theme_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Dark theme optimized to be easy on the eyes (using deep forest/slate tones)
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0E1410), // Ultra-dark forest background, very gentle on the eyes
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        brightness: Brightness.dark,
        primary: const Color(0xFF81C784), // Soft mint green
        secondary: const Color(0xFF4DB6AC), // Soft teal
        surface: const Color(0xFF18221B), // Muted dark surface for cards
        onSurface: const Color(0xFFE0E8E3), // Off-white/mint text to reduce glare
        onPrimary: const Color(0xFF0C3315),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A382E),
      ),
      fontFamily: 'Inter',
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ayo Tani',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      darkTheme: darkTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}