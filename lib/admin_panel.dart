import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class AdminPanel extends StatefulWidget {
  final String? masjidId;
  final String? masjidName;

  const AdminPanel({
    super.key, 
    required this.masjidId, 
    required this.masjidName
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _liveLinkController = TextEditingController(); 
  DateTime _selectedDate = DateTime.now();
  
  String? _detectedState; 
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingEventId;

  @override
  void initState() {
    super.initState();
    _fetchMasjidState();
  }

  // Automatically fetch the state from the masjid's profile in DB
  Future<void> _fetchMasjidState() async {
    if (widget.masjidId == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('masjids')
          .doc(widget.masjidId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _detectedState = (doc.data() as Map<String, dynamic>)['state'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching masjid state: $e");
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.masjidId == null || _detectedState == null) {
      _showSnack("Error: Masjid state not detected yet.");
      return;
    }

    setState(() => _isLoading = true);
    
    final eventData = {
      'masjidID': widget.masjidId,
      'locationName': widget.masjidName, 
      'state': _detectedState,           
      'title': _titleController.text.trim(),
      'liveLink': _liveLinkController.text.trim(), 
      'eventDate': Timestamp.fromDate(_selectedDate), 
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (_isEditing && _editingEventId != null) {
        await FirebaseFirestore.instance.collection('events').doc(_editingEventId).update(eventData);
        _showSnack("Event updated!");
      } else {
        eventData['timestamp'] = FieldValue.serverTimestamp(); 
        await FirebaseFirestore.instance.collection('events').add(eventData);
        _showSnack("Event posted!");
      }
      _clearForm();
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fixed the "non-existing method" error by actually including it
  Future<void> _deleteEvent(String id) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      _showSnack("Event deleted.");
    } catch (e) {
      _showSnack("Delete failed: $e");
    }
  }

  void _setupEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _isEditing = true;
      _editingEventId = doc.id;
      _titleController.text = data['title'] ?? '';
      _liveLinkController.text = data['liveLink'] ?? ''; 
      _selectedDate = (data['eventDate'] as Timestamp).toDate(); 
    });
  }

  void _clearForm() {
    setState(() {
      _isEditing = false;
      _editingEventId = null;
      _titleController.clear();
      _liveLinkController.clear();
      _selectedDate = DateTime.now();
    });
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _liveLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.masjidName} Admin"),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing) IconButton(icon: const Icon(Icons.close), onPressed: _clearForm)
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _detectedState == null 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildEventForm(),
          ),
          const Divider(thickness: 2),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildEventForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Posting for: $_detectedState", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Event Title", border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _liveLinkController,
            decoration: const InputDecoration(labelText: "Live Link (URL)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text("Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const Spacer(),
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen, 
                      foregroundColor: Colors.white
                    ),
                    child: Text(_isEditing ? "Update" : "Post"),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('masjidID', isEqualTo: widget.masjidId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No events found."));

        return ListView.builder(
          itemCount: docs.length,
itemBuilder: (context, index) {
  final doc = docs[index];
  final data = doc.data() as Map<String, dynamic>;
  
  // SAFE CASTING: Check if the field is a Timestamp before casting
  final dynamic dateRaw = data['eventDate'];
  final DateTime date = (dateRaw is Timestamp) 
      ? dateRaw.toDate() 
      : DateTime.now(); // Fallback to now if null or missing

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: ListTile(
      title: Text(data['title'] ?? 'Untitled Event', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Date: ${date.day}/${date.month}/${date.year}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue), 
            onPressed: () => _setupEdit(doc)
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red), 
            onPressed: () => _deleteEvent(doc.id)
          ),
        ],
      ),
    ),
  );
}
        );
      },
    );
  }
}