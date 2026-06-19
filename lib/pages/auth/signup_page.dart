import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/circle_social_button.dart';
import '../../widgets/round_check.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  final _authService = AuthService();

  bool _agree = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  OutlineInputBorder _border({Color color = AppColors.green}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1.2),
      );

  /// Validate email format
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  /// Validate password (minimum 6 characters)
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validate username (3-20 characters, alphanumeric + underscore)
  bool _isValidUsername(String username) {
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return regex.hasMatch(username);
  }

  /// Handle signup
  Future<void> _handleSignUp() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate all inputs
    if (_usernameC.text.isEmpty || _emailC.text.isEmpty || _passC.text.isEmpty || _confirmC.text.isEmpty) {
      setState(() => _errorMessage = 'Semua field harus diisi');
      return;
    }

    if (!_isValidUsername(_usernameC.text)) {
      setState(() => _errorMessage = 'Username 3-20 karakter, alphanumeric dan underscore');
      return;
    }

    if (!_isValidEmail(_emailC.text)) {
      setState(() => _errorMessage = 'Format email tidak valid');
      return;
    }

    if (!_isValidPassword(_passC.text)) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }

    if (_passC.text != _confirmC.text) {
      setState(() => _errorMessage = 'Password tidak cocok');
      return;
    }

    if (!_agree) {
      setState(() => _errorMessage = 'Setujui Syarat dan Ketentuan');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        email: _emailC.text.trim(),
        password: _passC.text,
        username: _usernameC.text.trim(),
      );

      if (mounted) {
        final session = response.session;
        final user = response.user;

        if (session != null && user != null) {
          // User is logged in (email confirmation is off or was auto-confirmed)
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else if (user != null) {
          // User signed up, but needs to confirm email
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registrasi berhasil! Silakan cek email untuk verifikasi.'),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        // Log the actual error to the console for debugging
        debugPrint('An unexpected error occurred during sign up: $e');
        debugPrint('Stack trace: $stackTrace');
        setState(() => _errorMessage = 'Gagal membuat profil pengguna. Silakan coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 30, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              Text(
                "Daftar dulu gasih?",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: context.textPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Masukkan Email dan Kata Sandi untuk membuat\nakun baru",
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: context.textPrimary.withOpacity(0.65),
                ),
              ),
              SizedBox(height: 22),

              // Error message display
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (_errorMessage != null) SizedBox(height: 16),

              // Username
              TextField(
                controller: _usernameC,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: TextStyle(color: context.textPrimary.withOpacity(0.35)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: _border(),
                  focusedBorder: _border(),
                  disabledBorder: _border(color: context.bgGrey),
                ),
              ),
              SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: TextStyle(color: context.textPrimary.withOpacity(0.35)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: _border(),
                  focusedBorder: _border(),
                  disabledBorder: _border(color: context.bgGrey),
                ),
              ),
              SizedBox(height: 16),

              // Password
              TextField(
                controller: _passC,
                obscureText: _obscure1,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Kata sandi",
                  hintStyle: TextStyle(color: context.textPrimary.withOpacity(0.35)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: _border(),
                  focusedBorder: _border(),
                  disabledBorder: _border(color: context.bgGrey),
                  suffixIcon: IconButton(
                    onPressed: !_isLoading ? () => setState(() => _obscure1 = !_obscure1) : null,
                    icon: Icon(
                      _obscure1 ? Icons.visibility_off : Icons.visibility,
                      color: context.textPrimary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: _confirmC,
                obscureText: _obscure2,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Verifikasi kata sandi",
                  hintStyle: TextStyle(color: context.textPrimary.withOpacity(0.35)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: _border(),
                  focusedBorder: _border(),
                  disabledBorder: _border(color: context.bgGrey),
                  suffixIcon: IconButton(
                    onPressed: !_isLoading ? () => setState(() => _obscure2 = !_obscure2) : null,
                    icon: Icon(
                      _obscure2 ? Icons.visibility_off : Icons.visibility,
                      color: context.textPrimary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              InkWell(
                onTap: !_isLoading ? () => setState(() => _agree = !_agree) : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      RoundCheck(checked: _agree, color: context.primaryColor),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Setuju dengan Syarat dan Ketentuan",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: context.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 36),

              Center(
                child: SizedBox(
                  width: 190,
                  height: 46,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      shape: StadiumBorder(),
                      textStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                      disabledBackgroundColor: context.bgGrey,
                    ),
                    onPressed: _isLoading ? null : _handleSignUp,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(context.scaffoldBg),
                            ),
                          )
                        : Text("Daftar"),
                  ),
                ),
              ),

              SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: !_isLoading
                      ? () {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      : null,
                  child: Text(
                    "Sudah punya akun?",
                    style: TextStyle(
                      fontSize: 13.8,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 44),

              Center(
                child: Text(
                  "Atau lanjut dengan",
                  style: TextStyle(fontSize: 13.5, color: context.textPrimary.withOpacity(0.6)),
                ),
              ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleSocialButton(
                    onTap: !_isLoading
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Google Sign-In akan segera tersedia'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : () {},
                    child: SvgPicture.asset("assets/icons/google.svg", width: 22, height: 22),
                  ),
                  SizedBox(width: 18),
                  CircleSocialButton(
                    onTap: !_isLoading
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Apple Sign-In akan segera tersedia'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : () {},
                    child: SvgPicture.asset(
                      "assets/icons/apple.svg",
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
