import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import '../../models/educational_content_model.dart';
import '../../services/educational_service.dart';
import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';

class EducationalListScreen extends StatefulWidget {
  EducationalListScreen({super.key});

  @override
  State<EducationalListScreen> createState() => _EducationalListScreenState();
}

class _EducationalListScreenState extends State<EducationalListScreen> {
  final _service = EducationalService();

  String _selected = 'All';
  Future<List<EducationalContent>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      // FIX: Use specific video methods instead of generic ones
      _future = _selected == 'All'
          ? _service.getVideos() 
          : _service.getVideosByDifficulty(_selected); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text('Video Belajar', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          _buildFilter(),
          SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<EducationalContent>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: context.primaryColor));
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(child: Text('Video belajar belum tersedia'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _VideoCard(
                      item: items[i],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.educationalDetail,
                          arguments: {'id': items[i].id},
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    final options = ['All', 'Beginner', 'Intermediate', 'Advanced'];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => SizedBox(width: 10),
        itemCount: options.length,
        itemBuilder: (_, i) {
          final v = options[i];
          final selected = _selected == v;
          return GestureDetector(
            onTap: () {
              _selected = v;
              _reload();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Color(0xFF0A3D2F) : Color(0xFFF1F3F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                v == 'All' ? 'All' : v,
                style: TextStyle(
                  color: selected ? context.cardBg : context.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final EducationalContent item;
  final VoidCallback onTap;

  const _VideoCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final difficultyText = _difficultyLabel(item.difficulty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dividerColor),
          // FIX: Replaced withOpacity with withValues for Flutter 3.27+
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                height: 110,
                width: double.infinity,
                color: context.dividerColor,
                child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                    ? Image.network(item.thumbnailUrl!, fit: BoxFit.cover)
                    : Center(child: Icon(Icons.play_circle_fill, size: 44, color: context.textSecondary)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // FIX: Replaced withOpacity with withValues
                      color: context.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      difficultyText,
                      style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w700, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(DifficultyLevel d) {
    switch (d) {
      case DifficultyLevel.beginner:
        return 'Pemula';
      case DifficultyLevel.intermediate:
        return 'Menengah';
      case DifficultyLevel.advanced:
        return 'Lanjut';
    }
  }
}