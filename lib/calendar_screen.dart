import 'package:flutter/material.dart';
import 'package:islamic_hijri_calendar/islamic_hijri_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  
  // Function to open the Live Link (YouTube/Zoom)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Calendar"),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. THE HIJRI CALENDAR (Visual Part)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: IslamicHijriCalendar(
              isHijriView: true,
              highlightBorder: AppTheme.primaryGreen,
              highlightTextColor: Colors.white,
              defaultTextColor: Colors.black,
              defaultBackColor: Colors.white,
              getSelectedEnglishDate: (date) {
                debugPrint("Selected: $date");
              },
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Live & Upcoming Events", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),

          // 2. THE DYNAMIC EVENT LIST (The "Real" Part)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Listening to your 'events' collection in Firestore
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('eventDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No events posted yet."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
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
                        title: Text(data['title'] ?? "No Title", 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${data['locationName']} • ${DateFormat('d MMM').format(eventDate)}"),
                            if (link.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextButton.icon(
                                  onPressed: () => _launchURL(link),
                                  icon: const Icon(Icons.videocam, size: 18, color: Colors.red),
                                  label: const Text("JOIN LIVE NOW", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}