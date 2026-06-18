import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/auth_provider.dart';
import '../../models/land_model.dart';
import '../../models/educational_content_model.dart'; 
import '../../models/weather_model.dart';
import '../../services/educational_service.dart'; 
import '../../services/land_service.dart'; 
import '../../services/weather_service.dart';
import '../../routes/app_routes.dart';

import '../monitoring/land_list_screen.dart'; 
import '../marketplace/marketplace_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_page.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadUserProfile();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final profile = authProvider.userProfile;
          if (_selectedIndex == 0) {
            return _HomeContent(userProfile: profile);
          }
          return _getScreenForIndex(_selectedIndex);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0A3D2F),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), label: 'Plant'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 1: return const MarketplaceScreen();
      case 2: return const LandListScreen();
      case 3: return const CommunityScreen();
      case 4: return const ProfilePage(); 
      default: return const SizedBox();
    }
  }
}

class _HomeContent extends StatefulWidget {
  final dynamic userProfile;
  const _HomeContent({required this.userProfile});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final _educationalService = EducationalService();
  final _landService = LandService();
  final _weatherService = WeatherService();

  BmkgWeatherData? _weatherData;
  bool _weatherLoading = true;
  List<Land> _lands = [];
  List<EducationalContent> _videos = [];
  List<EducationalContent> _articles = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile == null) {
      await authProvider.loadUserProfile();
    }
    final userId = authProvider.userProfile?.id;
    
    if (userId != null) {
      _lands = await _landService.getUserLands(userId);
    }

    // Fetch dari BMKG (non-blocking)
    _weatherService.getDefaultWeather().then((data) {
      if (mounted) {
        setState(() {
          _weatherData = data;
          _weatherLoading = false;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _weatherLoading = false);
    });

    final videos = await _educationalService.getVideos();
    final articles = await _educationalService.getArticles();

    if (mounted) {
      setState(() {
        _videos = videos.take(5).toList();
        _articles = articles.take(5).toList();
        _isLoading = false;
      });
    }
  }

  String _getThumbnail(EducationalContent content) {
    if (content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty) {
      return content.thumbnailUrl!;
    }
    return 'https://via.placeholder.com/240x135';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userProfile?.username ?? 'Petani';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(name), 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildWeatherCard(),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Lahan Pertanian', () {
             Navigator.pushNamed(context, AppRoutes.landList);
          }),
          const SizedBox(height: 12),
          _buildLandList(),

          const SizedBox(height: 24),

          _buildSectionHeader('Video Belajar', () {
            Navigator.pushNamed(context, AppRoutes.educational);
          }),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 16),
          _buildVideoList(),

          const SizedBox(height: 24),

          _buildSectionHeader('Artikel Terbaru', () {
             Navigator.pushNamed(context, AppRoutes.articleList);
          }),
          const SizedBox(height: 12),
          _buildArticleList(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(String name) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200, 
          decoration: const BoxDecoration(
            color: Color(0xFF0A3D2F),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          backgroundImage: widget.userProfile?.avatarUrl != null ? NetworkImage(widget.userProfile.avatarUrl!) : null,
                          child: widget.userProfile?.avatarUrl == null ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, $name', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Mau belajar apa hari ini?', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 48,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Cari sesuatu...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    final current = _weatherData?.current;
    final temp = current != null ? '${current.temperature}' : '--';
    final desc = current?.weatherDesc ?? 'Memuat data...';
    final humidity = current?.humidity ?? 0;
    final windSpeed = current?.windSpeed.toStringAsFixed(1) ?? '--';
    final weatherIcon = current?.weatherIcon ?? '🌤️';
    final isRainy = current?.isRainy ?? false;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.weather),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isRainy
                ? [const Color(0xFF1A3A5C), const Color(0xFF2C5F8A)]
                : [const Color(0xFF1B6CA8), const Color(0xFF0A3D2F)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A3D2F).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _weatherLoading
            ? Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white54),
                  ),
                  const SizedBox(width: 12),
                  Text('Memuat data cuaca BMKG...',
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 13)),
                ],
              )
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(weatherIcon,
                              style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$temp°C',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0)),
                              Text(desc,
                                  style: GoogleFonts.inter(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('BMKG',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    color: Colors.white70, size: 12),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 14),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildWeatherStat(Icons.water_drop_outlined,
                          '$humidity%', 'Kelembapan'),
                      const SizedBox(width: 16),
                      _buildWeatherStat(Icons.air, '$windSpeed m/s', 'Angin'),
                      const Spacer(),
                      Text('Surabaya · Data BMKG',
                          style: GoogleFonts.inter(
                              color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text('$value ',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          GestureDetector(
            onTap: onSeeAll,
            child: Text('SEE ALL >', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0A3D2F), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLandList() {
    if (_isLoading) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
    if (_lands.isEmpty) return const SizedBox(height: 100, child: Center(child: Text("Belum ada lahan")));

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _lands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final land = _lands[index];
          final imageUrl = land.imageUrl ?? 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${land.longitude ?? 112.7},${land.latitude ?? -7.2},15,0/400x400?access_token=pk.eyJ1IjoiZGVtb3VzZXIiLCJhIjoiY2w4Z3M5bHMyMDJmMQN1b3h5b3MifQ.placeholder';
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.monitoring, arguments: {'landId': land.id}),
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
              ),
              child: Stack(
                children: [
                  Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                  Positioned(bottom: 12, left: 12, right: 12, child: Text(land.name, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() { return const SizedBox(); } 

  Widget _buildVideoList() {
    if (_videos.isEmpty) return const Center(child: Text("No videos"));
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final video = _videos[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.educationalDetail, arguments: {'id': video.id}),
            child: SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(imageUrl: _getThumbnail(video), height: 135, width: 240, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleList() {
    if (_articles.isEmpty) return const SizedBox();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _articles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final article = _articles[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.newsArticle,
                arguments: {'articleId': article.id},
              );
            },
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: _getThumbnail(article),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: Colors.grey[300], height: 120),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(article.difficulty.name, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                            const Icon(Icons.bookmark_border_rounded, size: 18, color: Colors.grey),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}