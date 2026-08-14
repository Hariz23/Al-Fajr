import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A saved place in the Quran — either a bookmark or the last thing read.
class QuranMark {
  const QuranMark({
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    this.totalAyahs,
  });

  final int surahNumber;
  final String surahName;
  final int ayah;

  /// Known once the surah has been opened; drives the progress bar. Null when
  /// the count was never loaded, in which case callers hide the bar rather
  /// than guess at one.
  final int? totalAyahs;

  double? get progress {
    final total = totalAyahs;
    if (total == null || total <= 0) return null;
    return (ayah / total).clamp(0.0, 1.0);
  }

  String get reference => '$surahNumber:$ayah';

  Map<String, dynamic> toJson() => {
    'surah': surahNumber,
    'name': surahName,
    'ayah': ayah,
    if (totalAyahs != null) 'total': totalAyahs,
  };

  static QuranMark? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final surah = raw['surah'];
    final name = raw['name'];
    final ayah = raw['ayah'];
    if (surah is! int || name is! String || ayah is! int) return null;
    final total = raw['total'];
    return QuranMark(
      surahNumber: surah,
      surahName: name,
      ayah: ayah,
      totalAyahs: total is int ? total : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QuranMark &&
      other.surahNumber == surahNumber &&
      other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surahNumber, ayah);
}

/// Bookmarks and reading position, kept on the device.
///
/// Deliberately local rather than in Firestore: it is per-device reading
/// state, it must work offline, and it does not need to survive a reinstall.
class QuranLibrary {
  QuranLibrary._();

  static const _bookmarksKey = 'quran_bookmarks';
  static const _lastReadKey = 'quran_last_read';

  static Future<List<QuranMark>> bookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bookmarksKey) ?? const [];
    return raw
        .map((entry) {
          try {
            return QuranMark.fromJson(json.decode(entry));
          } catch (_) {
            return null;
          }
        })
        .whereType<QuranMark>()
        .toList();
  }

  static Future<bool> isBookmarked(int surahNumber, int ayah) async {
    final saved = await bookmarks();
    return saved.any((m) => m.surahNumber == surahNumber && m.ayah == ayah);
  }

  /// Adds the mark, or removes it when it is already saved. Returns the state
  /// the mark ended up in, so callers can report it.
  static Future<bool> toggleBookmark(QuranMark mark) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await bookmarks();
    final existed = saved.remove(mark);
    if (!existed) saved.add(mark);
    saved.sort((a, b) {
      final bySurah = a.surahNumber.compareTo(b.surahNumber);
      return bySurah != 0 ? bySurah : a.ayah.compareTo(b.ayah);
    });
    await prefs.setStringList(
      _bookmarksKey,
      saved.map((m) => json.encode(m.toJson())).toList(),
    );
    return !existed;
  }

  static Future<QuranMark?> lastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReadKey);
    if (raw == null) return null;
    try {
      return QuranMark.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastRead(QuranMark mark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReadKey, json.encode(mark.toJson()));
  }
}
