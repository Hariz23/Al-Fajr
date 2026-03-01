import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'surah_data.dart'; // Import the new data file
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
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Al-Quran", "Al-Quran")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchSurahs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          return ListView.separated(
            itemCount: snapshot.data!.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final surah = snapshot.data![index];
              final int number = surah['number'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text("$number", style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
                title: Text(surah['englishName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                // DUO-LANGUAGE SUBTITLE LOGIC
                subtitle: Text(
                  lang.isEnglish 
                      ? surah['englishNameTranslation'] 
                      : SurahData.malayNames[number] ?? "Terjemahan",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                trailing: Text(surah['name'], style: const TextStyle(fontSize: 20, fontFamily: 'Arabic')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahDetailView(
                        surahNumber: number,
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

class SurahDetailView extends StatelessWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailView({super.key, required this.surahNumber, required this.surahName});

  Future<Map<String, dynamic>> fetchAyahs(bool isEnglish) async {
    // Uses English (Asad) or Malay (Basmeih)
    final edition = isEnglish ? "en.asad" : "ms.basmeih";
    final url = 'https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,$edition';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load verses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(surahName),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchAyahs(lang.isEnglish),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          
          final arabicAyahs = snapshot.data!['data'][0]['ayahs'];
          final translatedAyahs = snapshot.data!['data'][1]['ayahs'];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: arabicAyahs.length + 1,
            itemBuilder: (context, index) {
              // Bismillah Header
              if (index == 0) {
                if (surahNumber == 9 || surahNumber == 1) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 25),
                  child: Center(
                    child: Text(
                      "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                      style: TextStyle(fontSize: 30, color: AppTheme.primaryGreen),
                    ),
                  ),
                );
              }

              final arabic = arabicAyahs[index - 1];
              final translation = translatedAyahs[index - 1];
              String arabicText = arabic['text'];

              // Clean Bismillah prefix if present
              if (surahNumber != 1 && index == 1) {
                arabicText = arabicText.replaceFirst("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "");
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.transparent : AppTheme.primaryGreen.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arabicText,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 26, height: 2, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            translation['text'],
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      "${lang.getText("Verse", "Ayat")} ${arabic['numberInSurah']}", 
                      style: const TextStyle(color: Colors.grey, fontSize: 11)
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}