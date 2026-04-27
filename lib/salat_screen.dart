import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';

class SalatScreen extends StatefulWidget {
  const SalatScreen({super.key});

  @override
  State<SalatScreen> createState() => _SalatScreenState();
}

class _SalatScreenState extends State<SalatScreen> {
  Future<Map<String, dynamic>> fetchSalatData() async {
    // Fetching for Kuala Lumpur using JAKIM method
    final response = await http.get(Uri.parse(
        'https://api.aladhan.com/v1/timingsByCity?city=Kuala%20Lumpur&country=Malaysia&method=11'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to load prayer times');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prayer Times")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchSalatData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final timings = snapshot.data!['timings'];
          final date = snapshot.data!['date'];

          return Column(
            children: [
              _buildDateHeader(date),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _prayerRow("Fajr", timings['Fajr'], Icons.wb_twilight),
                    _prayerRow("Sunrise", timings['Sunrise'], Icons.wb_sunny_outlined),
                    _prayerRow("Dhuhr", timings['Dhuhr'], Icons.wb_sunny),
                    _prayerRow("Asr", timings['Asr'], Icons.cloud_queue),
                    _prayerRow("Maghrib", timings['Maghrib'], Icons.wb_cloudy_outlined),
                    _prayerRow("Isha", timings['Isha'], Icons.nightlight_round),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(Map<String, dynamic> date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
      child: Column(
        children: [
          Text(date['readable'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            "${date['hijri']['day']} ${date['hijri']['month']['en']} ${date['hijri']['year']} AH",
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(String name, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen),
          const SizedBox(width: 20),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }
}