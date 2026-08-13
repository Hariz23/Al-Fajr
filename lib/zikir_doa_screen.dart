import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class ZikirDoaScreen extends StatefulWidget {
  const ZikirDoaScreen({super.key});

  @override
  State<ZikirDoaScreen> createState() => _ZikirDoaScreenState();
}

class _ZikirDoaScreenState extends State<ZikirDoaScreen> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppPage(
      title: lang.getText('Dhikr & Dua', 'Zikir & Doa'),
      subtitle: lang.getText(
        'A quiet space for daily remembrance',
        'Ruang tenang untuk ingatan harian',
      ),
      showBackButton: true,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedSection,
              thumbColor: AppTheme.surface,
              backgroundColor: AppTheme.surfaceMuted,
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(lang.getText('Counter', 'Kaunter')),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(lang.getText('Daily dua', 'Doa harian')),
                ),
              },
              onValueChanged: (value) {
                if (value == null) return;
                HapticFeedback.selectionClick();
                setState(() => _selectedSection = value);
              },
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedSection == 0
                ? const _DhikrCounter(key: ValueKey('counter'))
                : _DuaList(key: const ValueKey('dua'), lang: lang),
          ),
        ],
      ),
    );
  }
}

class _DhikrCounter extends StatefulWidget {
  const _DhikrCounter({super.key});

  @override
  State<_DhikrCounter> createState() => _DhikrCounterState();
}

class _DhikrCounterState extends State<_DhikrCounter> {
  int _count = 0;
  int _target = 33;

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() => _count++);
    if (_count % _target == 0) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final progress = (_count.remainder(_target) / _target).clamp(0.0, 1.0);
    return Column(
      children: [
        AppSurface(
          color: AppTheme.primaryGreenDark,
          borderColor: AppTheme.primaryGreenDark,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: Column(
            children: [
              Text(
                lang.getText('CURRENT ROUND', 'PUSINGAN SEMASA'),
                style: TextStyle(
                  color: AppTheme.textOnPrimary.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_count',
                semanticsLabel: lang.getText(
                  'Dhikr count $_count',
                  'Kiraan zikir $_count',
                ),
                style: const TextStyle(
                  color: AppTheme.textOnPrimary,
                  fontSize: 76,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: AppTheme.borderRadiusLg,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: AppTheme.accentGold,
                  backgroundColor: AppTheme.textOnPrimary.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lang.getText(
                  'Target $_target • ${_count ~/ _target} completed rounds',
                  'Sasaran $_target • ${_count ~/ _target} pusingan selesai',
                ),
                style: TextStyle(
                  color: AppTheme.textOnPrimary.withValues(alpha: 0.78),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppSurface(
          child: Column(
            children: [
              Text(
                lang.getText(
                  'Tap gently with each remembrance',
                  'Ketik perlahan bagi setiap zikir',
                ),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: lang.getText('Add one dhikr', 'Tambah satu zikir'),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(168, 168),
                  onPressed: _increment,
                  child: Container(
                    width: 168,
                    height: 168,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentGold, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.hand_point_right_fill,
                          color: AppTheme.textOnPrimary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.getText('TAP', 'KETIK'),
                          style: const TextStyle(
                            color: AppTheme.textOnPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _target,
                      children: const {
                        33: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('33'),
                        ),
                        100: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('100'),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) setState(() => _target = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppIconButton(
                    icon: CupertinoIcons.refresh,
                    label: lang.getText(
                      'Reset counter',
                      'Tetapkan semula kaunter',
                    ),
                    onPressed: _count == 0
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _count = 0);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DuaList extends StatelessWidget {
  const _DuaList({super.key, required this.lang});

  final LanguageProvider lang;

  static const _doas = [
    (
      en: 'Morning remembrance',
      ms: 'Zikir pagi',
      arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
    ),
    (
      en: 'Before sleeping',
      ms: 'Sebelum tidur',
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    ),
    (
      en: 'For parents',
      ms: 'Untuk ibu bapa',
      arabic: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    ),
    (
      en: 'Seeking knowledge',
      ms: 'Memohon ilmu',
      arabic: 'رَّبِّ زِدْنِي عِلْمًا',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final dua in _doas) ...[
          AppSurface(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lang.getText(dua.en, dua.ms),
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: dua.arabic),
                        );
                        if (context.mounted) {
                          showAppMessage(
                            context,
                            lang.getText('Dua copied.', 'Doa disalin.'),
                          );
                        }
                      },
                      child: const Icon(
                        CupertinoIcons.doc_on_doc,
                        color: AppTheme.textSecondary,
                        size: 19,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    dua.arabic,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 25,
                      height: 1.75,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
