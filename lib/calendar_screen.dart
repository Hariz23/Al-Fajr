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
  String selectedState = "All"; 

  final List<String> malaysianStates = [
    "All", "Johor", "Kedah", "Kelantan", "Melaka", "Negeri Sembilan", 
    "Pahang", "Perak", "Perlis", "Pulau Pinang", "Sabah", "Sarawak", 
    "Selangor", "Terengganu", "W.P. Kuala Lumpur", "W.P. Labuan", "W.P. Putrajaya"
  ];

  // --- SMART LINK LAUNCHER ---
  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;

    String trimmedUrl = url.trim();

    // Fix: Add protocol if missing, otherwise launchUrl will fail
    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      trimmedUrl = 'https://$trimmedUrl';
    }

    final Uri uri = Uri.parse(trimmedUrl);

    try {
      // Launch in external application (Browser/YouTube app)
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $trimmedUrl");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid link or no browser found.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Launch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    // Dynamic Query
    Query query = FirebaseFirestore.instance.collection('events');
    
    if (selectedState != "All") {
      query = query.where('state', isEqualTo: selectedState);
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
          SliverToBoxAdapter(child: _buildFilterBar(lang)),

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
                return const SliverFillRemaining(child: Center(child: Text("Error loading events")));
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

                      // Null-safe Date Parsing
                      final dynamic rawDate = data['eventDate'] ?? data['date'];
                      DateTime eventDate = (rawDate is Timestamp) ? rawDate.toDate() : DateTime.now();

                      // Reverted field names from original schema
                      String title = data['title'] ?? "No Title";
                      String location = data['locationName'] ?? data['masjidName'] ?? "Unknown Location";
                      String link = data['liveLink'] ?? data['link'] ?? "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen,
                            child: const Icon(Icons.mosque, color: Colors.white, size: 20),
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
                          onTap: link.isNotEmpty ? () => _launchURL(link) : null,
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

  Widget _buildFilterBar(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: malaysianStates.map((stateName) {
            bool isSelected = selectedState == stateName;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(stateName),
                selected: isSelected,
                selectedColor: AppTheme.primaryGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) => setState(() => selectedState = stateName),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}