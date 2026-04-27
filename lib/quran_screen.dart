import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart'; // Ensure this is in pubspec.yaml
import 'language_provider.dart';
import 'surah_data.dart'; 
import 'theme.dart';

// --- RECITER MODEL ---
class Reciter {
  final String name;
  final String id;
  Reciter({required this.name, required this.id});
}

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

// --- SURAH DETAIL VIEW WITH AUDIO ---
class SurahDetailView extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailView({super.key, required this.surahNumber, required this.surahName});

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Malaysian Recommended Reciters
  final List<Reciter> _reciters = [
    Reciter(name: "Mishary Alafasy", id: "ar.alafasy"),
    Reciter(name: "Abdullah Al-Matrood", id: "ar.almatrood"),
    Reciter(name: "Saad Al-Ghamdi", id: "ar.saadghamidi"),
    Reciter(name: "Maher Al-Muaiqly", id: "ar.mahermuaiqly"),
  ];

  late Reciter _selectedReciter;
  int? _playingAyahIndex;

  @override
  void initState() {
    super.initState();
    _selectedReciter = _reciters[0];
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchAyahs(bool isEnglish) async {
    final edition = isEnglish ? "en.asad" : "ms.basmeih";
    final url = 'https://api.alquran.cloud/v1/surah/${widget.surahNumber}/editions/quran-uthmani,$edition';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load verses');
    }
  }

  Future<void> _playAudio(int globalAyahNumber, int index) async {
    try {
      setState(() => _playingAyahIndex = index);
      final url = "https://cdn.islamic.network/quran/audio/128/${_selectedReciter.id}/$globalAyahNumber.mp3";
      await _audioPlayer.setUrl(url);
      _audioPlayer.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Audio Error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surahName),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // RECITER SELECTION DROPDOWN
          DropdownButton<Reciter>(
            underline: const SizedBox(),
            icon: const Icon(Icons.mic, color: Colors.white),
            onChanged: (Reciter? newValue) {
              setState(() {
                _selectedReciter = newValue!;
              });
            },
            items: _reciters.map<DropdownMenuItem<Reciter>>((Reciter value) {
              return DropdownMenuItem<Reciter>(
                value: value,
                child: Text(value.name, style: const TextStyle(color: Colors.black)),
              );
            }).toList(),
          ),
          const SizedBox(width: 10),
        ],
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
              if (index == 0) {
                if (widget.surahNumber == 9 || widget.surahNumber == 1) return const SizedBox.shrink();
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

              if (widget.surahNumber != 1 && index == 1) {
                arabicText = arabicText.replaceFirst("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "");
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.transparent : AppTheme.primaryGreen.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Verse Action Bar (Play Button)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[200],
                              child: Text("${arabic['numberInSurah']}", style: const TextStyle(fontSize: 10, color: Colors.black)),
                            ),
                            IconButton(
                              icon: Icon(
                                _playingAyahIndex == index ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                color: AppTheme.primaryGreen,
                              ),
                              onPressed: () => _playAudio(arabic['number'], index),
                            ),
                          ],
                        ),
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