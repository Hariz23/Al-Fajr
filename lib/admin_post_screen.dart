import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});

  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  String? _selectedState;
  String? _selectedMasjid;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void _handlePost(LanguageProvider lang) async {
    if (_selectedState == null || _selectedMasjid == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText(
          "Please select State, Masjid, and enter a Title", 
          "Sila pilih Negeri, Masjid, dan masukkan Tajuk"
        ))),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('events').add({
        "state": _selectedState,
        "masjidName": _selectedMasjid,
        "title": _titleController.text,
        "description": _descController.text,
        "link": _linkController.text,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText("Event posted!", "Acara telah dihantar!"))),
      );
      
      _titleController.clear();
      _linkController.clear();
      _descController.clear();
      setState(() { _selectedMasjid = null; });
    } catch (e) {
      debugPrint("Post Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Admin Panel: Add Event", "Panel Admin: Tambah Acara")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.getText("1. CHOOSE LOCATION", "1. PILIH LOKASI"), 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),

            // DYNAMIC STATE SELECTOR
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('masjids').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                
                final states = snapshot.data!.docs
                    .map((doc) => doc['state'] as String)
                    .toSet() 
                    .toList();
                states.sort();

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(), 
                    labelText: lang.getText("State", "Negeri")
                  ),
                  value: _selectedState,
                  items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() { 
                    _selectedState = val; 
                    _selectedMasjid = null; 
                  }),
                );
              }
            ),
            
            const SizedBox(height: 15),

            // DYNAMIC MASJID SELECTOR
            if (_selectedState != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('masjids')
                    .where('state', isEqualTo: _selectedState)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(), 
                      labelText: lang.getText("Select Masjid / Surau", "Pilih Masjid / Surau")
                    ),
                    value: _selectedMasjid,
                    items: snapshot.data!.docs.map((doc) {
                      String name = doc['name'];
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMasjid = val),
                  );
                },
              ),

            const SizedBox(height: 30),
            Text(lang.getText("2. EVENT DETAILS", "2. BUTIRAN ACARA"), 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: lang.getText("Event Title", "Tajuk Acara"), 
                border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: lang.getText("Short Description", "Penerangan Ringkas"), 
                border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: lang.getText("Link", "Pautan"),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _handlePost(lang),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: Text(lang.getText("POST EVENT", "HANTAR ACARA"), 
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}