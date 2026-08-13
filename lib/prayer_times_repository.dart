import 'dart:convert';

import 'package:http/http.dart' as http;

class PrayerTimesRepository {
  PrayerTimesRepository._();

  static const _endpoint =
      'https://api.aladhan.com/v1/timingsByCity?city=Kuala%20Lumpur&country=Malaysia&method=11';

  static Future<Map<String, String>> fetchKualaLumpur() async {
    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Prayer times service returned ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final rawTimings = data?['timings'] as Map<String, dynamic>?;
    if (rawTimings == null) throw Exception('Prayer times are missing');

    const supported = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final timings = <String, String>{};
    for (final prayer in supported) {
      final raw = rawTimings[prayer];
      // Without this guard a missing key becomes the string "null", which then
      // fails silently further down in scheduleAllPrayers.
      if (raw is! String || raw.trim().isEmpty) {
        throw Exception('Prayer times are missing $prayer');
      }
      timings[prayer] = raw.trim().split(' ').first;
    }
    return timings;
  }
}
