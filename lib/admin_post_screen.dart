import 'package:flutter/material.dart';
import 'theme.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});

  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  // Local Data for the "Twitch" logic your boss mentioned
  final List<String> _states = ["Selangor", "Putrajaya", "Kuala Lumpur"];
  
  final Map<String, List<String>> _masjidsByState = {
    "Selangor": ["Masjid Bukit Jelutong", "Masjid Subang Jaya", "Masjid Sultan Salahuddin Abdul Aziz Shah"],
    "Putrajaya": ["Masjid Putra", "Masjid Tuanku Mizan Zainal Abidin"],
    "Kuala Lumpur": ["Masjid Wilayah Persekutuan", "Masjid Jamek", "Masjid Negara"],
  };

  String? _selectedState;
  String? _selectedMasjid;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void _handlePost() {
    if (_selectedState == null || _selectedMasjid == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select State, Masjid, and enter a Title")),
      );
      return;
    }

    // Logic to send to Firebase (Text & Links only)
    final newEvent = {
      "state": _selectedState,
      "masjidName": _selectedMasjid,
      "title": _titleController.text,
      "description": _descController.text,
      "link": _linkController.text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    print("Sending to Database: $newEvent");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Event posted for $_selectedMasjid")),
    );
    
    // Clear fields
    _titleController.clear();
    _linkController.clear();
    _descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel: Add Event"),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("1. CHOOSE LOCATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            
            // STATE SELECTOR
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "State"),
              value: _selectedState,
              items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedState = val;
                  _selectedMasjid = null; // Reset masjid when state changes
                });
              },
            ),
            
            const SizedBox(height: 15),

            // MASJID SELECTOR (Filters based on State)
            if (_selectedState != null)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Select Masjid / Surau"),
                value: _selectedMasjid,
                items: _masjidsByState[_selectedState]!
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMasjid = val),
              ),

            const SizedBox(height: 30),
            const Text("2. EVENT DETAILS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Event Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Short Description", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: "Link (YouTube / FB Live / Maps)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handlePost,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text("POST EVENT", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}