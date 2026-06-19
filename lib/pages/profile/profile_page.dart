import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Consumer<AuthProvider>(builder: (context, authProvider, _) {
      final user = authProvider.userProfile;
      final name = user?.username ?? 'Petani';
      final avatarUrl = user?.avatarUrl;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                
                // --- HEADER: Avatar & Nama ---
                Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: theme.brightness == Brightness.dark ? context.textPrimary : context.dividerColor,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Icon(Icons.person, size: 35, color: context.textMuted)
                          : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40),

                // --- SECTION: Settings ---
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                SizedBox(height: 20),

                // --- MENU LIST (Fungsional) ---
                _buildMenuItem(
                  context,
                  title: 'Profil Saya',
                  icon: Icons.person,
                  iconColor: Color(0xFF4CAF50), // Hijau
                  bgColor: Color(0xFFE8F5E9),   // Hijau muda
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                _buildMenuItem(
                  context,
                  title: 'Ganti Password',
                  icon: Icons.lock_outline,
                  iconColor: Color(0xFF4CAF50),
                  bgColor: Color(0xFFE8F5E9),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                ),
                _buildMenuItem(
                  context,
                  title: 'Notifikasi',
                  icon: Icons.notifications_none,
                  iconColor: Color(0xFF4CAF50),
                  bgColor: Color(0xFFE8F5E9),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                ),
                _buildMenuItem(
                  context,
                  title: 'Syarat & Ketentuan',
                  icon: Icons.security,
                  iconColor: Color(0xFF4CAF50),
                  bgColor: Color(0xFFE8F5E9),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                ),
                _buildMenuItem(
                  context,
                  title: 'Layanan Pelanggan',
                  icon: Icons.chat_bubble_outline,
                  iconColor: Color(0xFF4CAF50),
                  bgColor: Color(0xFFE8F5E9),
                  onTap: () {
                     Navigator.pushNamed(context, AppRoutes.customerService);
                  },
                ),
                _buildMenuItem(
                  context,
                  title: 'Mode Gelap',
                  icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  iconColor: Color(0xFF4CAF50),
                  bgColor: Color(0xFFE8F5E9),
                  onTap: () {
                    themeProvider.toggleTheme(!themeProvider.isDarkMode);
                  },
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ),

                SizedBox(height: 30),

                // --- LOG OUT BUTTON ---
                InkWell(
                  onTap: () => _handleLogout(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFEBEE), // Merah muda
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.logout, color: Colors.red, size: 24),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Log Out',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Color(0xFF1B2C21) : bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            trailing ?? Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? context.textPrimary : context.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}