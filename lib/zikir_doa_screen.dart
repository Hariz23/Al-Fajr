import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class ZikirDoaScreen extends StatelessWidget {
  const ZikirDoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Zikir and Doa
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Adhkar & Devotion"),
          bottom: const TabBar(
            indicatorColor: AppTheme.accentGold,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.repeat), text: "Zikir"),
              Tab(icon: Icon(Icons.favorite), text: "Daily Doa"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ZikirTab(), // Content for Tab 1
            DoaTab(),   // Content for Tab 2
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: ZIKIR COUNTER ---
class ZikirTab extends StatefulWidget {
  const ZikirTab({super.key});

  @override
  State<ZikirTab> createState() => _ZikirTabState();
}

class _ZikirTabState extends State<ZikirTab> {
  int _counter = 0;

  void _increment() {
    HapticFeedback.mediumImpact(); // Vibration feedback
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$_counter", style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _increment,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 10))],
              ),
              child: const Center(
                child: Text("TAP", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 40),
          TextButton.icon(
            onPressed: () => setState(() => _counter = 0),
            icon: const Icon(Icons.refresh, color: Colors.grey),
            label: const Text("Reset Counter", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// --- TAB 2: DOA LIST ---
class DoaTab extends StatelessWidget {
  const DoaTab({super.key});

  final List<Map<String, String>> doas = const [
    {"title": "Morning Prayer", "arabic": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ"},
    {"title": "Before Sleeping", "arabic": "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا"},
    {"title": "For Parents", "arabic": "رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا"},
    {"title": "Seeking Knowledge", "arabic": "رَّبِّ زِدْنِي عِلْمًا"},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: doas.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doas[index]['title']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Text(
                  doas[index]['arabic']!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 22, height: 1.5, fontFamily: 'Arabic'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}