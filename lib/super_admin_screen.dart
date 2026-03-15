import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final _masjidNameController = TextEditingController();
  final _adminEmailController = TextEditingController();

  final List<String> _states = [
    "Johor", "Kedah", "Kelantan", "Melaka", "Negeri Sembilan", "Pahang", 
    "Perak", "Perlis", "Pulau Pinang", "Sabah", "Sarawak", "Selangor", 
    "Terengganu", "W.P. Kuala Lumpur"
  ];

  String? _selectedState;
  String? _selectedMasjidId;

  // Professional Feedback Styling
  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 1. REGISTER NEW MASJID
  Future<void> _addMasjid() async {
    final name = _masjidNameController.text.trim();
    if (name.isEmpty || _selectedState == null) {
      _showFeedback("Name and State are required", isError: true);
      return;
    }
    try {
      String docId = name.toLowerCase().replaceAll(' ', '_');
      await FirebaseFirestore.instance.collection('masjids').doc(docId).set({
        'name': name,
        'state': _selectedState,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _masjidNameController.clear();
      setState(() => _selectedState = null);
      _showFeedback("Masjid Registered Successfully!");
    } catch (e) {
      _showFeedback("Database Error: $e", isError: true);
    }
  }

  // 2. ASSIGN ADMIN (Triggers Home Screen Stream update)
  Future<void> _assignAdmin() async {
    final emailInput = _adminEmailController.text.trim().toLowerCase();
    if (_selectedMasjidId == null || emailInput.isEmpty) {
      _showFeedback("Selection required", isError: true);
      return;
    }

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailInput)
          .get();

      if (userSnap.docs.isEmpty) {
        _showFeedback("User not found: $emailInput", isError: true);
        return;
      }

      var userDoc = userSnap.docs.first;
      final userData = userDoc.data();
      String currentRole = userData['role'] ?? 'user';
      String? oldMasjid = userData['masjidName'];

      final masjidDoc = await FirebaseFirestore.instance.collection('masjids').doc(_selectedMasjidId).get();
      final String newMasjid = masjidDoc.data()?['name'] ?? 'Unknown';

      // Keep super_admin status if it already exists
      String finalRole = (currentRole == 'super_admin') ? 'super_admin' : 'admin';

      await FirebaseFirestore.instance.collection('users').doc(userDoc.id).update({
        'role': finalRole,
        'masjidID': _selectedMasjidId,
        'masjidName': newMasjid,
      });

      _adminEmailController.clear();
      _showFeedback(oldMasjid != null && oldMasjid != newMasjid 
          ? "Moved $emailInput to $newMasjid" 
          : "Permissions granted for $newMasjid");
    } catch (e) {
      _showFeedback("Assignment Error: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("System Control", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeaderCard("Masjid Registration", Icons.domain, const Color(0xFF1A237E), [
                    _buildTextField(_masjidNameController, "Masjid Name", Icons.edit_location),
                    const SizedBox(height: 12),
                    _buildDropdown("Select State", _states, _selectedState, (v) => setState(() => _selectedState = v)),
                    const SizedBox(height: 15),
                    _buildButton("SAVE MASJID", const Color(0xFF1A237E), _addMasjid),
                  ]),
                  const SizedBox(height: 16),
                  _buildHeaderCard("Access Assignment", Icons.admin_panel_settings, Colors.teal, [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('masjids').snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return _buildDropdown(
                          "Choose Target Masjid", 
                          snap.data!.docs.map((doc) => doc.id).toList(), 
                          _selectedMasjidId, 
                          (v) => setState(() => _selectedMasjidId = v),
                          nameMap: {for (var doc in snap.data!.docs) doc.id: doc['name']}
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_adminEmailController, "Admin Email", Icons.alternate_email),
                    const SizedBox(height: 15),
                    _buildButton("ASSIGN PERMISSIONS", Colors.teal, _assignAdmin),
                  ]),
                ],
              ),
            ),
          ),
          _buildLiveObserver(), // Put your live activity watcher back at the bottom
        ],
      ),
    );
  }

  // --- REUSABLE UI HELPERS ---

  Widget _buildHeaderCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            ]),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, Function(String?) onChanged, {Map<String, String>? nameMap}) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint),
      decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(nameMap?[s] ?? s))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback action) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLiveObserver() {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Live System Activity", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', whereIn: ['admin', 'super_admin']).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snap.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = snap.data!.docs[index].data() as Map<String, dynamic>;
                    bool isSuper = data['role'] == 'super_admin';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isSuper ? Colors.amber.shade50 : Colors.teal.shade50,
                        child: Icon(isSuper ? Icons.stars : Icons.person, color: isSuper ? Colors.amber : Colors.teal),
                      ),
                      title: Text(data['email'] ?? 'No Email', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(data['masjidName'] ?? 'Floating Admin', style: const TextStyle(fontSize: 12)),
                      trailing: isSuper ? const Badge(label: Text("SUPER", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.amber) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}