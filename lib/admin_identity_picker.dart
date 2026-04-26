import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_profile_provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class AdminIdentityPicker extends StatefulWidget {
  final AdminProfileProvider profile;
  final LanguageProvider lang;

  const AdminIdentityPicker({super.key, required this.profile, required this.lang});

  @override
  State<AdminIdentityPicker> createState() => _AdminIdentityPickerState();
}

class _AdminIdentityPickerState extends State<AdminIdentityPicker> {
  String? _tempState;
  String? _tempMasjid;

  @override
  Widget build(BuildContext context) {
    // SECURITY CHECK: If not super admin, show "Locked" message
    if (!widget.profile.isSuperAdmin) {
      return AlertDialog(
        title: Text(widget.lang.getText("Identity Locked", "Identiti Dikunci")),
        content: Text(widget.lang.getText(
          "Your masjid assignment is fixed by the developer. Contact Super Admin to change.",
          "Masjid anda telah ditetapkan. Hubungi Super Admin untuk menukar."
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      );
    }

    return ListenableBuilder(
      listenable: widget.lang,
      builder: (context, _) {
        return AlertDialog(
          key: ValueKey("picker_root_${widget.lang.isEnglish}"),
          title: Text(widget.lang.getText("Select Masjid (Super Admin)", "Pilih Masjid (Super Admin)")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- DYNAMIC STATE SELECTOR ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('masjids').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  // Extract unique states from the masjid documents
                  final states = snapshot.data!.docs
                      .map((doc) => doc['state'] as String)
                      .toSet()
                      .toList();
                  states.sort();

                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: widget.lang.getText("State", "Negeri"),
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _tempState,
                        items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() {
                          _tempState = val;
                          _tempMasjid = null;
                        }),
                      ),
                    ),
                  );
                }
              ),
              
              const SizedBox(height: 16),

              // --- DYNAMIC MASJID SELECTOR ---
              if (_tempState != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('masjids')
                      .where('state', isEqualTo: _tempState)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();

                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: widget.lang.getText("Masjid/Surau", "Masjid/Surau"),
                        border: const OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _tempMasjid,
                          items: snapshot.data!.docs.map((doc) {
                            String name = doc['name'];
                            return DropdownMenuItem(value: name, child: Text(name));
                          }).toList(),
                          onChanged: (val) => setState(() => _tempMasjid = val),
                        ),
                      ),
                    );
                  }
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(widget.lang.getText("Cancel", "Batal"))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen, 
                foregroundColor: Colors.white
              ),
              onPressed: () async {
                if (_tempState != null && _tempMasjid != null) {
                  // Pass data to provider to update Firestore user doc
                  await widget.profile.updateProfile(_tempMasjid!, _tempMasjid!, _tempState!);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(widget.lang.getText("Save", "Simpan")),
            ),
          ],
        );
      },
    );
  }
}