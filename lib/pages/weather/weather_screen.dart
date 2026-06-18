import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;

  const WeatherScreen({super.key, this.initialLat, this.initialLon});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();

  BmkgWeatherData? _weatherData;
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedCity = 'Surabaya';
  bool _isLocating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    if (widget.initialLat != null && widget.initialLon != null) {
      _selectedCity = WeatherService.getNearestCity(
        widget.initialLat!,
        widget.initialLon!,
      );
    }

    _fetchWeather();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _fadeController.reset();
    _slideController.reset();

    final data = await _weatherService.getWeatherByCity(_selectedCity);

    if (!mounted) return;
    setState(() {
      _weatherData = data;
      _isLoading = false;
      _hasError = data == null;
    });
    if (data != null) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  Future<void> _detectMyLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackbar('Layanan lokasi tidak aktif.', isError: true);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showSnackbar('Izin lokasi ditolak.', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackbar('Izin lokasi diblokir permanen. Buka Pengaturan.', isError: true);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final nearest = WeatherService.getNearestCity(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() => _selectedCity = nearest);
        _showSnackbar('Lokasi terdeteksi: $nearest', isError: false);
        _fetchWeather();
      }
    } catch (e) {
      if (mounted) _showSnackbar('Gagal mendeteksi lokasi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnackbar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1B9E77),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Color _getBgGradientTop(BmkgWeatherEntry? entry) {
    if (entry == null) return const Color(0xFF0A2E1A);
    if (entry.isRainy) return const Color(0xFF0D1B3E);
    if (entry.weatherCode == 0) return const Color(0xFF0C3B6E);
    if (entry.weatherCode <= 2) return const Color(0xFF134A8E);
    return const Color(0xFF1A2744);
  }

  Color _getBgGradientBottom(BmkgWeatherEntry? entry) {
    if (entry == null) return const Color(0xFF0E5234);
    if (entry.isRainy) return const Color(0xFF1B3A60);
    if (entry.weatherCode == 0) return const Color(0xFF1565C0);
    if (entry.weatherCode <= 2) return const Color(0xFF1976D2);
    return const Color(0xFF263570);
  }

  Color _getAccentColor(BmkgWeatherEntry? entry) {
    if (entry == null) return const Color(0xFF4CAF50);
    if (entry.isRainy) return const Color(0xFF64B5F6);
    if (entry.weatherCode == 0) return const Color(0xFFFFCA28);
    return const Color(0xFF81D4FA);
  }

  @override
  Widget build(BuildContext context) {
    final current = _weatherData?.current;
    final bgTop = _getBgGradientTop(current);
    final bgBottom = _getBgGradientBottom(current);
    final accent = _getAccentColor(current);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom, const Color(0xFF0A1628)],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles in background
            _buildBgDecorations(accent),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  if (_isLoading)
                    const Expanded(child: Center(child: _WeatherLoadingIndicator()))
                  else if (_hasError)
                    Expanded(child: _buildErrorState())
                  else
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              children: [
                                _buildCurrentWeather(accent),
                                const SizedBox(height: 12),
                                _buildWeatherDetails(accent),
                                const SizedBox(height: 20),
                                _buildHourlyForecast(accent),
                                const SizedBox(height: 20),
                                _buildDailyForecast(),
                                const SizedBox(height: 20),
                                _buildAgriculturalTips(accent),
                                const SizedBox(height: 20),
                                _buildBmkgAttribution(),
                              ],
                            ),
                          ),
                        ),
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

  // ─────────────────────────────────────────────────────────────
  // BACKGROUND DECORATION
  // ─────────────────────────────────────────────────────────────
  Widget _buildBgDecorations(Color accent) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _glassButton(
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 17),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prediksi Cuaca',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Sumber: BMKG Indonesia',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          // GPS location button
          if (_isLocating)
            _glassButton(
              child: const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              onTap: null,
            )
          else
            _glassButton(
              child: const Icon(Icons.my_location, color: Colors.white, size: 17),
              onTap: _detectMyLocation,
              tooltip: 'Gunakan Lokasi Saya',
            ),
          const SizedBox(width: 8),
          // City picker
          GestureDetector(
            onTap: _showCityPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(_selectedCity,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 15),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _glassButton(
            child: const Icon(Icons.refresh, color: Colors.white, size: 17),
            onTap: _fetchWeather,
          ),
        ],
      ),
    );
  }

  Widget _glassButton({required Widget child, required VoidCallback? onTap, String? tooltip}) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip, child: btn);
    return btn;
  }

  // ─────────────────────────────────────────────────────────────
  // CURRENT WEATHER – hero section
  // ─────────────────────────────────────────────────────────────
  Widget _buildCurrentWeather(Color accent) {
    final current = _weatherData!.current;
    final location = _weatherData!.location;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dateStr = '${days[now.weekday % 7]}, ${now.day} ${months[now.month]}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Date & time badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 12),
                    const SizedBox(width: 6),
                    Text(dateStr,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(timeStr,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Location tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: accent, size: 15),
              const SizedBox(width: 3),
              Text(
                '${location.kecamatan}, ${location.kotkab}',
                style: GoogleFonts.inter(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Big weather icon with pulse
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  current.weatherIcon,
                  style: const TextStyle(fontSize: 60),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Temperature
          Text(
            '${current.temperature}°',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 86,
              fontWeight: FontWeight.w100,
              height: 1.0,
            ),
          ),

          Text(
            'C',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),

          const SizedBox(height: 12),

          // Condition pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Text(
              current.weatherDesc,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Prediksi: ${_formatLocalDatetime(current.localDatetime)}',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WEATHER DETAILS – 4 metric cards
  // ─────────────────────────────────────────────────────────────
  Widget _buildWeatherDetails(Color accent) {
    final current = _weatherData!.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _metricCard(
            icon: Icons.water_drop_outlined,
            value: '${current.humidity}%',
            label: 'Kelembapan',
            accent: accent,
          ),
          const SizedBox(width: 10),
          _metricCard(
            icon: Icons.air,
            value: '${current.windSpeed.toStringAsFixed(1)}',
            unit: 'm/s',
            label: 'Angin ${current.windDirection}',
            accent: accent,
          ),
          const SizedBox(width: 10),
          _metricCard(
            icon: Icons.umbrella_outlined,
            value: '${current.precipitation}',
            unit: 'mm',
            label: 'Curah Hujan',
            accent: accent,
          ),
          const SizedBox(width: 10),
          _metricCard(
            icon: Icons.visibility_outlined,
            value: current.visibilityText,
            label: 'Visibilitas',
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String value,
    String? unit,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: unit,
                      style: GoogleFonts.inter(
                          color: Colors.white60, fontSize: 9),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HOURLY FORECAST
  // ─────────────────────────────────────────────────────────────
  Widget _buildHourlyForecast(Color accent) {
    final hourlyEntries = _weatherData!.getHourlyForecast24h();
    if (hourlyEntries.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('☀️ Prediksi Cuaca Per Jam'),
        const SizedBox(height: 10),
        SizedBox(
          height: 142,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: hourlyEntries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final entry = hourlyEntries[i];
              final entryTime = entry.localTime;
              final now = DateTime.now();
              final isNow = entryTime.hour == now.hour && entryTime.day == now.day;
              final isToday = entryTime.year == now.year &&
                  entryTime.month == now.month &&
                  entryTime.day == now.day;

              final String timeLabel;
              if (isNow) {
                timeLabel = 'Sekarang';
              } else if (isToday) {
                timeLabel = entry.timeFormatted;
              } else {
                timeLabel = '${entry.dayName}\n${entry.timeFormatted}';
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  gradient: isNow
                      ? LinearGradient(
                          colors: [
                            accent.withOpacity(0.5),
                            accent.withOpacity(0.2)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isNow ? null : Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isNow ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.12),
                    width: isNow ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      timeLabel,
                      style: GoogleFonts.inter(
                          color: isNow ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: isNow ? FontWeight.bold : FontWeight.normal),
                      textAlign: TextAlign.center,
                    ),
                    Text(entry.weatherIcon, style: const TextStyle(fontSize: 22)),
                    Text(
                      '${entry.temperature}°',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      entry.weatherDesc,
                      style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.humidity > 0)
                      Text(
                        '💧${entry.humidity}%',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 9),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY FORECAST
  // ─────────────────────────────────────────────────────────────
  Widget _buildDailyForecast() {
    final days = _weatherData!.dailyForecasts;
    if (days.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitleSmall('📅 Prediksi 3 Hari ke Depan'),
            const SizedBox(height: 14),
            ...days.take(3).toList().asMap().entries.map((e) {
              final isLast = e.key == math.min(days.length, 3) - 1;
              return Column(
                children: [
                  _buildDayRow(e.value),
                  if (!isLast) Divider(color: Colors.white.withOpacity(0.1), height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(BmkgDayForecast day) {
    final rep = day.representative;
    final isToday = _isSameDay(day.date, DateTime.now());
    const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Hari ini' : dayNames[day.date.weekday % 7],
                  style: GoogleFonts.inter(
                      color: isToday ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
                ),
                if (!isToday)
                  Text(
                    '${day.date.day}/${day.date.month}',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                  ),
              ],
            ),
          ),
          Text(rep.weatherIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rep.weatherDesc,
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
          ),
          Text('${day.minTemp}°',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          const SizedBox(width: 6),
          _buildTempBar(day.minTemp, day.maxTemp),
          const SizedBox(width: 6),
          Text('${day.maxTemp}°',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTempBar(int min, int max) {
    return Container(
      width: 55,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFFFFCA28), Color(0xFFFF7043)],
          stops: [0, 0.5, 1],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AGRICULTURAL TIPS
  // ─────────────────────────────────────────────────────────────
  Widget _buildAgriculturalTips(Color accent) {
    final current = _weatherData!.current;
    final tips = _getAgriculturalTips(current);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitleSmall('🌾 Rekomendasi Pertanian'),
            const SizedBox(height: 14),
            ...tips.asMap().entries.map((entry) {
              final tip = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip['icon']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['title']!,
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(tip['desc']!,
                              style: GoogleFonts.inter(
                                  color: Colors.white60, fontSize: 11, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getAgriculturalTips(BmkgWeatherEntry entry) {
    final tips = <Map<String, String>>[];

    if (entry.isRainy) {
      tips.addAll([
        {
          'icon': '🚫',
          'title': 'Tunda Penyiraman',
          'desc': 'Hujan cukup untuk kebutuhan air tanaman hari ini.',
        },
        {
          'icon': '🌿',
          'title': 'Waspadai Penyakit Tanaman',
          'desc': 'Kelembapan tinggi meningkatkan risiko jamur & bakteri.',
        },
        {
          'icon': '💧',
          'title': 'Periksa Drainase',
          'desc': 'Pastikan saluran air lahan tidak tersumbat.',
        },
      ]);
    } else if (entry.weatherCode == 0) {
      tips.addAll([
        {
          'icon': '✅',
          'title': 'Waktu Ideal Bertani',
          'desc': 'Cuaca cerah, cocok untuk semua aktivitas di ladang.',
        },
        {
          'icon': '💧',
          'title': 'Siram Pagi & Sore',
          'desc': 'Suhu ${entry.temperature}°C – siram rutin untuk cegah kekeringan.',
        },
        {
          'icon': '🌻',
          'title': 'Fotosintesis Optimal',
          'desc': 'Cahaya matahari penuh mendukung pertumbuhan tanaman.',
        },
      ]);
    } else {
      tips.addAll([
        {
          'icon': '🌤️',
          'title': 'Cuaca Moderat',
          'desc': 'Kondisi baik untuk pemupukan dan perawatan tanaman.',
        },
        {
          'icon': '💧',
          'title': 'Pantau Kebutuhan Air',
          'desc': 'Kelembapan ${entry.humidity}% – sesuaikan jadwal penyiraman.',
        },
      ]);
    }

    if (entry.windSpeed > 10) {
      tips.add({
        'icon': '💨',
        'title': 'Angin Kencang',
        'desc': 'Kecepatan ${entry.windSpeed} m/s – pasang penyangga tanaman jika perlu.',
      });
    }

    return tips;
  }

  // ─────────────────────────────────────────────────────────────
  // BMKG ATTRIBUTION
  // ─────────────────────────────────────────────────────────────
  Widget _buildBmkgAttribution() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white38, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data prediksi bersumber dari BMKG (Badan Meteorologi, Klimatologi, dan Geofisika) Indonesia · bmkg.go.id',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ERROR STATE
  // ─────────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text('🌩️', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Gagal Mengambil Data Cuaca',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet Anda dan coba lagi.',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _fetchWeather,
              icon: const Icon(Icons.refresh),
              label: Text('Coba Lagi',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A3D2F),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CITY PICKER DIALOG
  // ─────────────────────────────────────────────────────────────
  void _showCityPicker() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2B1E), Color(0xFF0D2040)],
            ),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Text('Pilih Kota',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: WeatherService.availableCities.map((city) {
                    final isSelected = _selectedCity == city;
                    return ListTile(
                      leading: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF4CAF50).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.white24,
                          ),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.white38,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        city,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (_selectedCity != city) {
                          setState(() => _selectedCity = city);
                          _fetchWeather();
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(text,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _sectionTitleSmall(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  String _formatLocalDatetime(String localDatetime) {
    try {
      final dt = DateTime.parse(localDatetime.replaceAll(' ', 'T'));
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month]} · ${dt.hour.toString().padLeft(2, '0')}:00';
    } catch (_) {
      return localDatetime;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────
// LOADING INDICATOR
// ─────────────────────────────────────────────────────────────
class _WeatherLoadingIndicator extends StatefulWidget {
  const _WeatherLoadingIndicator();

  @override
  State<_WeatherLoadingIndicator> createState() => _WeatherLoadingIndicatorState();
}

class _WeatherLoadingIndicatorState extends State<_WeatherLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _rotation = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _rotation,
          builder: (_, __) => Transform.rotate(
            angle: _rotation.value * 2 * math.pi,
            child: const Text('🌤️', style: TextStyle(fontSize: 52)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Mengambil data BMKG...',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        const SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}
