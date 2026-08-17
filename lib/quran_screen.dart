import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'juz_data.dart';
import 'quran_library.dart';
import 'surah_data.dart';
import 'theme.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late Future<List<dynamic>> _surahsFuture;
  
  // 1. Added TextEditingController and SpeechToText variables
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  String _searchQuery = '';
  int _selectedSegment = 0;

  static const _fallbackSurahs = <Map<String, dynamic>>[
    {
      'number': 1,
      'name': 'سُورَةُ ٱلْفَاتِحَةِ',
      'englishName': 'Al-Fatihah',
      'englishNameTranslation': 'The Opening',
      'revelationType': 'Meccan',
      'numberOfAyahs': 7,
    },
    {
      'number': 2,
      'name': 'سُورَةُ البَقَرَةِ',
      'englishName': 'Al-Baqarah',
      'englishNameTranslation': 'The Cow',
      'revelationType': 'Medinan',
      'numberOfAyahs': 286,
    },
    {
      'number': 3,
      'name': 'سُورَةُ آلِ عِمۡرَانَ',
      'englishName': 'Aal-E-Imran',
      'englishNameTranslation': 'The Family of Imran',
      'revelationType': 'Medinan',
      'numberOfAyahs': 200,
    },
    {
      'number': 4,
      'name': 'سُورَةُ النِّسَاءِ',
      'englishName': 'An-Nisa',
      'englishNameTranslation': 'The Women',
      'revelationType': 'Medinan',
      'numberOfAyahs': 176,
    },
    {
      'number': 5,
      'name': 'سُورَةُ المَائـِدَةِ',
      'englishName': 'Al-Ma’idah',
      'englishNameTranslation': 'The Table Spread',
      'revelationType': 'Medinan',
      'numberOfAyahs': 120,
    },
    {
      'number': 6,
      'name': 'سُورَةُ الأَنۡعَامِ',
      'englishName': 'Al-An’am',
      'englishNameTranslation': 'The Cattle',
      'revelationType': 'Meccan',
      'numberOfAyahs': 165,
    },
  ];

  QuranMark? _lastRead;
  List<QuranMark> _bookmarks = const [];
  List<dynamic> _loadedSurahs = const [];

  @override
  void initState() {
    super.initState();
    _surahsFuture = _fetchSurahs();
    _loadLibrary();
    _initSpeech(); // Initialize speech on load
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 2. Extracted Speech Methods
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      final words = result.recognizedWords;
      _searchController.text = words; // Show text in the search bar
      _searchQuery = words.trim().toLowerCase(); // Trigger the search filter
    });
  }

  String _surahNameFor(int number) {
    for (final item in _loadedSurahs) {
      if (item is Map && item['number'] == number) {
        return item['englishName'].toString();
      }
    }
    return 'Surah $number';
  }

  Future<void> _loadLibrary() async {
    final last = await QuranLibrary.lastRead();
    final saved = await QuranLibrary.bookmarks();
    if (!mounted) return;
    setState(() {
      _lastRead = last;
      _bookmarks = saved;
    });
  }

  Future<void> _openSurah(int number, String name) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahDetailView(surahNumber: number, surahName: name),
      ),
    );
    await _loadLibrary();
  }

  Future<List<dynamic>> _fetchSurahs() async {
    final response = await http.get(
      Uri.parse('https://api.alquran.cloud/v1/surah'),
    );
    if (response.statusCode == 200) return json.decode(response.body)['data'];
    throw Exception('Failed to load Quran');
  }

  void _retry() => setState(() => _surahsFuture = _fetchSurahs());

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgSoftWhite,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang.getText('Al-Quran', 'Al-Quran'),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                        _RoundAction(
                          icon: _selectedSegment == 2
                              ? CupertinoIcons.bookmark_fill
                              : CupertinoIcons.bookmark,
                          onTap: () => setState(() => _selectedSegment = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.getText(
                        'Read, listen and reflect',
                        'Baca, dengar dan renungkan',
                      ),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 3. Updated Search Widget integration
                    _QuranSearch(
                      controller: _searchController,
                      isListening: _speechToText.isListening,
                      onMicPressed: () {
                        if (!_speechEnabled) {
                           showAppMessage(context, "Microphone permission denied", isError: true);
                           return;
                        }
                        if (_speechToText.isNotListening) {
                          _startListening();
                        } else {
                          _stopListening();
                        }
                      },
                      onChanged: (value) => setState(
                        () => _searchQuery = value.trim().toLowerCase(),
                      ),
                    ),
                    
                    const SizedBox(height: 18),
                    _ContinueReadingCard(
                      mark: _lastRead,
                      onTap: () {
                        final mark = _lastRead;
                        _openSurah(
                          mark?.surahNumber ?? 1,
                          mark?.surahName ?? 'Al-Fatihah',
                        );
                      },
                    ),
                    const SizedBox(height: 21),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<int>(
                        groupValue: _selectedSegment,
                        thumbColor: AppTheme.surface,
                        backgroundColor: const Color(0xFFE8ECEA),
                        padding: const EdgeInsets.all(3),
                        children: const {
                          0: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Surahs'),
                          ),
                          1: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Juz'),
                          ),
                          2: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Bookmarks'),
                          ),
                        },
                        onValueChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedSegment = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _selectedSegment == 0
                          ? '114 Surahs'
                          : (_selectedSegment == 1 ? '30 Juz' : 'Saved verses'),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (_selectedSegment == 0)
              FutureBuilder<List<dynamic>>(
                future: _surahsFuture,
                initialData: _fallbackSurahs,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _QuranError(onRetry: _retry),
                    );
                  }

                  _loadedSurahs = snapshot.data!;
                  final surahs = snapshot.data!.where((item) {
                    if (_searchQuery.isEmpty) return true;
                    final englishName = item['englishName']
                        .toString()
                        .toLowerCase();
                    final translation = item['englishNameTranslation']
                        .toString()
                        .toLowerCase();
                    final number = item['number'].toString();
                    return englishName.contains(_searchQuery) ||
                        translation.contains(_searchQuery) ||
                        number == _searchQuery;
                  }).toList();

                  if (surahs.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No surah found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    sliver: SliverList.separated(
                      itemCount: surahs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final surah = surahs[index] as Map<String, dynamic>;
                        return _SurahRow(
                          surah: surah,
                          subtitle: lang.isEnglish
                              ? surah['englishNameTranslation']
                              : SurahData.malayNames[surah['number']] ??
                                    'Terjemahan',
                          onTap: () => _openSurah(
                            surah['number'] as int,
                            surah['englishName'] as String,
                          ),
                        );
                      },
                    ),
                  );
                },
              )
            else if (_selectedSegment == 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList.separated(
                  itemCount: JuzStart.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final juz = JuzStart.all[index];
                    return _JuzRow(
                      juz: juz,
                      surahName: _surahNameFor(juz.surahNumber),
                      onTap: () => _openSurah(
                        juz.surahNumber,
                        _surahNameFor(juz.surahNumber),
                      ),
                    );
                  },
                ),
              )
            else if (_bookmarks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _QuranEmptyState(isBookmarks: true),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList.separated(
                  itemCount: _bookmarks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final mark = _bookmarks[index];
                    return _BookmarkRow(
                      mark: mark,
                      onTap: () => _openSurah(mark.surahNumber, mark.surahName),
                      onRemove: () async {
                        await QuranLibrary.toggleBookmark(mark);
                        await _loadLibrary();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundAction({required this.icon, required this.onTap});

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
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
      ),
    );
  }
}

// 4. Updated _QuranSearch to receive the controller and mic actions
class _QuranSearch extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  final VoidCallback onMicPressed;
  final bool isListening;

  const _QuranSearch({
    required this.onChanged,
    required this.controller,
    required this.onMicPressed,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: CupertinoTextField(
        controller: controller, // Bound to the speech controller
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: null,
        placeholder: 'Search surah or verse',
        placeholderStyle: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 14),
          child: Icon(
            CupertinoIcons.search,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ),
        suffix: CupertinoButton(
          padding: const EdgeInsets.only(right: 14),
          minSize: 0,
          onPressed: onMicPressed,
          child: Icon(
            // Change icon to show recording state
            isListening ? CupertinoIcons.stop_circle_fill : CupertinoIcons.mic_fill,
            size: 20,
            color: isListening ? Colors.redAccent : AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  final VoidCallback onTap;
  final QuranMark? mark;

  const _ContinueReadingCard({required this.onTap, this.mark});

  double? get progress => mark?.progress;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        height: 142,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF075D43), Color(0xFF0E7A58)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -46,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                    width: 24,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 25,
              top: 27,
              child: Text(
                'ٱقْرَأْ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.book_fill,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'CONTINUE READING',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.05,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    mark?.surahName ?? 'Al-Fatihah',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mark == null
                        ? 'Start from the beginning'
                        : 'Ayah ${mark!.ayah}'
                              '${progress == null ? '' : '  ·  ${(progress! * 100).round()}% complete'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.67),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 145,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress ?? 0,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentGold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final Map<String, dynamic> surah;
  final String subtitle;
  final VoidCallback onTap;

  const _SurahRow({
    required this.surah,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppTheme.mint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${surah['number']}',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah['englishName'],
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah['revelationType']}  ·  ${surah['numberOfAyahs']} verses',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    surah['name'],
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahAudioButton extends StatelessWidget {
  const _AyahAudioButton({
    required this.isLoading,
    required this.isPlaying,
    required this.positionStream,
    required this.duration,
    required this.onTap,
  });

  final bool isLoading;
  final bool isPlaying;
  final Stream<Duration> positionStream;
  final Duration? duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(38, 38),
      onPressed: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isPlaying)
              StreamBuilder<Duration>(
                stream: positionStream,
                builder: (context, snapshot) {
                  final total = duration?.inMilliseconds ?? 0;
                  final played = snapshot.data?.inMilliseconds ?? 0;
                  return SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: total <= 0 ? null : (played / total).clamp(0.0, 1.0),
                      strokeWidth: 2,
                      backgroundColor: AppTheme.mintStrong,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primaryGreen,
                      ),
                    ),
                  );
                },
              ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CupertinoActivityIndicator(
                        radius: 9,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      key: ValueKey(isPlaying),
                      color: AppTheme.primaryGreen,
                      size: isPlaying ? 14 : 17,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JuzRow extends StatelessWidget {
  const _JuzRow({
    required this.juz,
    required this.surahName,
    required this.onTap,
  });

  final JuzStart juz;
  final String surahName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '${juz.juz}',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Juz ${juz.juz}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Begins at $surahName ${juz.surahNumber}:${juz.ayah}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({
    required this.mark,
    required this.onTap,
    required this.onRemove,
  });

  final QuranMark mark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 14,
              ),
              onPressed: onTap,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.bookmark_fill,
                    size: 19,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mark.surahName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ayah ${mark.ayah}  ·  ${mark.reference}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(44, 44),
            onPressed: onRemove,
            child: const Icon(
              CupertinoIcons.delete,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranEmptyState extends StatelessWidget {
  final bool isBookmarks;

  const _QuranEmptyState({this.isBookmarks = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBookmarks
                ? CupertinoIcons.bookmark
                : CupertinoIcons.square_grid_2x2,
            size: 36,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          Text(
            'No saved verses yet',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tap the bookmark on any verse to keep it here.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _QuranError extends StatelessWidget {
  final VoidCallback onRetry;

  const _QuranError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.book_circle,
            size: 38,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load the Quran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 15),
          CupertinoButton.filled(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class SurahDetailView extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailView({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingAyahIndex;
  int? _loadingAyahIndex;

  Future<Map<String, dynamic>>? _ayahsFuture;
  bool? _loadedInEnglish;

  Future<Map<String, dynamic>> _ayahsFor(bool isEnglish) {
    if (_loadedInEnglish != isEnglish || _ayahsFuture == null) {
      _loadedInEnglish = isEnglish;
      _ayahsFuture = _fetchAyahs(isEnglish);
    }
    return _ayahsFuture!;
  }
  Set<int> _bookmarked = {};
  int? _totalAyahs;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingAyahIndex = null;
          _loadingAyahIndex = null;
        });
      } else if (!state.playing && _playingAyahIndex != null) {
        setState(() => _playingAyahIndex = null);
      }
    });
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final saved = await QuranLibrary.bookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarked = saved
          .where((m) => m.surahNumber == widget.surahNumber)
          .map((m) => m.ayah)
          .toSet();
    });
  }

  QuranMark _markFor(int ayah) => QuranMark(
    surahNumber: widget.surahNumber,
    surahName: widget.surahName,
    ayah: ayah,
    totalAyahs: _totalAyahs,
  );

  void _rememberPosition(int ayah) {
    QuranLibrary.setLastRead(_markFor(ayah));
  }

  Future<void> _toggleBookmark(int ayah) async {
    final nowSaved = await QuranLibrary.toggleBookmark(_markFor(ayah));
    _rememberPosition(ayah);
    if (!mounted) return;
    setState(() {
      if (nowSaved) {
        _bookmarked.add(ayah);
      } else {
        _bookmarked.remove(ayah);
      }
    });
    showAppMessage(
      context,
      nowSaved
          ? 'Saved ${widget.surahName} ${'$ayah'}'
          : 'Removed ${widget.surahName} ${'$ayah'}',
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchAyahs(bool isEnglish) async {
    final edition = isEnglish ? 'en.asad' : 'ms.basmeih';
    final response = await http.get(
      Uri.parse(
        'https://api.alquran.cloud/v1/surah/${widget.surahNumber}/editions/quran-uthmani,$edition',
      ),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load verses');
  }

  Future<void> _playAudio(int globalAyahNumber, int index) async {
    try {
      if (_playingAyahIndex == index && _audioPlayer.playing) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _playingAyahIndex = null);
        return;
      }
      if (_loadingAyahIndex == index) return;

      setState(() {
        _loadingAyahIndex = index;
        _playingAyahIndex = null;
      });
      await _audioPlayer.setUrl(
        'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyahNumber.mp3',
      );
      if (!mounted || _loadingAyahIndex != index) return;
      setState(() {
        _loadingAyahIndex = null;
        _playingAyahIndex = index;
      });
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _playingAyahIndex = null;
        _loadingAyahIndex = null;
      });
      showAppMessage(context, 'Audio currently unavailable.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgSoftWhite,
      appBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.bgSoftWhite.withValues(alpha: 0.94),
        border: const Border(
          bottom: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
        middle: Text(
          widget.surahName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: const Icon(
          CupertinoIcons.headphones,
          size: 19,
          color: AppTheme.primaryGreen,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ayahsFor(lang.isEnglish),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
                color: AppTheme.primaryGreen,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Unable to load verses'));
          }

          final arabicAyahs =
              snapshot.data!['data'][0]['ayahs'] as List<dynamic>;
          final translatedAyahs =
              snapshot.data!['data'][1]['ayahs'] as List<dynamic>;

          if (_totalAyahs != arabicAyahs.length) {
            _totalAyahs = arabicAyahs.length;
            _rememberPosition(1);
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            itemCount: arabicAyahs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (widget.surahNumber == 9 || widget.surahNumber == 1) {
                  return const SizedBox(height: 8);
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Text(
                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 25,
                      color: AppTheme.primaryGreen,
                      height: 1.6,
                    ),
                  ),
                );
              }

              final arabic = arabicAyahs[index - 1] as Map<String, dynamic>;
              final translation =
                  translatedAyahs[index - 1] as Map<String, dynamic>;
              var arabicText = arabic['text'] as String;
              if (widget.surahNumber != 1 && index == 1) {
                arabicText = arabicText.replaceFirst(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  '',
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${arabic['numberInSurah']}',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(34, 34),
                          onPressed: () =>
                              _toggleBookmark(arabic['numberInSurah'] as int),
                          child: Icon(
                            _bookmarked.contains(arabic['numberInSurah'])
                                ? CupertinoIcons.bookmark_fill
                                : CupertinoIcons.bookmark,
                            color: AppTheme.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _AyahAudioButton(
                          isLoading: _loadingAyahIndex == index,
                          isPlaying: _playingAyahIndex == index,
                          positionStream: _audioPlayer.positionStream,
                          duration: _audioPlayer.duration,
                          onTap: () {
                            _rememberPosition(
                              arabic['numberInSurah'] as int,
                            );
                            _playAudio(arabic['number'], index);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      arabicText,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.9,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppTheme.divider),
                    const SizedBox(height: 14),
                    Text(
                      translation['text'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}