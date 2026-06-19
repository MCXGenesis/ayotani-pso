import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ambil data user
    final userProfile = Provider.of<AuthProvider>(context, listen: false).userProfile;
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    _nameController.text = userProfile?.username ?? '';
    _emailController.text = currentUser?.email ?? '';
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final newEmail = _emailController.text.trim();

      // Hanya update Email karena Nama & Gambar di-lock (read-only)
      if (newEmail.isNotEmpty && newEmail != supabase.auth.currentUser?.email) {
        await supabase.auth.updateUser(UserAttributes(email: newEmail));
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email diperbarui! Cek inbox email baru Anda untuk konfirmasi.')),
          );
           Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak ada perubahan yang disimpan.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil URL avatar untuk ditampilkan
    final userProfile = Provider.of<AuthProvider>(context).userProfile;
    final avatarUrl = userProfile?.avatarUrl;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Profil Saya', style: GoogleFonts.inter(color: context.textPrimary)),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- 1. Tampilan Gambar (Read Only) ---
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: context.dividerColor,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(Icons.person, size: 50, color: context.textMuted)
                    : null,
              ),
            ),
            SizedBox(height: 30),

            // --- 2. Nama (Read Only / Locked) ---
            _buildTextField(
              "Nama Lengkap", 
              _nameController, 
              Icons.person, 
              isReadOnly: true // Dikunci
            ),
            SizedBox(height: 20),

            // --- 3. Email (Bisa Diedit) ---
            _buildTextField(
              "Email", 
              _emailController, 
              Icons.email,
              isReadOnly: false // Bisa diubah
            ),
            
            SizedBox(height: 40),

            // --- 4. Tombol Simpan ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: context.scaffoldBg)
                    : Text("Simpan Perubahan Email", style: GoogleFonts.inter(color: context.scaffoldBg, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {required bool isReadOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly, // Kunci field jika readOnly true
          style: TextStyle(color: isReadOnly ? context.textSecondary : context.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isReadOnly ? context.textMuted : context.textSecondary),
            filled: isReadOnly,
            fillColor: isReadOnly ? context.dividerColor : Colors.white, // Warna abu jika dikunci
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isReadOnly ? Colors.transparent : context.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isReadOnly ? Colors.transparent : context.primaryColor, width: 2),
            ),
          ),
        ),
        if (isReadOnly)
          Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              "*Nama tidak dapat diubah.",
              style: GoogleFonts.inter(fontSize: 10, color: context.textMuted, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}