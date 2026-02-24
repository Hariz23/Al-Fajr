import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'qiblah_screen.dart';
import 'quran_screen.dart';
import 'salat_screen.dart';
import 'zakat_screen.dart';
import 'zikir_doa_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'admin_panel.dart';
import 'theme.dart';

class MainDashboard extends StatefulWidget {
  final bool isAdmin; 
  const MainDashboard({super.key, required this.isAdmin});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // The list of 5 screens
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onNavigate, isAdmin: widget.isAdmin), 
      const QuranScreen(),
      const QiblahScreen(),
      const CalendarScreen(),
      const SettingsScreen(), 
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Required for 5 items
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: "Quran"),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: "Qiblat"),
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  final bool isAdmin;
  const HomeScreen({super.key, required this.onNavigate, required this.isAdmin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? prayerTimes;

  @override
  void initState() {
    super.initState();
    _fetchPrayerTimes();
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      // Fetching for Kuala Lumpur (JAKIM Method usually maps to Method 11)
      final response = await http.get(Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=Kuala%20Lumpur&country=Malaysia&method=11'));
      if (response.statusCode == 200) {
        setState(() {
          prayerTimes = json.decode(response.body)['data']['timings'];
        });
      }
    } catch (e) {
      debugPrint("Prayer Time API Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              padding: const EdgeInsets.only(top: 20),
              children: [
                _buildMenuCard("Al-Quran", Icons.menu_book, () => widget.onNavigate(1)),
                _buildMenuCard("Waktu Solat", Icons.access_time, () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const SalatScreen()));
                }),
                _buildMenuCard("Zikir & Doa", Icons.auto_awesome, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ZikirDoaScreen()));
                }),
                _buildMenuCard("Zakat", Icons.volunteer_activism, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ZakatScreen()));
                }),
                _buildMenuCard("Arah Qiblat", Icons.explore, () => widget.onNavigate(2)),
                
                // ADMIN PANEL ONLY VISIBLE TO ADMINS
                // Inside _buildMenuCard for Admin Panel in home_screen.dart
if (widget.isAdmin)
  _buildMenuCard("Admin Panel", Icons.admin_panel_settings, () {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanel()));
  }, isSpecial: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 25, right: 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Assalamu Alaikum,", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const Text("Masjid Al-Fajr", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _prayerTime("Subuh", prayerTimes?['Fajr']),
                _prayerTime("Zohor", prayerTimes?['Dhuhr']),
                _prayerTime("Asar", prayerTimes?['Asr']),
                _prayerTime("Maghrib", prayerTimes?['Maghrib']),
                _prayerTime("Isyak", prayerTimes?['Isha']),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _prayerTime(String label, String? time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 4),
        Text(time ?? "--:--", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildMenuCard(String title, IconData icon, VoidCallback onTap, {bool isSpecial = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isSpecial ? Border.all(color: AppTheme.primaryGreen, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: AppTheme.primaryGreen),
            const SizedBox(height: 12),
            Text(title, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}