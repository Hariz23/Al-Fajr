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
  String? selectedMasjid;

  final List<String> malaysianStates = [
    "All", "Johor", "Kedah", "Kelantan", "Melaka", "Negeri Sembilan", 
    "Pahang", "Perak", "Perlis", "Pulau Pinang", "Sabah", "Sarawak", 
    "Selangor", "Terengganu", "W.P. Kuala Lumpur", "W.P. Labuan", "W.P. Putrajaya"
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    // Dynamic Query
    Query query = FirebaseFirestore.instance.collection('events');
    if (selectedState != "All") query = query.where('state', isEqualTo: selectedState);
    if (selectedMasjid != null) query = query.where('locationName', isEqualTo: selectedMasjid);
    query = query.orderBy('eventDate', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Community Calendar", "Kalendar Komuniti")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Sticky Filter Bar (stays at the top while scrolling)
          SliverToBoxAdapter(child: _buildFilterBar(lang)),

          // 2. Hijri Calendar Section
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

          // 3. Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                lang.getText("Live & Upcoming Events", "Acara Langsung & Akan Datang"), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ),

          // 4. Event List (SliverStreamBuilder)
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

              // Use SliverList so it works within the CustomScrollView
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      DateTime eventDate = (data['eventDate'] as Timestamp).toDate();
                      String link = data['liveLink'] ?? "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: data['venueType'] == 'Masjid' ? AppTheme.primaryGreen : Colors.orange,
                            child: Icon(
                              data['venueType'] == 'Masjid' ? Icons.mosque : Icons.house,
                              color: Colors.white, size: 20,
                            ),
                          ),
                          title: Text(data['title'] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${data['locationName']} • ${DateFormat('d MMM').format(eventDate)}"),
                              if (link.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _launchURL(link),
                                  icon: const Icon(Icons.videocam, size: 18, color: Colors.red),
                                  label: Text(lang.getText("JOIN LIVE NOW", "SERTAI SEKARANG"), 
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          
          // Add some bottom padding so the last item isn't cut off
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

Widget _buildFilterBar(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      color: Colors.grey[100],
      child: Column(
        children: [
          SingleChildScrollView(
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
                    // --- FIX IS HERE ---
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    // -------------------
                    onSelected: (val) => setState(() {
                      selectedState = stateName;
                      selectedMasjid = null;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
          if (selectedState != "All")
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}