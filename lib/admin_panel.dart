import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'admin_profile_provider.dart'; // Pulls the saved profile
import 'theme.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  final String _eventType = 'Talk/Kuliah';

  Future<void> _publishEvent(AdminProfileProvider profile) async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('events').add({
          'title': _titleController.text.trim(),
          'locationName': profile.masjidName, // Auto-filled from Settings
          'state': profile.state,             // Auto-filled from Settings
          'liveLink': _linkController.text.trim(),
          'eventDate': Timestamp.fromDate(_selectedDate),
          'category': _eventType,
          'postedBy': "Admin",
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Success! Event pushed to Community Calendar.")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the profile data once
    final profile = Provider.of<AdminProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post New Event"),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- AUTOMATIC IDENTITY CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Posting as:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(profile.masjidName ?? "Unknown Masjid", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen)),
                    Text("State: ${profile.state ?? 'Unknown'}", style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text("Event Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Event Title", 
                  hintText: "e.g., Kuliah Maghrib Perdana",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: "Live Link (YouTube/Zoom URL)",
                  hintText: "Paste link here (Optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              const Text("Event Date", style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: ListTile(
                  title: Text(DateFormat('EEEE, d MMMM yyyy').format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_month, color: AppTheme.primaryGreen),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _publishEvent(profile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("PUBLISH TO CALENDAR", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 