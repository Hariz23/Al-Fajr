import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'admin_profile_provider.dart';
import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class AdminIdentityPicker extends StatefulWidget {
  const AdminIdentityPicker({
    super.key,
    required this.profile,
    required this.lang,
  });

  final AdminProfileProvider profile;
  final LanguageProvider lang;

  @override
  State<AdminIdentityPicker> createState() => _AdminIdentityPickerState();
}

class _AdminIdentityPickerState extends State<AdminIdentityPicker> {
  String? _selectedState;
  String? _selectedMosqueId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isSuperAdmin) {
      return CupertinoAlertDialog(
        title: Text(widget.lang.getText('Identity locked', 'Identiti dikunci')),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            widget.lang.getText(
              'Only a Super Admin can change a mosque assignment.',
              'Hanya Super Admin boleh menukar penetapan masjid.',
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            CupertinoIcons.building_2_fill,
            color: AppTheme.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.lang.getText(
                'Switch mosque identity',
                'Tukar identiti masjid',
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('masjids').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(26),
                child: Center(child: CupertinoActivityIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                widget.lang.getText(
                  'Mosques could not be loaded. Check the connection.',
                  'Masjid tidak dapat dimuatkan. Semak sambungan.',
                ),
                style: const TextStyle(color: AppTheme.danger),
              );
            }
            final mosques = snapshot.data?.docs ?? [];
            final states =
                mosques
                    .map((document) => document.data()['state']?.toString())
                    .whereType<String>()
                    .where((state) => state.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
            final filtered =
                mosques
                    .where(
                      (document) =>
                          document.data()['state']?.toString() ==
                          _selectedState,
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a.data()['name'] ?? '').toString().compareTo(
                      (b.data()['name'] ?? '').toString(),
                    ),
                  );
            final validMosque = filtered.any(
              (document) => document.id == _selectedMosqueId,
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: states.contains(_selectedState)
                      ? _selectedState
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.lang.getText('State', 'Negeri'),
                    prefixIcon: const Icon(CupertinoIcons.map),
                  ),
                  items: [
                    for (final state in states)
                      DropdownMenuItem(value: state, child: Text(state)),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedState = value;
                    _selectedMosqueId = null;
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: validMosque ? _selectedMosqueId : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.lang.getText(
                      'Mosque or surau',
                      'Masjid atau surau',
                    ),
                    prefixIcon: const Icon(CupertinoIcons.location),
                  ),
                  items: [
                    for (final mosque in filtered)
                      DropdownMenuItem(
                        value: mosque.id,
                        child: Text(
                          (mosque.data()['name'] ?? mosque.id).toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _selectedState == null
                      ? null
                      : (value) => setState(() => _selectedMosqueId = value),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lang.getText(
                    'The real Firestore document ID is saved with the display name.',
                    'ID dokumen Firestore sebenar disimpan bersama nama paparan.',
                  ),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(widget.lang.getText('Cancel', 'Batal')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving || !validMosque
                          ? null
                          : () => _save(filtered),
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textOnPrimary,
                              ),
                            )
                          : Text(widget.lang.getText('Save', 'Simpan')),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      actions: const [],
    );
  }

  Future<void> _save(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mosques,
  ) async {
    final matches = mosques.where((doc) => doc.id == _selectedMosqueId);
    if (_selectedState == null || matches.isEmpty) return;
    final selected = matches.first;
    final name = selected.data()['name']?.toString() ?? '';
    setState(() => _saving = true);
    try {
      await widget.profile.updateProfile(selected.id, name, _selectedState!);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppMessage(
        context,
        widget.lang.getText(
          'Assignment could not be updated.',
          'Penetapan tidak dapat dikemas kini.',
        ),
        isError: true,
      );
    }
  }
}
