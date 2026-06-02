import 'dart:async'; // Added for StreamSubscription
import 'package:flutter/material.dart';
import 'package:islamic_hijri_calendar/islamic_hijri_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isFilterExpanded = false;
  String _filterMode = "State"; 
  String selectedState = "All"; 
  String selectedMosque = "All";

  final List<String> malaysianStates = [
    "Johor", "Kedah", "Kelantan", "Melaka", "Negeri Sembilan", 
    "Pahang", "Perak", "Perlis", "Pulau Pinang", "Sabah", "Sarawak", 
    "Selangor", "Terengganu", "W.P. Kuala Lumpur", "W.P. Labuan", "W.P. Putrajaya"
  ];

  List<String> dynamicMosqueList = [];
  bool _isLoadingMosques = true;
  
  // 1. Added variable to hold the live stream subscription
  StreamSubscription<QuerySnapshot>? _mosqueSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMosqueList(); // 2. Call the new real-time listener
  }

  // 3. IMPORTANT: Cancel the stream when the screen is closed to prevent memory leaks
  @override
  void dispose() {
    _mosqueSubscription?.cancel();
    super.dispose();
  }

  // 4. Replaced one-time fetch with this real-time listener
  void _listenToMosqueList() {
    _mosqueSubscription = FirebaseFirestore.instance
        .collection('masjids')
        .snapshots()
        .listen((snap) {
      List<String> fetchedNames = [];
      for (var doc in snap.docs) {
        if (doc.data().containsKey('name') && doc['name'].toString().trim().isNotEmpty) {
          fetchedNames.add(doc['name']);
        }
      }
      fetchedNames.sort();
      
      if (mounted) {
        setState(() {
          dynamicMosqueList = fetchedNames;
          _isLoadingMosques = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() {
          _isLoadingMosques = false;
        });
      }
    });
  }

  Future<void> _launchURL(String url, LanguageProvider lang) async {
    if (url.isEmpty) {
      return;
    }
    String trimmedUrl = url.trim();
    if (!trimmedUrl.startsWith('http')) {
      trimmedUrl = 'https://$trimmedUrl';
    }
    final Uri uri = Uri.parse(trimmedUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Logic to hide past events
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    Query query = FirebaseFirestore.instance.collection('events');
    
    // Applying the auto-hide filter
    query = query.where('eventDate', isGreaterThanOrEqualTo: startOfToday);

    if (_filterMode == "State" && selectedState != "All") {
      query = query.where('state', isEqualTo: selectedState);
    } else if (_filterMode == "Mosque" && selectedMosque != "All") {
      query = query.where('locationName', isEqualTo: selectedMosque);
    }
    
    query = query.orderBy('eventDate', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Community Calendar", "Kalendar Komuniti")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCollapsibleFilterBar(lang)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IslamicHijriCalendar(
                isHijriView: true,
                highlightBorder: AppTheme.primaryGreen,
                highlightTextColor: Colors.white,
                defaultTextColor: Colors.black,
                defaultBackColor: Colors.white,
                getSelectedEnglishDate: (date) => debugPrint("Selected: $date"),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                lang.getText("Live & Upcoming Events", "Acara Langsung & Akan Datang"), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text("Error: Index required. Check console link.")),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(lang.getText("No events found.", "Tiada acara ditemui."))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      final dynamic rawDate = data['eventDate'] ?? data['date'];
                      DateTime eventDate = (rawDate is Timestamp) ? rawDate.toDate() : DateTime.now();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen,
                            child: Icon(Icons.mosque, color: Colors.white, size: 20),
                          ),
                          title: Text(data['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${data['locationName'] ?? ""} • ${DateFormat('d MMM').format(eventDate)}"),
                          onTap: () {
                            String link = data['liveLink'] ?? data['link'] ?? "";
                            if (link.isNotEmpty) {
                              _launchURL(link, lang);
                            }
                          },
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildCollapsibleFilterBar(LanguageProvider lang) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          ListTile(
            title: Text(
              lang.getText("Filter Events", "Tapis Acara"), 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            trailing: Icon(_isFilterExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Column(
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: "State", label: Text(lang.getText("By State", "Negeri"))),
                      ButtonSegment(value: "Mosque", label: Text(lang.getText("By Mosque", "Masjid"))),
                    ],
                    selected: {_filterMode},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _filterMode = newSelection.first;
                        selectedState = "All";
                        selectedMosque = "All";
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  if (_filterMode == "Mosque" && _isLoadingMosques) ...[
                    const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator())),
                  ] else ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          _buildFilterChip(lang.getText("All", "Semua"), "All"),
                          ...(_filterMode == "State" ? malaysianStates : dynamicMosqueList)
                              .map((name) => _buildFilterChip(name, name)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = (_filterMode == "State" ? selectedState : selectedMosque) == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen,
        onSelected: (val) {
          setState(() {
            if (_filterMode == "State") {
              selectedState = value;
            } else {
              selectedMosque = value;
            }
          });
        },
      ),
    );
  }
}