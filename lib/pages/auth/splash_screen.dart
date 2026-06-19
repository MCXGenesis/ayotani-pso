import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 80,
              color: context.scaffoldBg,
            ),
            SizedBox(height: 24),
            Text(
              'Ayo Tani',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: context.scaffoldBg,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                context.scaffoldBg.withOpacity(0.7),
              ),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}