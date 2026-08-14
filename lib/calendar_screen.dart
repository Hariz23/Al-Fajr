import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islamic_hijri_calendar/islamic_hijri_calendar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _states = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'W.P. Kuala Lumpur',
    'W.P. Labuan',
    'W.P. Putrajaya',
  ];

  bool _filterExpanded = false;
  String _filterMode = 'State';
  String _selectedState = 'All';
  String _selectedMosque = 'All';
  List<String> _mosques = [];
  bool _loadingMosques = true;
  bool _mosqueLoadFailed = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToMosques();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToMosques() {
    _subscription?.cancel();
    setState(() {
      _loadingMosques = true;
      _mosqueLoadFailed = false;
    });
    _subscription = FirebaseFirestore.instance
        .collection('masjids')
        .snapshots()
        .listen(
          (snapshot) {
            final names =
                snapshot.docs
                    .map(
                      (document) => document.data()['name']?.toString().trim(),
                    )
                    .whereType<String>()
                    .where((name) => name.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
            if (!mounted) return;
            setState(() {
              _mosques = names;
              _loadingMosques = false;
              _mosqueLoadFailed = false;
              if (_selectedMosque != 'All' &&
                  !names.contains(_selectedMosque)) {
                _selectedMosque = 'All';
              }
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _loadingMosques = false;
              _mosqueLoadFailed = true;
            });
          },
        );
  }

  Query<Map<String, dynamic>> _eventQuery() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: startOfToday);
    if (_filterMode == 'State' && _selectedState != 'All') {
      query = query.where('state', isEqualTo: _selectedState);
    } else if (_filterMode == 'Mosque' && _selectedMosque != 'All') {
      query = query.where('locationName', isEqualTo: _selectedMosque);
    }
    return query.orderBy('eventDate');
  }

  Future<void> _launchUrl(String rawUrl, LanguageProvider lang) async {
    var normalized = rawUrl.trim();
    if (normalized.isEmpty) return;
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) {
      showAppMessage(
        context,
        lang.getText(
          'This event link is invalid.',
          'Pautan acara ini tidak sah.',
        ),
        isError: true,
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      showAppMessage(
        context,
        lang.getText(
          'The link could not be opened.',
          'Pautan tidak dapat dibuka.',
        ),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText('Community', 'Komuniti'),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
              ),
            ),
            Text(
              lang.getText(
                'Live and upcoming mosque events',
                'Acara masjid secara langsung dan akan datang',
              ),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          AppIconButton(
            icon: _filterExpanded
                ? CupertinoIcons.xmark
                : CupertinoIcons.slider_horizontal_3,
            label: lang.getText('Filter events', 'Tapis acara'),
            onPressed: () => setState(() => _filterExpanded = !_filterExpanded),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            sliver: SliverList.list(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  alignment: Alignment.topCenter,
                  child: _filterExpanded
                      ? _FilterPanel(
                          mode: _filterMode,
                          selectedState: _selectedState,
                          selectedMosque: _selectedMosque,
                          states: _states,
                          mosques: _mosques,
                          loadingMosques: _loadingMosques,
                          mosqueLoadFailed: _mosqueLoadFailed,
                          lang: lang,
                          onModeChanged: (value) => setState(() {
                            _filterMode = value;
                            _selectedState = 'All';
                            _selectedMosque = 'All';
                          }),
                          onFilterChanged: (value) => setState(() {
                            if (_filterMode == 'State') {
                              _selectedState = value;
                            } else {
                              _selectedMosque = value;
                            }
                          }),
                          onRetryMosques: _listenToMosques,
                        )
                      : const SizedBox.shrink(),
                ),
                if (_filterExpanded) const SizedBox(height: 14),
                AppSurface(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: ClipRRect(
                    borderRadius: AppTheme.borderRadiusSm,
                    child: Material(
                      color: AppTheme.surface,
                      child: IslamicHijriCalendar(
                        isHijriView: true,
                        highlightBorder: AppTheme.primaryGreen,
                        highlightTextColor: AppTheme.textOnPrimary,
                        defaultTextColor: AppTheme.textPrimary,
                        defaultBackColor: AppTheme.surface,
                        getSelectedEnglishDate: (_) {},
                      ),
                    ),
                  ),
                ),
                AppSectionTitle(
                  title: lang.getText('UPCOMING EVENTS', 'ACARA AKAN DATANG'),
                  action: _activeFilterLabel(lang),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _eventQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(34),
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 13),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: AppStateView(
                      icon: CupertinoIcons.exclamationmark_triangle,
                      title: lang.getText(
                        'Events are unavailable',
                        'Acara tidak tersedia',
                      ),
                      message: lang.getText(
                        'The event query could not be completed. Check the Firestore index and your connection.',
                        'Pertanyaan acara tidak dapat diselesaikan. Semak indeks Firestore dan sambungan anda.',
                      ),
                      actionLabel: lang.getText(
                        'Clear filters',
                        'Kosongkan tapisan',
                      ),
                      onAction: _clearFilters,
                    ),
                  ),
                );
              }

              final documents = snapshot.data?.docs ?? [];
              if (documents.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: AppStateView(
                      icon: CupertinoIcons.calendar_badge_plus,
                      title: lang.getText(
                        'No upcoming events',
                        'Tiada acara akan datang',
                      ),
                      message: lang.getText(
                        'Try another filter or check back when your mosque publishes a new event.',
                        'Cuba tapisan lain atau semak semula apabila masjid menerbitkan acara baharu.',
                      ),
                      actionLabel: _hasActiveFilter
                          ? lang.getText(
                              'Show all events',
                              'Tunjukkan semua acara',
                            )
                          : null,
                      onAction: _hasActiveFilter ? _clearFilters : null,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = documents[index].data();
                    final rawDate = data['eventDate'] ?? data['date'];
                    final eventDate = rawDate is Timestamp
                        ? rawDate.toDate()
                        : DateTime.now();
                    final link = (data['liveLink'] ?? data['link'] ?? '')
                        .toString();
                    return _EventCard(
                      title:
                          (data['title'] ??
                                  lang.getText(
                                    'Untitled event',
                                    'Acara tanpa tajuk',
                                  ))
                              .toString(),
                      location:
                          (data['locationName'] ?? data['masjidName'] ?? '')
                              .toString(),
                      state: (data['state'] ?? '').toString(),
                      description: (data['description'] ?? '').toString(),
                      date: eventDate,
                      hasLink: link.trim().isNotEmpty,
                      lang: lang,
                      onTap: link.trim().isEmpty
                          ? null
                          : () => _launchUrl(link, lang),
                    );
                  },
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  bool get _hasActiveFilter =>
      _selectedState != 'All' || _selectedMosque != 'All';

  void _clearFilters() => setState(() {
    _selectedState = 'All';
    _selectedMosque = 'All';
  });

  Widget? _activeFilterLabel(LanguageProvider lang) {
    if (!_hasActiveFilter) return null;
    final label = _filterMode == 'State' ? _selectedState : _selectedMosque;
    return GestureDetector(
      onTap: _clearFilters,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.mint,
          borderRadius: AppTheme.borderRadiusLg,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.mode,
    required this.selectedState,
    required this.selectedMosque,
    required this.states,
    required this.mosques,
    required this.loadingMosques,
    required this.mosqueLoadFailed,
    required this.lang,
    required this.onModeChanged,
    required this.onFilterChanged,
    required this.onRetryMosques,
  });

  final String mode;
  final String selectedState;
  final String selectedMosque;
  final List<String> states;
  final List<String> mosques;
  final bool loadingMosques;
  final bool mosqueLoadFailed;
  final LanguageProvider lang;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRetryMosques;

  @override
  Widget build(BuildContext context) {
    final selected = mode == 'State' ? selectedState : selectedMosque;
    final options = mode == 'State' ? states : mosques;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText('Filter events', 'Tapis acara'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: mode,
              children: {
                'State': Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(lang.getText('By state', 'Mengikut negeri')),
                ),
                'Mosque': Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(lang.getText('By mosque', 'Mengikut masjid')),
                ),
              },
              onValueChanged: (value) {
                if (value != null) onModeChanged(value);
              },
            ),
          ),
          const SizedBox(height: 14),
          if (mode == 'Mosque' && loadingMosques)
            const Center(child: CupertinoActivityIndicator())
          else if (mode == 'Mosque' && mosqueLoadFailed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    lang.getText(
                      'Mosques could not be loaded.',
                      'Senarai masjid tidak dapat dimuatkan.',
                    ),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: onRetryMosques,
                  child: Text(lang.getText('Retry', 'Cuba lagi')),
                ),
              ],
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(lang.getText('All', 'Semua'), 'All', selected),
                  for (final option in options) _chip(option, option, selected),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, String selected) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: value == selected,
      showCheckmark: false,
      onSelected: (_) => onFilterChanged(value),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.location,
    required this.state,
    required this.description,
    required this.date,
    required this.hasLink,
    required this.lang,
    required this.onTap,
  });

  final String title;
  final String location;
  final String state;
  final String description;
  final DateTime date;
  final bool hasLink;
  final LanguageProvider lang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: AppTheme.borderRadiusSm,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: AppTheme.borderRadiusSm,
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: const TextStyle(
                      color: AppTheme.primaryGreenDark,
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      location,
                      state,
                    ].where((value) => value.isNotEmpty).join(' • '),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('EEEE, h:mm a').format(date),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasLink)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  CupertinoIcons.arrow_up_right_square,
                  color: AppTheme.primaryGreen,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
