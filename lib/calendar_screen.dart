import 'package:flutter/material.dart';
import 'package:islamic_hijri_calendar/islamic_hijri_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart'; // Added
import 'language_provider.dart'; // Added
import 'theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Community Calendar", "Kalendar Komuniti")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
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
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lang.getText("Live & Upcoming Events", "Acara Langsung & Akan Datang"), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('eventDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text(lang.getText("Something went wrong", "Sesuatu tidak kena")));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(child: Text(lang.getText("No events posted yet.", "Tiada acara dipaparkan lagi.")));
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
                                  label: Text(
                                    lang.getText("JOIN LIVE NOW", "SERTAI SEKARANG"), 
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                                  ),
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