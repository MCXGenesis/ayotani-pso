import 'package:flutter/material.dart';
import 'package:ayotani/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/land_model.dart';
import '../../services/land_service.dart';
import '../../services/weather_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class LandListScreen extends StatefulWidget {
  LandListScreen({super.key});

  @override
  State<LandListScreen> createState() => _LandListScreenState();
}

class _LandListScreenState extends State<LandListScreen> {
  final _landService = LandService();
  List<Land> _lands = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLands();
  }

  Future<void> _fetchLands() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userProfile?.id;
    if (userId != null) {
      final lands = await _landService.getUserLands(userId);
      if (mounted) setState(() => _lands = lands);
    } else {
      // Demo mode
      if (mounted) setState(() => _lands = [_landService.getDemoLand()]);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lahan Pertanian Saya', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
               // Use a named route or push directly to add land
               // For now we just refresh after return
               Navigator.pushNamed(context, '/add-land').then((_) => _fetchLands()); 
            },
          )
        ],
      ),
      backgroundColor: context.scaffoldBg,
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: context.primaryColor))
          : _lands.isEmpty 
              ? Center(child: Text("Belum ada lahan.", style: GoogleFonts.inter()))
              : ListView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  itemCount: _lands.length,
                  itemBuilder: (context, index) {
                    return _LandCardItem(land: _lands[index]);
                  },
                ),
    );
  }
}

class _LandCardItem extends StatefulWidget {
  final Land land;
  const _LandCardItem({required this.land});

  @override
  State<_LandCardItem> createState() => _LandCardItemState();
}

class _LandCardItemState extends State<_LandCardItem> {
  final _weatherService = WeatherService();
  Map<String, dynamic>? _weather;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  void _fetchWeather() async {
    if (widget.land.latitude != null && widget.land.longitude != null) {
      final data = await _weatherService.getCurrentWeather(widget.land.latitude!, widget.land.longitude!);
      if (mounted) setState(() => _weather = data?['current'] ?? data?['current_weather']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final land = widget.land;
    
    // Financial Calc
    final totalModal = land.modalPerKg * land.targetHarvestKg;
    final profitPct = land.targetProfitPercentage;
    final estProfit = totalModal * (profitPct / 100);
    
    final temp = _weather?['temperature_2m'] ?? _weather?['temperature'] ?? '-';

    return GestureDetector(
      onTap: () {
        // Navigate to Monitoring Screen with specific ID
        Navigator.pushNamed(
          context, 
          AppRoutes.monitoring, 
          arguments: {'landId': land.id}
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
            // 1. Thumbnail (Map Snapshot)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${land.longitude ?? 112.7},${land.latitude ?? -7.2},15,0/600x300?access_token=pk.eyJ1IjoiZGVtb3VzZXIiLCJhIjoiY2w4Z3M5bHMyMDJmMQN1b3h5b3MifQ.placeholder',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(height: 180, color: context.dividerColor),
                    errorWidget: (context, url, error) => Container(height: 180, color: context.dividerColor, child: Icon(Icons.broken_image)),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                      child: Text('${land.areaSize} Ha', style: TextStyle(color: context.cardBg, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: context.cardBg.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.wb_sunny, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('$temp°C', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            // 2. Info Content
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Icon
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.agriculture, color: Color(0xFF0A3D2F), size: 20),
                  ),
                  SizedBox(width: 12),
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          land.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          land.location ?? 'Lokasi tidak diketahui',
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        // Financial Summary Row
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.dividerColor)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMiniStat('Target', '${land.targetHarvestKg.toStringAsFixed(0)} Kg'),
                              _buildMiniStat('Modal', _formatCurrency(totalModal)),
                              _buildMiniStat('Est. Profit', _formatCurrency(estProfit), color: Colors.green),
                            ],
                          ),
                        )
                      ],
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

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? context.textPrimary)),
      ],
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) return '${(val/1000000).toStringAsFixed(1)}Jt';
    if (val >= 1000) return '${(val/1000).toStringAsFixed(0)}rb';
    return val.toStringAsFixed(0);
  }
}