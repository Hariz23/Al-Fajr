import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationNameController = TextEditingController(); // Name of Masjid/Surau
  final _linkController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _venueType = 'Masjid'; // Default
  final String _eventType = 'Talk/Kuliah';

  Future<void> _publishEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('events').add({
          'title': _titleController.text.trim(),
          'venueType': _venueType, // Masjid or Surau
          'locationName': _locationNameController.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: const Text("Post New Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Venue Type", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio(value: 'Masjid', groupValue: _venueType, onChanged: (val) => setState(() => _venueType = val!)),
                  const Text("Masjid"),
                  const SizedBox(width: 20),
                  Radio(value: 'Surau', groupValue: _venueType, onChanged: (val) => setState(() => _venueType = val!)),
                  const Text("Surau"),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Event Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _locationNameController,
                decoration: InputDecoration(labelText: "Name of $_venueType", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: "Live Link (YouTube/Zoom URL)",
                  hintText: "Paste link here for community to join online",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Event Date", style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
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
                  onPressed: _publishEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("PUBLISH TO CALENDAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}