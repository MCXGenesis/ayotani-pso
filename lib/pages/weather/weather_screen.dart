import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weather_model.dart';
import '../../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();

  BmkgWeatherData? _weatherData;
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedCity = 'Surabaya';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchWeather();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _animController.reset();

    final data = await _weatherService.getWeatherByCity(_selectedCity);

    if (!mounted) return;
    setState(() {
      _weatherData = data;
      _isLoading = false;
      _hasError = data == null;
    });
    if (data != null) _animController.forward();
  }

  Color _getBgColor(BmkgWeatherEntry? entry) {
    if (entry == null) return const Color(0xFF0A3D2F);
    if (entry.isRainy) return const Color(0xFF1A3A5C);
    if (entry.weatherCode == 0) return const Color(0xFF1B6CA8);
    if (entry.weatherCode <= 2) return const Color(0xFF2980B9);
    return const Color(0xFF34495E);
  }

  Color _getBgColor2(BmkgWeatherEntry? entry) {
    if (entry == null) return const Color(0xFF1A7A5E);
    if (entry.isRainy) return const Color(0xFF2C5F8A);
    if (entry.weatherCode == 0) return const Color(0xFF2ECC71).withValues(alpha: 0.7);
    return const Color(0xFF27AE60).withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final current = _weatherData?.current;
    final bgColor1 = _getBgColor(current);
    final bgColor2 = _getBgColor2(current);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor1, bgColor2],
          ),
        ),
        child: SafeArea(
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildCurrentWeather(),
                          const SizedBox(height: 8),
                          _buildWeatherDetails(),
                          const SizedBox(height: 20),
                          _buildHourlyForecast(),
                          const SizedBox(height: 20),
                          _buildDailyForecast(),
                          const SizedBox(height: 20),
                          _buildAgriculturalTips(),
                          const SizedBox(height: 20),
                          _buildBmkgAttribution(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // TOP BAR
  // ──────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
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
                Text('Data resmi dari BMKG',
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // City selector
          GestureDetector(
            onTap: _showCityPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(_selectedCity,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh button
          GestureDetector(
            onTap: _fetchWeather,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // CURRENT WEATHER
  // ──────────────────────────────────────────────
  Widget _buildCurrentWeather() {
    final current = _weatherData!.current;
    final location = _weatherData!.location;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '${location.kecamatan}, ${location.kotkab}',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weather icon (emoji large)
          Text(current.weatherIcon, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),

          // Temperature
          Text(
            '${current.temperature}°C',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 68,
              fontWeight: FontWeight.w200,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 8),
          // Condition
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              current.weatherDesc,
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Prakiraan: ${_formatLocalDatetime(current.localDatetime)} (Sekarang: ${_formatCurrentTime(_weatherData?.fetchedAt, location.timezone)})',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // WEATHER DETAILS CARDS
  // ──────────────────────────────────────────────
  Widget _buildWeatherDetails() {
    final current = _weatherData!.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDetailItem(
                Icons.water_drop_outlined,
                '${current.humidity}%',
                'Kelembapan'),
            _buildDetailDivider(),
            _buildDetailItem(
                Icons.air,
                '${current.windSpeed.toStringAsFixed(1)} m/s',
                'Angin ${current.windDirection}'),
            _buildDetailDivider(),
            _buildDetailItem(
                Icons.umbrella_outlined,
                '${current.precipitation} mm',
                'Curah Hujan'),
            _buildDetailDivider(),
            _buildDetailItem(
                Icons.visibility_outlined,
                current.visibilityText,
                'Jarak Pandang'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDetailDivider() {
    return Container(width: 1, height: 40, color: Colors.white24);
  }

  // ──────────────────────────────────────────────
  // HOURLY FORECAST
  // ──────────────────────────────────────────────
  Widget _buildHourlyForecast() {
    final todayEntries = _weatherData!.todayEntries;
    if (todayEntries.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Prakiraan Hari Ini',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: todayEntries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final entry = todayEntries[i];
              final isNow = entry == _weatherData!.current;
              return Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isNow
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: isNow
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(entry.timeFormatted,
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11)),
                    Text(entry.weatherIcon,
                        style: const TextStyle(fontSize: 22)),
                    Text('${entry.temperature}°',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // 3-DAY DAILY FORECAST
  // ──────────────────────────────────────────────
  Widget _buildDailyForecast() {
    final days = _weatherData!.dailyForecasts;
    if (days.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prakiraan 3 Hari',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...days.take(3).map((day) => _buildDayRow(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(BmkgDayForecast day) {
    final rep = day.representative;
    final isToday = _isSameDay(day.date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              isToday ? 'Hari ini' : day.representative.dayName,
              style: GoogleFonts.inter(
                  color: isToday ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Text(rep.weatherIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(rep.weatherDesc,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ),
          Text('${day.minTemp}°',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          const SizedBox(width: 4),
          _buildTempBar(day.minTemp, day.maxTemp),
          const SizedBox(width: 4),
          Text('${day.maxTemp}°',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTempBar(int min, int max) {
    return Container(
      width: 60,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.6),
            Colors.orange.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // AGRICULTURAL TIPS
  // ──────────────────────────────────────────────
  Widget _buildAgriculturalTips() {
    final current = _weatherData!.current;
    final tips = _getAgriculturalTips(current);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌾', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Rekomendasi Pertanian',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip['icon']!,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip['title']!,
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Text(tip['desc']!,
                                style: GoogleFonts.inter(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getAgriculturalTips(BmkgWeatherEntry entry) {
    final tips = <Map<String, String>>[];

    if (entry.isRainy) {
      tips.add({
        'icon': '🚫',
        'title': 'Tunda Penyiraman',
        'desc': 'Hujan cukup untuk kebutuhan air tanaman hari ini.',
      });
      tips.add({
        'icon': '🌿',
        'title': 'Waspadai Penyakit Tanaman',
        'desc': 'Kelembapan tinggi meningkatkan risiko jamur & bakteri.',
      });
      tips.add({
        'icon': '💧',
        'title': 'Periksa Drainase',
        'desc': 'Pastikan saluran air lahan tidak tersumbat.',
      });
    } else if (entry.weatherCode == 0) {
      tips.add({
        'icon': '✅',
        'title': 'Waktu Ideal Bertani',
        'desc': 'Cuaca cerah, cocok untuk semua aktivitas di ladang.',
      });
      tips.add({
        'icon': '💧',
        'title': 'Siram Pagi & Sore',
        'desc': 'Suhu ${entry.temperature}°C – siram rutin untuk cegah kekeringan.',
      });
      tips.add({
        'icon': '🌻',
        'title': 'Fotosintesis Optimal',
        'desc': 'Cahaya matahari penuh mendukung pertumbuhan tanaman.',
      });
    } else {
      tips.add({
        'icon': '🌤️',
        'title': 'Cuaca Moderat',
        'desc': 'Kondisi baik untuk pemupukan dan perawatan tanaman.',
      });
      tips.add({
        'icon': '💧',
        'title': 'Pantau Kebutuhan Air',
        'desc': 'Kelembapan ${entry.humidity}% – sesuaikan jadwal penyiraman.',
      });
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

  // ──────────────────────────────────────────────
  // BMKG ATTRIBUTION
  // ──────────────────────────────────────────────
  Widget _buildBmkgAttribution() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data prakiraan cuaca bersumber dari BMKG (Badan Meteorologi, Klimatologi, dan Geofisika) Indonesia – bmkg.go.id',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // ERROR STATE
  // ──────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌩️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Gagal Mengambil Data Cuaca',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet Anda dan coba lagi.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchWeather,
              icon: const Icon(Icons.refresh),
              label: Text('Coba Lagi',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A3D2F),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // CITY PICKER
  // ──────────────────────────────────────────────
  void _showCityPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2B1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text(
            'Pilih Kota',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: WeatherService.availableCities.map(
              (city) => ListTile(
                leading: Icon(
                  _selectedCity == city
                      ? Icons.location_on
                      : Icons.location_on_outlined,
                  color: _selectedCity == city
                      ? const Color(0xFF4CAF50)
                      : Colors.white54,
                ),
                title: Text(
                  city,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: _selectedCity == city
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _selectedCity == city
                    ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (_selectedCity != city) {
                    setState(() => _selectedCity = city);
                    _fetchWeather();
                  }
                },
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────
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

  String _formatCurrentTime(DateTime? dt, String? tzOffset) {
    if (dt == null) return '--:--';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    
    String tzName = 'WIB';
    if (tzOffset == '+0800') {
      tzName = 'WITA';
    } else if (tzOffset == '+0900') {
      tzName = 'WIT';
    }
    
    return '$hour:$minute $tzName';
  }
}

// ──────────────────────────────────────────────
// LOADING INDICATOR
// ──────────────────────────────────────────────
class _WeatherLoadingIndicator extends StatelessWidget {
  const _WeatherLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
        const SizedBox(height: 16),
        Text(
          'Mengambil data dari BMKG...',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
