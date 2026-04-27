import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class Reciter {
  final String name;
  final String id; // e.g., 'ar.alafasy'

  Reciter({required this.name, required this.id});
}

class QuranAudioService {
  final AudioPlayer _player = AudioPlayer();
  
  // Default to Mishary Rashid Alafasy (Popular in Malaysia)
  Reciter _selectedReciter = Reciter(name: "Mishary Alafasy", id: "ar.alafasy");

  Reciter get selectedReciter => _selectedReciter;

  void updateReciter(Reciter newReciter) {
    _selectedReciter = newReciter;
  }

  // globalAyahNumber is 1 to 6236
  Future<void> playAyah(int globalAyahNumber, String surahName, int ayahInSurah) async {
    final url = "https://cdn.islamic.network/quran/audio/128/${_selectedReciter.id}/$globalAyahNumber.mp3";
    
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '$globalAyahNumber',
            album: "Surah $surahName",
            title: "Ayat $ayahInSurah",
            artUri: Uri.parse("https://your-app-logo-url.png"),
          ),
        ),
      );
      _player.play();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void pause() => _player.pause();
  void stop() => _player.stop();
  
  Stream<PlayerState> get stateStream => _player.playerStateStream;
}