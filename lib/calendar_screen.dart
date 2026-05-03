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

  // Removed "All" from the list to handle it dynamically in the UI
  final List<String> malaysianStates = [
    "Johor", "Kedah", "Kelantan", "Melaka", "Negeri Sembilan", 
    "Pahang", "Perak", "Perlis", "Pulau Pinang", "Sabah", "Sarawak", 
    "Selangor", "Terengganu", "W.P. Kuala Lumpur", "W.P. Labuan", "W.P. Putrajaya"
  ];

  List<String> dynamicMosqueList = [];
  bool _isLoadingMosques = true;

  @override
  void initState() {
    super.initState();
    _fetchMosqueList();
  }

  Future<void> _fetchMosqueList() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('masjids').get();
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
    } catch (e) {
      debugPrint("Error fetching mosque list: $e");
      if (mounted) {
        setState(() => _isLoadingMosques = false);
      }
    }
  }

  Future<void> _launchURL(String url, LanguageProvider lang) async {
    if (url.isEmpty) return;
    String trimmedUrl = url.trim();

    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      trimmedUrl = 'https://$trimmedUrl';
    }

    final Uri uri = Uri.parse(trimmedUrl);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(lang.getText(
              "Invalid link or no browser found.", 
              "Pautan tidak sah atau tiada pelayar ditemui."
            ))),
          );
        }
      }
    } catch (e) {
      debugPrint("Launch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    Query query = FirebaseFirestore.instance.collection('events');
    
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
                return SliverFillRemaining(
                  child: Center(child: Text(lang.getText(
                    "Error loading events", 
                    "Ralat memuatkan acara"
                  )))
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

                      String title = data['title'] ?? lang.getText("No Title", "Tiada Tajuk");
                      String location = data['locationName'] ?? lang.getText("Unknown Location", "Lokasi Tidak Diketahui");
                      String link = data['liveLink'] ?? data['link'] ?? "";

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
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$location • ${DateFormat('d MMM').format(eventDate)}"),
                              if (link.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.videocam, size: 16, color: Colors.red),
                                      const SizedBox(width: 5),
                                      Text(
                                        lang.getText("JOIN LIVE", "SERTAI SEKARANG"), 
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          onTap: link.isNotEmpty ? () => _launchURL(link, lang) : null,
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
    String allText = lang.getText("All", "Semua");

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          ListTile(
            title: Text(
              lang.getText("Filter Events", "Tapis Acara"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Icon(_isFilterExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
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

                  if (_filterMode == "Mosque" && _isLoadingMosques)
                    const Center(child: CircularProgressIndicator())
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          // Explicit "All" chip with dynamic translation
                          _buildFilterChip(allText, "All", lang),
                          
                          ...(_filterMode == "State" ? malaysianStates : dynamicMosqueList)
                              .map((name) => _buildFilterChip(name, name, lang)),
                        ],
                      ),
                    ),
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

  Widget _buildFilterChip(String label, String value, LanguageProvider lang) {
    bool isSelected = (_filterMode == "State" ? selectedState : selectedMosque) == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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