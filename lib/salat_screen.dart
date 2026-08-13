import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'theme.dart';

class SalatScreen extends StatefulWidget {
  const SalatScreen({super.key});

  @override
  State<SalatScreen> createState() => _SalatScreenState();
}

class _SalatScreenState extends State<SalatScreen> {
  late Future<Map<String, dynamic>> _salatFuture;

  Map<String, dynamic> get _fallbackSalatData => {
    'timings': {
      'Fajr': '05:52',
      'Sunrise': '07:11',
      'Dhuhr': '13:18',
      'Asr': '16:36',
      'Maghrib': '19:25',
      'Isha': '20:36',
    },
    'date': {
      'hijri': {
        'day': '28',
        'month': {'en': 'Safar'},
        'year': '1448',
      },
    },
  };

  static const _prayers = <_PrayerVisual>[
    _PrayerVisual('Fajr', CupertinoIcons.cloud_moon_fill),
    _PrayerVisual('Sunrise', CupertinoIcons.sunrise_fill),
    _PrayerVisual('Dhuhr', CupertinoIcons.sun_max_fill),
    _PrayerVisual('Asr', CupertinoIcons.cloud_sun_fill),
    _PrayerVisual('Maghrib', CupertinoIcons.sunset_fill),
    _PrayerVisual('Isha', CupertinoIcons.moon_stars_fill),
  ];

  @override
  void initState() {
    super.initState();
    _salatFuture = _fetchSalatData();
  }

  Future<Map<String, dynamic>> _fetchSalatData() async {
    final response = await http
        .get(
          Uri.parse(
            'https://api.aladhan.com/v1/timingsByCity?city=Kuala%20Lumpur&country=Malaysia&method=11',
          ),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception('Failed to load prayer times');
  }

  void _retry() => setState(() => _salatFuture = _fetchSalatData());

  String _nextPrayerName(Map<String, dynamic> timings) {
    final now = DateTime.now();
    for (final prayer in _prayers.where((item) => item.name != 'Sunrise')) {
      final parts = timings[prayer.name].toString().split(' ').first.split(':');
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (time.isAfter(now)) return prayer.name;
    }
    return 'Fajr';
  }

  String _countdown(Map<String, dynamic> timings, String prayer) {
    final now = DateTime.now();
    final parts = timings[prayer].toString().split(' ').first.split(':');
    var time = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    if (!time.isAfter(now)) time = time.add(const Duration(days: 1));
    final delta = time.difference(now);
    return '${delta.inHours.toString().padLeft(2, '0')}h ${delta.inMinutes.remainder(60).toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSoftWhite,
      appBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.bgSoftWhite.withValues(alpha: 0.94),
        border: const Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
        middle: const Text(
          'Prayer Times',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        leading: CupertinoNavigationBarBackButton(
          color: AppTheme.primaryGreen,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const Icon(
          CupertinoIcons.location_fill,
          size: 18,
          color: AppTheme.primaryGreen,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _salatFuture,
        initialData: kDebugMode ? _fallbackSalatData : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: AppTheme.primaryGreen,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _PrayerError(onRetry: _retry);
          }

          final timings = snapshot.data!['timings'] as Map<String, dynamic>;
          final date = snapshot.data!['date'] as Map<String, dynamic>;
          final nextPrayer = _nextPrayerName(timings);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                sliver: SliverList.list(
                  children: [
                    _LocationRow(date: date),
                    const SizedBox(height: 15),
                    _NextPrayerCard(
                      prayer: nextPrayer,
                      time: timings[nextPrayer].toString().split(' ').first,
                      countdown: _countdown(timings, nextPrayer),
                    ),
                    const SizedBox(height: 20),
                    const _WeekStrip(),
                    const SizedBox(height: 24),
                    const Text(
                      'Today',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < _prayers.length;
                            index++
                          ) ...[
                            _PrayerRow(
                              prayer: _prayers[index],
                              time: timings[_prayers[index].name]
                                  .toString()
                                  .split(' ')
                                  .first,
                              isNext: _prayers[index].name == nextPrayer,
                            ),
                            if (index != _prayers.length - 1)
                              const Divider(
                                height: 0.5,
                                thickness: 0.5,
                                indent: 66,
                                color: AppTheme.divider,
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: AppTheme.mint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_shield_fill,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'JAKIM · Malaysia',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Official calculation method (WLY01)',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_forward,
                            color: AppTheme.primaryGreen,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final Map<String, dynamic> date;

  const _LocationRow({required this.date});

  @override
  Widget build(BuildContext context) {
    final hijri = date['hijri'] as Map<String, dynamic>;
    return Row(
      children: [
        const Icon(
          CupertinoIcons.location_circle_fill,
          color: AppTheme.primaryGreen,
          size: 35,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kuala Lumpur',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const Row(
            children: [
              Icon(
                CupertinoIcons.arrow_clockwise,
                size: 13,
                color: AppTheme.primaryGreen,
              ),
              SizedBox(width: 5),
              Text(
                'Updated',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final String prayer;
  final String time;
  final String countdown;

  const _NextPrayerCard({
    required this.prayer,
    required this.time,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF075D43), Color(0xFF118261)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 26,
                ),
              ),
            ),
          ),
          Positioned(
            right: 34,
            top: 34,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.sun_max_fill,
                color: AppTheme.accentGold,
                size: 28,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT PRAYER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.15,
                  ),
                ),
                const Spacer(),
                Text(
                  prayer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Begins in $countdown',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = start.add(Duration(days: index));
        final isToday = day.day == today.day && day.month == today.month;
        return Container(
          width: 43,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isToday ? AppTheme.primaryGreen : AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday ? AppTheme.primaryGreen : AppTheme.divider,
            ),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(day).substring(0, 2),
                style: TextStyle(
                  color: isToday ? Colors.white70 : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: isToday ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PrayerVisual {
  final String name;
  final IconData icon;

  const _PrayerVisual(this.name, this.icon);
}

class _PrayerRow extends StatelessWidget {
  final _PrayerVisual prayer;
  final String time;
  final bool isNext;

  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      color: isNext ? AppTheme.mint : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isNext ? Colors.white : AppTheme.bgSoftWhite,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              prayer.icon,
              size: 18,
              color: isNext ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prayer.name,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          if (isNext) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.accentGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            time,
            style: TextStyle(
              color: isNext ? AppTheme.primaryGreen : AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            isNext ? CupertinoIcons.speaker_2_fill : CupertinoIcons.bell,
            size: 17,
            color: isNext ? AppTheme.primaryGreen : AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _PrayerError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PrayerError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.wifi_exclamationmark,
              color: AppTheme.primaryGreen,
              size: 38,
            ),
            const SizedBox(height: 14),
            const Text(
              'Prayer times are unavailable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
