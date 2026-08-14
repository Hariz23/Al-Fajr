import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});

  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedState;
  String? _selectedMosqueId;
  DateTime _eventDate = DateTime.now().add(const Duration(hours: 1));
  bool _posting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _post(
    LanguageProvider lang,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mosques,
  ) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final matches = mosques.where((doc) => doc.id == _selectedMosqueId);
    if (matches.isEmpty || _selectedState == null) {
      showAppMessage(
        context,
        lang.getText('Select a valid mosque.', 'Pilih masjid yang sah.'),
        isError: true,
      );
      return;
    }
    final mosque = matches.first;
    final mosqueName = (mosque.data()['name'] ?? '').toString();
    setState(() => _posting = true);
    try {
      await FirebaseFirestore.instance.collection('events').add({
        'state': _selectedState,
        'masjidID': mosque.id,
        'locationName': mosqueName,
        'masjidName': mosqueName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'liveLink': _linkController.text.trim(),
        'link': _linkController.text.trim(),
        'eventDate': Timestamp.fromDate(_eventDate),
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _titleController.clear();
      _linkController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedMosqueId = null;
        _eventDate = DateTime.now().add(const Duration(hours: 1));
      });
      showAppMessage(
        context,
        lang.getText('Event published.', 'Acara diterbitkan.'),
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'Event could not be published. Check your permissions and connection.',
          'Acara tidak dapat diterbitkan. Semak kebenaran dan sambungan anda.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate),
    );
    if (time == null) return;
    setState(() {
      _eventDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppPage(
      title: lang.getText('Publish event', 'Terbitkan acara'),
      subtitle: lang.getText(
        'Create a community calendar entry',
        'Cipta entri kalendar komuniti',
      ),
      showBackButton: true,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('masjids').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const AppSurface(
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          if (snapshot.hasError) {
            return AppStateView(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: lang.getText(
                'Mosques could not be loaded',
                'Masjid tidak dapat dimuatkan',
              ),
              message: lang.getText(
                'Check the connection and Firestore permissions.',
                'Semak sambungan dan kebenaran Firestore.',
              ),
            );
          }
          final allMosques = snapshot.data?.docs ?? [];
          final states =
              allMosques
                  .map((doc) => doc.data()['state']?.toString())
                  .whereType<String>()
                  .where((state) => state.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final mosques =
              allMosques
                  .where(
                    (doc) => doc.data()['state']?.toString() == _selectedState,
                  )
                  .toList()
                ..sort(
                  (a, b) => (a.data()['name'] ?? '').toString().compareTo(
                    (b.data()['name'] ?? '').toString(),
                  ),
                );
          final validMosque = mosques.any((doc) => doc.id == _selectedMosqueId);

          return Form(
            key: _formKey,
            child: Column(
              children: [
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading(
                        lang.getText('Location', 'Lokasi'),
                        lang.getText(
                          'Choose the mosque that owns this event.',
                          'Pilih masjid yang menganjurkan acara ini.',
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: states.contains(_selectedState)
                            ? _selectedState
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: lang.getText('State', 'Negeri'),
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
                        validator: (value) => value == null
                            ? lang.getText('Select a state.', 'Pilih negeri.')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: validMosque ? _selectedMosqueId : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: lang.getText(
                            'Mosque or surau',
                            'Masjid atau surau',
                          ),
                          prefixIcon: const Icon(CupertinoIcons.location),
                        ),
                        items: [
                          for (final mosque in mosques)
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
                            : (value) =>
                                  setState(() => _selectedMosqueId = value),
                        validator: (value) => value == null
                            ? lang.getText('Select a mosque.', 'Pilih masjid.')
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading(
                        lang.getText('Event details', 'Butiran acara'),
                        lang.getText(
                          'The date is required; description and link are optional.',
                          'Tarikh diperlukan; penerangan dan pautan adalah pilihan.',
                        ),
                      ),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: lang.getText('Event title', 'Tajuk acara'),
                          prefixIcon: const Icon(CupertinoIcons.textformat),
                        ),
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? lang.getText(
                                'Enter an event title.',
                                'Masukkan tajuk acara.',
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: lang.getText(
                            'Short description (optional)',
                            'Penerangan ringkas (pilihan)',
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _linkController,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: lang.getText(
                            'Live or event link (optional)',
                            'Pautan langsung atau acara (pilihan)',
                          ),
                          prefixIcon: const Icon(CupertinoIcons.link),
                        ),
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final normalized = raw.startsWith('http')
                              ? raw
                              : 'https://$raw';
                          final uri = Uri.tryParse(normalized);
                          return uri == null || uri.host.isEmpty
                              ? lang.getText(
                                  'Enter a valid URL.',
                                  'Masukkan URL yang sah.',
                                )
                              : null;
                        },
                      ),
                      const SizedBox(height: 13),
                      OutlinedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(CupertinoIcons.calendar, size: 18),
                        label: Text(
                          DateFormat(
                            'EEE, d MMM yyyy • h:mm a',
                          ).format(_eventDate),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _posting ? null : () => _post(lang, mosques),
                    icon: _posting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textOnPrimary,
                            ),
                          )
                        : const Icon(CupertinoIcons.paperplane_fill),
                    label: Text(
                      lang.getText('Publish event', 'Terbitkan acara'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}
