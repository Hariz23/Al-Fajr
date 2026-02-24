import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  Future<List<dynamic>> fetchSurahs() async {
    final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load Quran');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Al-Quran")),
      body: FutureBuilder<List<dynamic>>(
        future: fetchSurahs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final surah = snapshot.data![index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text("${surah['number']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(surah['englishName']),
                subtitle: Text(surah['englishNameTranslation']),
                trailing: Text(surah['name'], style: const TextStyle(fontSize: 18)),
                onTap: () {
                  // Navigate to the detail page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahDetailView(
                        surahNumber: surah['number'],
                        surahName: surah['englishName'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// NEW: The screen that opens when you click a Surah
class SurahDetailView extends StatelessWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailView({super.key, required this.surahNumber, required this.surahName});

  Future<List<dynamic>> fetchAyahs() async {
    final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/$surahNumber'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data']['ayahs'];
    } else {
      throw Exception('Failed to load verses');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(surahName)),
      body: FutureBuilder<List<dynamic>>(
        future: fetchAyahs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final ayahs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ayahs.length + 1, // +1 for the Bismillah Header
            itemBuilder: (context, index) {
              // 1. Top Header: Bismillah (Except for Surah 9)
              if (index == 0) {
                if (surahNumber == 9 || surahNumber == 1) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                      style: TextStyle(fontSize: 28, fontFamily: 'Arabic', color: AppTheme.primaryGreen),
                    ),
                  ),
                );
              }

              // 2. The Verses
              final ayah = ayahs[index - 1];
              String text = ayah['text'];

              // Clean "Bismillah" from the start of the first verse if it's there
              if (surahNumber != 1 && index == 1) {
                text = text.replaceFirst("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "");
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.transparent : AppTheme.primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 22, height: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text("Verse ${ayah['numberInSurah']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                ],
              );
            },
          );
        },
      ),
    );
  }
}