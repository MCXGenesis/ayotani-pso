import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/educational_content_model.dart';
import '../../services/educational_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';

class ArticleListScreen extends StatefulWidget {
  ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final _educationalService = EducationalService();
  List<EducationalContent> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    final articles = await _educationalService.getArticles();
    if (mounted) {
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Artikel Pertanian', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: context.scaffoldBg,
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : _articles.isEmpty 
              ? Center(child: Text("Belum ada artikel.", style: GoogleFonts.inter()))
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) {
                    return _ArticleCardItem(article: _articles[index]);
                  },
                ),
    );
  }
}

class _ArticleCardItem extends StatelessWidget {
  final EducationalContent article;
  const _ArticleCardItem({required this.article});

  @override
  Widget build(BuildContext context) {
    final date = article.publishedAt != null 
        ? DateFormat('dd MMM yyyy').format(article.publishedAt!) 
        : 'Just now';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context, 
          AppRoutes.newsArticle, 
          arguments: {'articleId': article.id} // Pass ID
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: article.thumbnailUrl ?? 'https://via.placeholder.com/600x300',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 180, color: context.dividerColor),
                errorWidget: (context, url, error) => Container(height: 180, color: context.dividerColor, child: Icon(Icons.broken_image)),
              ),
            ),
            
            // Info Content
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4)),
                        child: Text(article.difficulty.name.toUpperCase(), style: TextStyle(fontSize: 10, color: Color(0xFF0A3D2F), fontWeight: FontWeight.bold)),
                      ),
                      Text(date, style: TextStyle(fontSize: 11, color: context.bgGrey)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    article.title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    article.description,
                    style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: context.bgGrey,
                        child: Icon(Icons.person, size: 12, color: context.cardBg),
                      ),
                      SizedBox(width: 6),
                      Text(article.author ?? 'Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Spacer(),
                      Icon(Icons.bookmark_border, size: 20, color: context.bgGrey),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}