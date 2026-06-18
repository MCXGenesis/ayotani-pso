class BmkgLocation {
  final String provinsi;
  final String kotkab;
  final String kecamatan;
  final String desa;
  final double lon;
  final double lat;
  final String timezone;

  BmkgLocation({
    required this.provinsi,
    required this.kotkab,
    required this.kecamatan,
    required this.desa,
    required this.lon,
    required this.lat,
    required this.timezone,
  });

  factory BmkgLocation.fromJson(Map<String, dynamic> json) {
    return BmkgLocation(
      provinsi: json['provinsi'] ?? '',
      kotkab: json['kotkab'] ?? '',
      kecamatan: json['kecamatan'] ?? '',
      desa: json['desa'] ?? '',
      lon: (json['lon'] ?? 0.0).toDouble(),
      lat: (json['lat'] ?? 0.0).toDouble(),
      timezone: json['timezone'] ?? '+0700',
    );
  }
}

class BmkgWeatherEntry {
  final String datetime;
  final String localDatetime;
  final int temperature;
  final int humidity;
  final double windSpeed;
  final String windDirection;
  final int weatherCode;
  final String weatherDesc;
  final String weatherDescEn;
  final String imageUrl;
  final double precipitation;
  final String visibilityText;

  BmkgWeatherEntry({
    required this.datetime,
    required this.localDatetime,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
    required this.weatherDesc,
    required this.weatherDescEn,
    required this.imageUrl,
    required this.precipitation,
    required this.visibilityText,
  });

  factory BmkgWeatherEntry.fromJson(Map<String, dynamic> json) {
    return BmkgWeatherEntry(
      datetime: json['datetime'] ?? '',
      localDatetime: json['local_datetime'] ?? '',
      temperature: (json['t'] ?? 0).toInt(),
      humidity: (json['hu'] ?? 0).toInt(),
      windSpeed: (json['ws'] ?? 0.0).toDouble(),
      windDirection: json['wd'] ?? '',
      weatherCode: (json['weather'] ?? 0).toInt(),
      weatherDesc: json['weather_desc'] ?? '',
      weatherDescEn: json['weather_desc_en'] ?? '',
      imageUrl: json['image'] ?? '',
      precipitation: (json['tp'] ?? 0.0).toDouble(),
      visibilityText: json['vs_text'] ?? '',
    );
  }

  /// Get friendly weather icon for display
  String get weatherIcon {
    switch (weatherCode) {
      case 0: return '☀️'; // Cerah
      case 1: return '🌤️'; // Cerah Berawan
      case 2: return '⛅'; // Cerah Berawan
      case 3: return '🌥️'; // Berawan
      case 4: return '☁️'; // Berawan Tebal
      case 5: return '🌦️'; // Udara Kabur
      case 10: return '🌫️'; // Asap
      case 45: return '🌫️'; // Kabut
      case 60: return '🌧️'; // Hujan Ringan
      case 61: return '🌧️'; // Hujan Sedang
      case 63: return '⛈️'; // Hujan Lebat
      case 80: return '🌧️'; // Hujan Lokal
      case 95: return '⛈️'; // Hujan Petir
      case 97: return '⛈️'; // Hujan Petir Lebat
      default: return '🌤️';
    }
  }

  /// Parse local_datetime to DateTime
  DateTime get localTime {
    try {
      return DateTime.parse(localDatetime.replaceAll(' ', 'T'));
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Get day name from local_datetime
  String get dayName {
    final dt = localTime;
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[dt.weekday % 7];
  }

  /// Get formatted time (e.g. 09:00)
  String get timeFormatted {
    final dt = localTime;
    return '${dt.hour.toString().padLeft(2, '0')}:00';
  }

  bool get isRainy => weatherCode >= 60;
}

class BmkgDayForecast {
  final DateTime date;
  final List<BmkgWeatherEntry> entries;

  BmkgDayForecast({required this.date, required this.entries});

  int get minTemp => entries.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
  int get maxTemp => entries.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);

  BmkgWeatherEntry get representative {
    // Pick the entry at noon or the most extreme one
    return entries.firstWhere(
      (e) => e.localTime.hour >= 10 && e.localTime.hour <= 14,
      orElse: () => entries.first,
    );
  }
}

class BmkgWeatherData {
  final BmkgLocation location;
  final List<BmkgWeatherEntry> allEntries;
  final DateTime fetchedAt;

  BmkgWeatherData({
    required this.location,
    required this.allEntries,
    required this.fetchedAt,
  });

  /// Current weather (closest entry to now)
  BmkgWeatherEntry get current {
    if (allEntries.isEmpty) throw StateError('No weather data');
    final now = DateTime.now();
    return allEntries.reduce((a, b) {
      final diffA = a.localTime.difference(now).abs();
      final diffB = b.localTime.difference(now).abs();
      return diffA < diffB ? a : b;
    });
  }

  /// Group entries by day for 3-day forecast
  List<BmkgDayForecast> get dailyForecasts {
    final Map<String, List<BmkgWeatherEntry>> grouped = {};
    for (final entry in allEntries) {
      final key = '${entry.localTime.year}-${entry.localTime.month}-${entry.localTime.day}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped.entries
        .map((e) => BmkgDayForecast(
              date: grouped[e.key]!.first.localTime,
              entries: e.value,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Entries for today only
  List<BmkgWeatherEntry> get todayEntries {
    final today = DateTime.now();
    return allEntries.where((e) {
      final dt = e.localTime;
      return dt.year == today.year && dt.month == today.month && dt.day == today.day;
    }).toList();
  }

  /// Interpolated hourly entries for the next 24 hours
  List<BmkgWeatherEntry> getHourlyForecast24h() {
    if (allEntries.isEmpty) return [];

    // Sort allEntries just to be absolutely sure
    final sorted = List<BmkgWeatherEntry>.from(allEntries)
      ..sort((a, b) => a.localTime.compareTo(b.localTime));

    final now = DateTime.now();
    final startHour = DateTime(now.year, now.month, now.day, now.hour);
    final List<BmkgWeatherEntry> result = [];

    for (int i = 0; i < 24; i++) {
      final targetTime = startHour.add(Duration(hours: i));

      // Find the entries bounding targetTime
      BmkgWeatherEntry? before;
      BmkgWeatherEntry? after;

      for (final entry in sorted) {
        final entryTime = entry.localTime;
        if (entryTime.isBefore(targetTime) || entryTime.isAtSameMomentAs(targetTime)) {
          if (before == null || entryTime.isAfter(before.localTime)) {
            before = entry;
          }
        }
        if (entryTime.isAfter(targetTime) || entryTime.isAtSameMomentAs(targetTime)) {
          if (after == null || entryTime.isBefore(after.localTime)) {
            after = entry;
          }
        }
      }

      if (before == null && after == null) {
        continue;
      }

      final BmkgWeatherEntry interpolated;
      if (before != null && after != null && !before.localTime.isAtSameMomentAs(after.localTime)) {
        // Interpolate
        final totalMinutes = after.localTime.difference(before.localTime).inMinutes;
        final targetMinutes = targetTime.difference(before.localTime).inMinutes;
        final ratio = totalMinutes > 0 ? targetMinutes / totalMinutes : 0.0;

        final temp = (before.temperature + (after.temperature - before.temperature) * ratio).round();
        final hum = (before.humidity + (after.humidity - before.humidity) * ratio).round();
        final ws = before.windSpeed + (after.windSpeed - before.windSpeed) * ratio;
        final precip = before.precipitation + (after.precipitation - before.precipitation) * ratio;

        // Choose closer entry for discrete/string properties
        final closer = ratio <= 0.5 ? before : after;

        interpolated = BmkgWeatherEntry(
          datetime: closer.datetime,
          localDatetime: _formatDateTime(targetTime),
          temperature: temp,
          humidity: hum,
          windSpeed: ws,
          windDirection: closer.windDirection,
          weatherCode: closer.weatherCode,
          weatherDesc: closer.weatherDesc,
          weatherDescEn: closer.weatherDescEn,
          imageUrl: closer.imageUrl,
          precipitation: precip,
          visibilityText: closer.visibilityText,
        );
      } else {
        // Only one of them is available, or they are at the exact same moment
        final base = before ?? after!;
        interpolated = BmkgWeatherEntry(
          datetime: base.datetime,
          localDatetime: _formatDateTime(targetTime),
          temperature: base.temperature,
          humidity: base.humidity,
          windSpeed: base.windSpeed,
          windDirection: base.windDirection,
          weatherCode: base.weatherCode,
          weatherDesc: base.weatherDesc,
          weatherDescEn: base.weatherDescEn,
          imageUrl: base.imageUrl,
          precipitation: base.precipitation,
          visibilityText: base.visibilityText,
        );
      }

      result.add(interpolated);
    }

    return result;
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return "$y-$m-$d $h:$min:$s";
  }

  static BmkgWeatherData fromJson(Map<String, dynamic> json) {
    final location = BmkgLocation.fromJson(json['lokasi'] as Map<String, dynamic>);
    final dataList = json['data'] as List<dynamic>;

    final List<BmkgWeatherEntry> entries = [];
    if (dataList.isNotEmpty) {
      final cuacaDays = dataList[0]['cuaca'] as List<dynamic>;
      for (final day in cuacaDays) {
        for (final entry in day as List<dynamic>) {
          entries.add(BmkgWeatherEntry.fromJson(entry as Map<String, dynamic>));
        }
      }
    }

    return BmkgWeatherData(
      location: location,
      allEntries: entries,
      fetchedAt: DateTime.now(),
    );
  }
}
