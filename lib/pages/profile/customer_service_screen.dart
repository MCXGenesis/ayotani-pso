import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class CustomerServiceScreen extends StatelessWidget {
  CustomerServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Layanan Pelanggan', style: GoogleFonts.inter(color: context.textPrimary)),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Kontak Support ---
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                // PERBAIKAN: Menggunakan withValues agar tidak deprecated
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: context.primaryColor, size: 30),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Butuh bantuan mendesak?",
                          style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "support@ayotani.com",
                          style: GoogleFonts.inter(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // --- FAQ Section ---
            Text(
              "FAQ (Tanya Jawab)",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // PERBAIKAN: Menambahkan parameter context
            _buildFAQItem(
              context,
              "Bagaimana cara mengganti password?",
              "Buka menu Pengaturan > Ganti Password. Masukkan password baru Anda dan konfirmasi.",
            ),
            _buildFAQItem(
              context,
              "Apakah data lahan saya aman?",
              "Ya, data lahan Anda disimpan secara terenkripsi di server kami dan hanya bisa diakses oleh akun Anda.",
            ),
            _buildFAQItem(
              context,
              "Bagaimana cara menghubungi ahli tani?",
              "Fitur konsultasi ahli sedang dalam pengembangan. Pantau terus notifikasi untuk update terbaru!",
            ),
            _buildFAQItem(
              context,
              "Saya lupa email akun saya, bagaimana?",
              "Silakan hubungi support@ayotani.com dengan menyertakan nama lengkap dan nomor HP yang terdaftar.",
            ),
          ],
        ),
      ),
    );
  }

  // PERBAIKAN: Menerima BuildContext untuk mengakses Theme
  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.dividerColor),
      ),
      // PERBAIKAN UTAMA: Menggunakan Theme.of(context) menggantikan Theme.of(null!)
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}