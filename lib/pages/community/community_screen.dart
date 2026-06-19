import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import '../../theme/app_colors.dart';

class CommunityScreen extends StatelessWidget {
  CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.dividerColor,
      appBar: AppBar(
        title: Text(
          'Komunitas Tani', 
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)
        ),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: context.primaryColor),
                ),
                SizedBox(width: 12),
                Text(
                  "Apa yang anda tanam hari ini?", 
                  style: TextStyle(color: context.bgGrey, fontSize: 14)
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Diskusi Terbaru",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildPostItem(
            context,
            name: "Budi Santoso",
            role: "Petani Cabai",
            time: "2 jam yang lalu",
            content: "Alhamdulillah panen cabai hari ini melimpah! Harga di pasar juga sedang bagus.",
            likes: 24,
            comments: 5,
          ),
          _buildPostItem(
            context,
            name: "Siti Aminah",
            role: "Pemula",
            time: "5 jam yang lalu",
            content: "Ada yang tau cara mengatasi daun menguning pada tanaman tomat?",
            likes: 12,
            comments: 8,
            hasImage: true, 
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(
    BuildContext context, {
    required String name,
    required String role,
    required String time,
    required String content,
    required int likes,
    required int comments,
    bool hasImage = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8, 
            offset: Offset(0, 2)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.dividerColor,
                child: Text(name[0], style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("$role • $time", style: TextStyle(fontSize: 12, color: context.bgGrey)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(content, style: TextStyle(height: 1.5)),
          if (hasImage) ...[
            SizedBox(height: 12),
            Container(
              height: 150, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(Icons.image, size: 50, color: Colors.green),
              ),
            ),
          ],
          SizedBox(height: 16),
          Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(onPressed: () {}, icon: Icon(Icons.thumb_up_outlined, size: 18), label: Text("$likes")),
              TextButton.icon(onPressed: () {}, icon: Icon(Icons.comment_outlined, size: 18), label: Text("$comments")),
            ],
          ),
        ],
      ),
    );
  }
}