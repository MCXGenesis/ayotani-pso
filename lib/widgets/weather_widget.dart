import 'package:flutter/material.dart';
import '../models/iot_reading_model.dart';
import '../services/iot_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class WeatherWidget extends StatefulWidget {
  WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final _iotService = IotService();

  @override
  Widget build(BuildContext context) {
    final supabase = SupabaseService();
    return FutureBuilder<IotReading?>(
      future: _iotService.getLatestReading(supabase.userId ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        final reading = snapshot.data;

        if (reading == null) {
          return _buildNoDataCard();
        }

        return _buildWeatherCard(reading);
      },
    );
  }

  /// Build weather card with current conditions
  Widget _buildWeatherCard(IotReading reading) {
    final temp = reading.temperature ?? 0.0;
    final humidity = reading.humidity ?? 0.0;

    // Determine weather condition based on temperature and humidity
    final weatherCondition = _getWeatherCondition(temp, humidity);
    final weatherIcon = _getWeatherIcon(weatherCondition);
    final weatherText = _getWeatherText(weatherCondition);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getGradientColor1(temp), _getGradientColor2(temp)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weatherText,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${temp.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      color: context.cardBg,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Icon(
                weatherIcon,
                color: context.cardBg,
                size: 56,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelembapan',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${humidity.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: context.cardBg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelembapan Tanah',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(reading.soilMoisture ?? 0).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: context.cardBg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Air',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(reading.waterLevel ?? 0).toStringAsFixed(1)}L',
                    style: TextStyle(
                      color: context.cardBg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get weather condition based on temperature and humidity
  String _getWeatherCondition(double temp, double humidity) {
    if (temp > 30 || humidity > 80) {
      return 'rainy';
    } else if (temp < 15 && humidity < 40) {
      return 'cold';
    } else if (temp >= 15 && temp <= 25 && humidity >= 40 && humidity <= 70) {
      return 'sunny';
    } else if (humidity > 60) {
      return 'cloudy';
    } else {
      return 'sunny';
    }
  }

  /// Get weather icon
  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'rainy':
        return Icons.cloud_queue;
      case 'cold':
        return Icons.ac_unit;
      case 'cloudy':
        return Icons.cloud;
      case 'sunny':
      default:
        return Icons.wb_sunny;
    }
  }

  /// Get weather text
  String _getWeatherText(String condition) {
    switch (condition) {
      case 'rainy':
        return 'Kemungkinan Hujan';
      case 'cold':
        return 'Cuaca Dingin';
      case 'cloudy':
        return 'Mendung';
      case 'sunny':
      default:
        return 'Cerah';
    }
  }

  /// Get gradient color 1 based on temperature
  Color _getGradientColor1(double temp) {
    if (temp > 30) return Color(0xFFFF6B6B);
    if (temp > 25) return Color(0xFFFFD93D);
    if (temp > 15) return Color(0xFF6BCB77);
    return Color(0xFF4D96FF);
  }

  /// Get gradient color 2 based on temperature
  Color _getGradientColor2(double temp) {
    if (temp > 30) return Color(0xFFFF8E53);
    if (temp > 25) return Color(0xFFFFA502);
    if (temp > 15) return AppColors.green;
    return Color(0xFF2E7FBF);
  }

  /// Build loading card
  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.primaryColor.withOpacity(0.3), context.primaryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Gagal memuat data cuaca',
        style: TextStyle(color: Colors.red[700]),
      ),
    );
  }

  /// Build no data card
  Widget _buildNoDataCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Data sensor belum tersedia',
        style: TextStyle(color: context.bgGrey),
      ),
    );
  }
}
