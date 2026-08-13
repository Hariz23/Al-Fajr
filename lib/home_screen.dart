import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_panel.dart';
import 'calendar_screen.dart';
import 'language_provider.dart';
import 'qiblah_screen.dart';
import 'prayer_times_repository.dart';
import 'quran_screen.dart';
import 'salat_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'zakat_screen.dart';
import 'zikir_doa_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  void _onNavigate(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String currentRole = 'user';
        var isAdmin = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentRole = data['role'] ?? 'user';
          isAdmin = currentRole == 'admin' || currentRole == 'super_admin';
        }

        final screens = <Widget>[
          HomeScreen(onNavigate: _onNavigate, isAdmin: isAdmin),
          const QuranScreen(),
          const QiblahScreen(),
          const CalendarScreen(),
          SettingsScreen(role: currentRole),
        ];

        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.96),
              border: const Border(
                top: BorderSide(color: AppTheme.divider, width: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.045),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CupertinoTabBar(
              currentIndex: _currentIndex,
              onTap: _onNavigate,
              activeColor: AppTheme.primaryGreen,
              inactiveColor: AppTheme.textSecondary,
              backgroundColor: Colors.transparent,
              border: const Border(),
              iconSize: 23,
              height: 62,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.house),
                  activeIcon: const Icon(CupertinoIcons.house_fill),
                  label: lang.getText('Home', 'Utama'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.book),
                  activeIcon: const Icon(CupertinoIcons.book_fill),
                  label: lang.getText('Quran', 'Al-Quran'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.location_north),
                  activeIcon: const Icon(CupertinoIcons.location_north_fill),
                  label: lang.getText('Qiblat', 'Kiblat'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.calendar),
                  activeIcon: const Icon(CupertinoIcons.calendar_today),
                  label: lang.getText('Events', 'Acara'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(CupertinoIcons.gear),
                  activeIcon: const Icon(CupertinoIcons.gear_solid),
                  label: lang.getText('Settings', 'Tetapan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.isAdmin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _fallbackTimes = <String, String>{
    'Fajr': '05:52',
    'Dhuhr': '13:18',
    'Asr': '16:36',
    'Maghrib': '19:25',
    'Isha': '20:36',
  };

  Map<String, dynamic>? prayerTimes;

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final data = await PrayerTimesRepository.fetchKualaLumpur();
      if (mounted) setState(() => prayerTimes = data);
    } catch (error) {
      debugPrint('Prayer API error: $error');
    }
  }

  MapEntry<String, DateTime>? _nextPrayer() {
    final now = DateTime.now();
    final times = prayerTimes ?? (kDebugMode ? _fallbackTimes : null);
    if (times == null) return null;
    for (final prayer in _fallbackTimes.keys) {
      final value = (times[prayer] ?? _fallbackTimes[prayer]!)
          .toString()
          .split(' ')
          .first;
      final parts = value.split(':');
      final date = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (date.isAfter(now)) return MapEntry(prayer, date);
    }
    final value = (times['Fajr'] ?? _fallbackTimes['Fajr']!)
        .toString()
        .split(' ')
        .first;
    final parts = value.split(':');
    return MapEntry(
      'Fajr',
      DateTime(
        now.year,
        now.month,
        now.day + 1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ),
    );
  }

  String _countdown(DateTime prayer) {
    final difference = prayer.difference(DateTime.now());
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final userName = data?['name']?.toString().trim();
        final masjidName = data?['masjidName']?.toString().trim();
        final masjidId = data?['masjidID']?.toString();
        final nextPrayer = _nextPrayer();

        return Scaffold(
          backgroundColor: AppTheme.bgSoftWhite,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  userName: userName?.isNotEmpty == true
                      ? userName!
                      : lang.getText('Guest', 'Tetamu'),
                  masjidName: masjidName?.isNotEmpty == true
                      ? masjidName!
                      : 'Kuala Lumpur, Malaysia',
                  nextPrayer:
                      nextPrayer?.key ??
                      lang.getText('Prayer times', 'Waktu solat'),
                  nextPrayerTime: nextPrayer == null
                      ? '—'
                      : TimeOfDay.fromDateTime(
                          nextPrayer.value,
                        ).format(context),
                  countdown: nextPrayer == null
                      ? lang.getText('Refreshing…', 'Mengemas kini…')
                      : _countdown(nextPrayer.value),
                  onOpenPrayers: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const SalatScreen()),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 118),
                sliver: SliverList.list(
                  children: [
                    _SectionTitle(
                      title: lang.getText('Your day', 'Hari anda'),
                      action: lang.getText('See all', 'Lihat semua'),
                    ),
                    const SizedBox(height: 13),
                    _DailyVerseCard(lang: lang),
                    const SizedBox(height: 26),
                    _SectionTitle(title: lang.getText('Explore', 'Terokai')),
                    const SizedBox(height: 13),
                    _ActionGrid(
                      actions: [
                        _HomeAction(
                          title: lang.getText('Al-Quran', 'Al-Quran'),
                          subtitle: lang.getText(
                            'Read & listen',
                            'Baca & dengar',
                          ),
                          icon: CupertinoIcons.book_fill,
                          color: AppTheme.primaryGreen,
                          background: AppTheme.mint,
                          onTap: () => widget.onNavigate(1),
                        ),
                        _HomeAction(
                          title: lang.getText('Dhikr & Dua', 'Zikir & Doa'),
                          subtitle: lang.getText(
                            'Daily remembrance',
                            'Amalan harian',
                          ),
                          icon: CupertinoIcons.sparkles,
                          color: AppTheme.accentGoldDeep,
                          background: AppTheme.warmCream,
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const ZikirDoaScreen(),
                            ),
                          ),
                        ),
                        _HomeAction(
                          title: lang.getText('Qiblat', 'Kiblat'),
                          subtitle: lang.getText('Find direction', 'Cari arah'),
                          icon: CupertinoIcons.location_north_fill,
                          color: AppTheme.accentTeal,
                          background: AppTheme.tealTint,
                          onTap: () => widget.onNavigate(2),
                        ),
                        _HomeAction(
                          title: lang.getText('Zakat', 'Zakat'),
                          subtitle: lang.getText(
                            'Calculate easily',
                            'Kira dengan mudah',
                          ),
                          icon: CupertinoIcons.heart_fill,
                          color: AppTheme.accentClay,
                          background: AppTheme.clayTint,
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const ZakatScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(height: 14),
                      _AdminCard(
                        onTap: masjidId == null
                            ? null
                            : () => Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => AdminPanel(
                                    masjidId: masjidId,
                                    masjidName: masjidName,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String userName;
  final String masjidName;
  final String nextPrayer;
  final String nextPrayerTime;
  final String countdown;
  final VoidCallback onOpenPrayers;

  const _HeroHeader({
    required this.userName,
    required this.masjidName,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.countdown,
    required this.onOpenPrayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.headerGradientStart, AppTheme.headerGradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _SkyPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          userName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assalammualaikum, $userName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              masjidName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HeaderButton(
                        icon: CupertinoIcons.bell_fill,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 29),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'NEXT PRAYER',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              nextPrayer,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.1,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '$nextPrayerTime  •  in $countdown',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.sun_max_fill,
                              color: AppTheme.accentGold,
                              size: 34,
                            ),
                            Positioned(
                              top: 7,
                              right: 17,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: onOpenPrayers,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.09),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PrayerMini(
                            name: 'Fajr',
                            icon: CupertinoIcons.cloud_moon_fill,
                          ),
                          _PrayerMini(
                            name: 'Dhuhr',
                            icon: CupertinoIcons.sun_max_fill,
                          ),
                          _PrayerMini(
                            name: 'Asr',
                            icon: CupertinoIcons.cloud_sun_fill,
                          ),
                          _PrayerMini(
                            name: 'Maghrib',
                            icon: CupertinoIcons.sunset_fill,
                          ),
                          _PrayerMini(
                            name: 'Isha',
                            icon: CupertinoIcons.moon_stars_fill,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tap to view all prayer times ›',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.46),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(42, 42),
      onPressed: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _PrayerMini extends StatelessWidget {
  final String name;
  final IconData icon;

  const _PrayerMini({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.72)),
        const SizedBox(height: 5),
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.55,
            ),
          ),
        ),
        if (action != null)
          Text(
            action!,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _DailyVerseCard extends StatelessWidget {
  final LanguageProvider lang;

  const _DailyVerseCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppTheme.warmCream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.quote_bubble_fill,
              color: AppTheme.accentGold,
              size: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText('Verse of the day', 'Ayat hari ini'),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '“Indeed, with hardship comes ease.”',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ash-Sharh · 94:6',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 15,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });
}

class _ActionGrid extends StatelessWidget {
  final List<_HomeAction> actions;

  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: action.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: action.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20),
                ),
                const Spacer(),
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _AdminCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.mint,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Icon(CupertinoIcons.person_2_fill, color: AppTheme.primaryGreen),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Masjid admin panel',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: AppTheme.primaryGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.45),
      size.width * 0.34,
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.45),
      size.width * 0.23,
      linePaint,
    );

    final dotPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.45);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final center = Offset(
        size.width * 0.86 + math.cos(angle) * size.width * 0.29,
        size.height * 0.45 + math.sin(angle) * size.width * 0.29,
      );
      canvas.drawCircle(center, i.isEven ? 2.2 : 1.3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
