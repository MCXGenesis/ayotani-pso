import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/educational_content_model.dart';
import '../../services/educational_service.dart';
import '../../theme/app_colors.dart';

class EducationalDetailScreen extends StatefulWidget {
  final int contentId;

  const EducationalDetailScreen({super.key, required this.contentId});

  @override
  State<EducationalDetailScreen> createState() => _EducationalDetailScreenState();
}

class _EducationalDetailScreenState extends State<EducationalDetailScreen> {
  final _service = EducationalService();

  EducationalContent? _content;
  YoutubePlayerController? _yt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await _service.getContentById(widget.contentId);

    if (!mounted) return;

    _content = content;

    final url = content?.videoUrl ?? '';
    final videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId != null) {
      _yt = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _yt?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    if (_content == null) {
      return const Scaffold(
        body: Center(child: Text('Konten tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Video Belajar', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Player / Fallback
          if (_yt != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: YoutubePlayer(controller: _yt!),
            )
          else
            Container(
              height: 210,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('Video URL bukan YouTube / invalid'),
              ),
            ),

          const SizedBox(height: 16),

          Text(
            _content!.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _content!.description,
            style: TextStyle(color: Colors.grey[800], height: 1.5),
          ),
        ],
      ),
    );
  }
}
