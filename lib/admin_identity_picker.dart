import 'package:flutter/material.dart';
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
  final List<String> _states = ["Selangor", "Putrajaya", "Kuala Lumpur"];
  final Map<String, List<String>> _masjids = {
    "Selangor": ["Masjid Bukit Jelutong", "Masjid Subang Jaya"],
    "Putrajaya": ["Masjid Putra"],
    "Kuala Lumpur": ["Masjid Wilayah"],
  };

  String? _tempState;
  String? _tempMasjid;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lang.getText("Identity Setup", "Tetapan Identiti")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "State"),
            items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() { _tempState = val; _tempMasjid = null; }),
          ),
          const SizedBox(height: 10),
          if (_tempState != null)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Masjid/Surau"),
              items: _masjids[_tempState]!.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _tempMasjid = val),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.lang.getText("Cancel", "Batal"))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          onPressed: () {
            if (_tempState != null && _tempMasjid != null) {
              widget.profile.updateProfile(_tempMasjid!, _tempState!);
              Navigator.pop(context);
            }
          },
          child: Text(widget.lang.getText("Save", "Simpan"), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}