import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({
    super.key,
    required this.masjidId,
    required this.masjidName,
  });

  final String? masjidId;
  final String? masjidName;

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _liveLinkController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  String? _detectedState;
  String? _stateError;
  bool _loadingState = true;
  bool _saving = false;
  bool _editing = false;
  String? _editingEventId;

  @override
  void initState() {
    super.initState();
    _fetchMasjidState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _liveLinkController.dispose();
    super.dispose();
  }

  Future<void> _fetchMasjidState() async {
    final id = widget.masjidId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loadingState = false;
        _stateError = 'missing-assignment';
      });
      return;
    }
    try {
      final document = await FirebaseFirestore.instance
          .collection('masjids')
          .doc(id)
          .get();
      final state = document.data()?['state']?.toString().trim();
      if (!mounted) return;
      setState(() {
        _loadingState = false;
        _detectedState = state?.isNotEmpty == true ? state : null;
        _stateError = _detectedState == null ? 'missing-state' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingState = false;
        _stateError = 'network';
      });
    }
  }

  Future<void> _save(LanguageProvider lang) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.masjidId?.isNotEmpty != true || _detectedState == null) {
      showAppMessage(
        context,
        lang.getText(
          'A valid mosque assignment is required.',
          'Penetapan masjid yang sah diperlukan.',
        ),
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    final eventData = <String, dynamic>{
      'masjidID': widget.masjidId,
      'locationName': widget.masjidName ?? '',
      'masjidName': widget.masjidName ?? '',
      'state': _detectedState,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'liveLink': _liveLinkController.text.trim(),
      'link': _liveLinkController.text.trim(),
      'eventDate': Timestamp.fromDate(_selectedDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (_editing && _editingEventId != null) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(_editingEventId)
            .update(eventData);
      } else {
        eventData['timestamp'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('events').add(eventData);
      }
      if (!mounted) return;
      showAppMessage(
        context,
        _editing
            ? lang.getText('Event updated.', 'Acara dikemas kini.')
            : lang.getText('Event published.', 'Acara diterbitkan.'),
      );
      _clearForm();
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'The event could not be saved. Check your connection and permissions.',
          'Acara tidak dapat disimpan. Semak sambungan dan kebenaran anda.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEvent(
    String id,
    String title,
    LanguageProvider lang,
  ) async {
    final confirmed = await showDestructiveConfirmation(
      context,
      title: lang.getText('Delete event?', 'Padam acara?'),
      message: title,
      confirmLabel: lang.getText('Delete', 'Padam'),
      cancelLabel: lang.getText('Cancel', 'Batal'),
    );
    if (!confirmed) return;
    try {
      await FirebaseFirestore.instance.collection('events').doc(id).delete();
      if (mounted) {
        showAppMessage(
          context,
          lang.getText('Event deleted.', 'Acara dipadam.'),
        );
      }
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'Event could not be deleted.',
          'Acara tidak dapat dipadam.',
        ),
        isError: true,
      );
    }
  }

  void _startEditing(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final rawDate = data['eventDate'];
    setState(() {
      _editing = true;
      _editingEventId = document.id;
      _titleController.text = (data['title'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();
      _liveLinkController.text = (data['liveLink'] ?? data['link'] ?? '')
          .toString();
      _selectedDate = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(_formKey.currentContext!);
    });
  }

  void _clearForm() {
    setState(() {
      _editing = false;
      _editingEventId = null;
      _titleController.clear();
      _descriptionController.clear();
      _liveLinkController.clear();
      _selectedDate = DateTime.now().add(const Duration(hours: 1));
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;
    setState(() {
      _selectedDate = DateTime(
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
    final mosqueName = widget.masjidName?.trim().isNotEmpty == true
        ? widget.masjidName!
        : lang.getText('Mosque admin', 'Admin masjid');
    return AppPage(
      title: lang.getText('Event studio', 'Studio acara'),
      subtitle: mosqueName,
      showBackButton: true,
      trailing: _editing
          ? AppIconButton(
              icon: CupertinoIcons.xmark,
              label: lang.getText('Cancel editing', 'Batal suntingan'),
              onPressed: _clearForm,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingState)
            const AppSurface(
              child: Row(
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(width: 14),
                  Text('Loading mosque assignment…'),
                ],
              ),
            )
          else if (_stateError != null)
            AppStateView(
              icon: CupertinoIcons.building_2_fill,
              title: lang.getText(
                'Mosque assignment unavailable',
                'Penetapan masjid tidak tersedia',
              ),
              message: lang.getText(
                'Ask a Super Admin to assign this account to a valid mosque and state.',
                'Minta Super Admin menetapkan akaun ini kepada masjid dan negeri yang sah.',
              ),
              actionLabel: _stateError == 'network'
                  ? lang.getText('Retry', 'Cuba lagi')
                  : null,
              onAction: _stateError == 'network'
                  ? () {
                      setState(() => _loadingState = true);
                      _fetchMasjidState();
                    }
                  : null,
            )
          else
            _eventForm(lang),
          AppSectionTitle(
            title: lang.getText('PUBLISHED EVENTS', 'ACARA DITERBITKAN'),
          ),
          _eventList(lang),
        ],
      ),
    );
  }

  Widget _eventForm(LanguageProvider lang) {
    return AppSurface(
      color: _editing ? AppTheme.warmCream : AppTheme.surface,
      borderColor: _editing ? AppTheme.paleGold : AppTheme.divider,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppTheme.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar_badge_plus,
                    color: AppTheme.primaryGreen,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editing
                            ? lang.getText('Edit event', 'Sunting acara')
                            : lang.getText('New event', 'Acara baharu'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _detectedState ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 4,
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
              controller: _liveLinkController,
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
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(CupertinoIcons.calendar, size: 18),
              label: Text(
                DateFormat('EEE, d MMM yyyy • h:mm a').format(_selectedDate),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : () => _save(lang),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textOnPrimary,
                        ),
                      )
                    : Text(
                        _editing
                            ? lang.getText('Update event', 'Kemas kini acara')
                            : lang.getText('Publish event', 'Terbitkan acara'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventList(LanguageProvider lang) {
    final id = widget.masjidId;
    if (id == null || id.isEmpty) {
      return AppStateView(
        icon: CupertinoIcons.calendar,
        title: lang.getText('No event list', 'Tiada senarai acara'),
        message: lang.getText(
          'Events appear after a mosque is assigned.',
          'Acara akan muncul selepas masjid ditetapkan.',
        ),
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('masjidID', isEqualTo: id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (snapshot.hasError) {
          return AppStateView(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: lang.getText(
              'Events could not be loaded',
              'Acara tidak dapat dimuatkan',
            ),
            message: lang.getText(
              'Check the connection and Firestore permissions.',
              'Semak sambungan dan kebenaran Firestore.',
            ),
          );
        }
        final documents = [...?snapshot.data?.docs]
          ..sort((a, b) {
            final aDate = a.data()['eventDate'];
            final bDate = b.data()['eventDate'];
            final aValue = aDate is Timestamp ? aDate.toDate() : DateTime(1970);
            final bValue = bDate is Timestamp ? bDate.toDate() : DateTime(1970);
            return bValue.compareTo(aValue);
          });
        if (documents.isEmpty) {
          return AppStateView(
            icon: CupertinoIcons.calendar_badge_plus,
            title: lang.getText('No events yet', 'Belum ada acara'),
            message: lang.getText(
              'Create the first event using the form above.',
              'Cipta acara pertama menggunakan borang di atas.',
            ),
          );
        }
        return Column(
          children: [
            for (final document in documents) ...[
              _AdminEventCard(
                document: document,
                lang: lang,
                onEdit: () => _startEditing(document),
                onDelete: () => _deleteEvent(
                  document.id,
                  (document.data()['title'] ?? '').toString(),
                  lang,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  const _AdminEventCard({
    required this.document,
    required this.lang,
    required this.onEdit,
    required this.onDelete,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final LanguageProvider lang;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final rawDate = data['eventDate'];
    final date = rawDate is Timestamp ? rawDate.toDate() : null;
    final isPast = date?.isBefore(DateTime.now()) ?? false;
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPast ? AppTheme.surfaceMuted : AppTheme.mint,
              borderRadius: AppTheme.borderRadiusSm,
            ),
            child: Icon(
              isPast ? CupertinoIcons.clock_fill : CupertinoIcons.calendar,
              color: isPast ? AppTheme.textSecondary : AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (data['title'] ??
                          lang.getText('Untitled event', 'Acara tanpa tajuk'))
                      .toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null
                      ? lang.getText('Date missing', 'Tarikh tiada')
                      : DateFormat('d MMM yyyy • h:mm a').format(date),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: onEdit,
            child: const Icon(
              CupertinoIcons.pencil,
              color: AppTheme.info,
              size: 19,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            onPressed: onDelete,
            child: const Icon(
              CupertinoIcons.delete,
              color: AppTheme.danger,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}
