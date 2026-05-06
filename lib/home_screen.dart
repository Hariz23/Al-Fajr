import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'language_provider.dart'; 
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
  const MainDashboard({super.key}); // Clean constructor

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
    final lang = Provider.of<LanguageProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        // Default roles while loading
        String currentRole = 'user';
        bool isAdmin = false;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          currentRole = data['role'] ?? 'user';
          // Check if user is either a masjid admin or the super admin
          isAdmin = (currentRole == 'admin' || currentRole == 'super_admin');
        }

        final List<Widget> screens = [
          HomeScreen(onNavigate: _onNavigate, isAdmin: isAdmin), 
          const QuranScreen(),
          const QiblahScreen(),
          const CalendarScreen(),
          SettingsScreen(role: currentRole), // Passes the exact role string
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryGreen,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: lang.getText("Home", "Utama")),
              BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), label: lang.getText("Quran", "Al-Quran")),
              BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), label: lang.getText("Qiblat", "Kiblat")),
              BottomNavigationBarItem(icon: const Icon(Icons.event_outlined), label: lang.getText("Events", "Acara")),
              BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined), label: lang.getText("Settings", "Tetapan")),
            ],
          ),
        );
      },
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
      final response = await http.get(Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Kuala%20Lumpur&country=Malaysia&method=11'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['timings'];
        if (mounted) setState(() => prayerTimes = data);
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final String? userName = userData?['name'];
        final String? liveMasjidName = userData?['masjidName'];
        final String? liveMasjidId = userData?['masjidID'];

        return Column(
          children: [
            _buildHeader(lang, liveMasjidName, userName),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    mainAxisSpacing: 15, 
                    crossAxisSpacing: 15
                  ),
                  padding: const EdgeInsets.only(top: 20),
                  children: [
                    _buildMenuCard(lang.getText("Al-Quran", "Al-Quran"), Icons.menu_book, () => widget.onNavigate(1)),
                    _buildMenuCard(lang.getText("Prayer Times", "Waktu Solat"), Icons.access_time, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SalatScreen()))),
                    _buildMenuCard(lang.getText("Dhikr & Dua", "Zikir & Doa"), Icons.auto_awesome, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ZikirDoaScreen()))),
                    _buildMenuCard(lang.getText("Zakat", "Zakat"), Icons.volunteer_activism, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ZakatScreen()))),
                    _buildMenuCard(lang.getText("Qiblat Direction", "Arah Qiblat"), Icons.explore, () => widget.onNavigate(2)),
                    if (widget.isAdmin)
                      _buildMenuCard(lang.getText("Admin Panel", "Panel Admin"), Icons.admin_panel_settings, () {
                        if (liveMasjidId != null) Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPanel(masjidId: liveMasjidId, masjidName: liveMasjidName)));
                      }, isSpecial: true),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(LanguageProvider lang, String? masjidName, String? userName) {
    String greeting = "Assalammualaikum, ${userName ?? ""}";
    String subTitle = (masjidName != null && masjidName.isNotEmpty) ? masjidName : lang.getText("Welcome to Hijrah", "Selamat Datang ke Hijrah");

    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 25, right: 25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.primaryGreen, 
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(50))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(subTitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 25),
          _buildPrayerRow(lang),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _prayerTime(lang.getText("Fajr", "Subuh"), prayerTimes?['Fajr']),
          _prayerTime(lang.getText("Dhuhr", "Zohor"), prayerTimes?['Dhuhr']),
          _prayerTime(lang.getText("Asr", "Asar"), prayerTimes?['Asr']),
          _prayerTime(lang.getText("Maghrib", "Maghrib"), prayerTimes?['Maghrib']),
          _prayerTime(lang.getText("Isha", "Isyak"), prayerTimes?['Isha']),
        ],
      ),
    );
  }

  Widget _prayerTime(String label, String? time) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(time ?? "--:--", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }

  Widget _buildMenuCard(String title, IconData icon, VoidCallback onTap, {bool isSpecial = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 35, color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }
}