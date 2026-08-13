import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  static const _states = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Pulau Pinang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'W.P. Kuala Lumpur',
    'W.P. Labuan',
    'W.P. Putrajaya',
  ];

  final _mosqueFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _mosqueNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  String? _selectedState;
  String? _selectedMosqueId;
  bool _addingMosque = false;
  bool _assigningAdmin = false;

  @override
  void dispose() {
    _mosqueNameController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _addMosque(LanguageProvider lang) async {
    FocusScope.of(context).unfocus();
    if (!(_mosqueFormKey.currentState?.validate() ?? false)) return;
    setState(() => _addingMosque = true);
    try {
      final reference = FirebaseFirestore.instance.collection('masjids').doc();
      await reference.set({
        'name': _mosqueNameController.text.trim(),
        'state': _selectedState,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _mosqueNameController.clear();
      setState(() => _selectedState = null);
      showAppMessage(
        context,
        lang.getText('Mosque registered.', 'Masjid didaftarkan.'),
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'The mosque could not be registered. Check your permissions and connection.',
          'Masjid tidak dapat didaftarkan. Semak kebenaran dan sambungan anda.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _addingMosque = false);
    }
  }

  Future<void> _assignAdmin(
    LanguageProvider lang,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> mosques,
  ) async {
    FocusScope.of(context).unfocus();
    if (!(_adminFormKey.currentState?.validate() ?? false)) return;
    final selected = mosques.where((doc) => doc.id == _selectedMosqueId);
    if (selected.isEmpty) {
      showAppMessage(
        context,
        lang.getText('Select a valid mosque.', 'Pilih masjid yang sah.'),
        isError: true,
      );
      return;
    }

    setState(() => _assigningAdmin = true);
    try {
      final email = _adminEmailController.text.trim().toLowerCase();
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (users.docs.isEmpty) {
        if (mounted) {
          showAppMessage(
            context,
            lang.getText(
              'No registered user has this email.',
              'Tiada pengguna berdaftar menggunakan emel ini.',
            ),
            isError: true,
          );
        }
        return;
      }

      final user = users.docs.first;
      final mosque = selected.first;
      final currentRole = user.data()['role']?.toString() ?? 'user';
      final mosqueName = mosque.data()['name']?.toString() ?? '';
      final state = mosque.data()['state']?.toString() ?? '';
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'role': currentRole == 'super_admin' ? 'super_admin' : 'admin',
        'masjidID': mosque.id,
        'masjidName': mosqueName,
        'state': state,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _adminEmailController.clear();
      showAppMessage(
        context,
        lang.getText(
          'Administrator assigned to $mosqueName.',
          'Pentadbir ditetapkan kepada $mosqueName.',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'Permissions could not be assigned.',
          'Kebenaran tidak dapat diberikan.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _assigningAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppPage(
      title: lang.getText('System control', 'Kawalan sistem'),
      subtitle: lang.getText(
        'Mosques and administrator access',
        'Akses masjid dan pentadbir',
      ),
      showBackButton: true,
      child: Column(
        children: [
          AppSurface(
            color: AppTheme.primaryGreenDark,
            borderColor: AppTheme.primaryGreenDark,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: AppTheme.primaryGreenDark,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    lang.getText(
                      'Changes here affect live community access. Verify every email and mosque before saving.',
                      'Perubahan di sini mempengaruhi akses komuniti langsung. Sahkan setiap emel dan masjid sebelum menyimpan.',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textOnPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSectionTitle(
            title: lang.getText('REGISTER MOSQUE', 'DAFTAR MASJID'),
          ),
          AppSurface(
            child: Form(
              key: _mosqueFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _mosqueNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: lang.getText('Mosque name', 'Nama masjid'),
                      prefixIcon: const Icon(CupertinoIcons.building_2_fill),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? lang.getText(
                            'Enter the full mosque name.',
                            'Masukkan nama penuh masjid.',
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: lang.getText('State', 'Negeri'),
                      prefixIcon: const Icon(CupertinoIcons.map),
                    ),
                    items: [
                      for (final state in _states)
                        DropdownMenuItem(value: state, child: Text(state)),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedState = value),
                    validator: (value) => value == null
                        ? lang.getText('Select a state.', 'Pilih negeri.')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _addingMosque ? null : () => _addMosque(lang),
                      child: _addingMosque
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textOnPrimary,
                              ),
                            )
                          : Text(
                              lang.getText('Register mosque', 'Daftar masjid'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSectionTitle(
            title: lang.getText('ASSIGN ADMINISTRATOR', 'TETAPKAN PENTADBIR'),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('masjids')
                .snapshots(),
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
                    'Check Firestore permissions and connection.',
                    'Semak kebenaran Firestore dan sambungan.',
                  ),
                );
              }
              final mosques = [...?snapshot.data?.docs]
                ..sort(
                  (a, b) => (a.data()['name'] ?? '').toString().compareTo(
                    (b.data()['name'] ?? '').toString(),
                  ),
                );
              final validValue =
                  mosques.any((doc) => doc.id == _selectedMosqueId)
                  ? _selectedMosqueId
                  : null;
              return AppSurface(
                child: Form(
                  key: _adminFormKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: validValue,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: lang.getText(
                            'Target mosque',
                            'Masjid sasaran',
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
                        onChanged: (value) =>
                            setState(() => _selectedMosqueId = value),
                        validator: (value) => value == null
                            ? lang.getText('Select a mosque.', 'Pilih masjid.')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adminEmailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: lang.getText(
                            'Registered user email',
                            'Emel pengguna berdaftar',
                          ),
                          prefixIcon: const Icon(CupertinoIcons.mail),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(email)
                              ? null
                              : lang.getText(
                                  'Enter a valid email.',
                                  'Masukkan emel yang sah.',
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _assigningAdmin
                              ? null
                              : () => _assignAdmin(lang, mosques),
                          icon: _assigningAdmin
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textOnPrimary,
                                  ),
                                )
                              : const Icon(CupertinoIcons.person_badge_plus),
                          label: Text(
                            lang.getText(
                              'Assign permissions',
                              'Berikan kebenaran',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          AppSectionTitle(
            title: lang.getText('ACTIVE ADMINISTRATORS', 'PENTADBIR AKTIF'),
          ),
          _AdministratorList(lang: lang),
        ],
      ),
    );
  }
}

class _AdministratorList extends StatelessWidget {
  const _AdministratorList({required this.lang});

  final LanguageProvider lang;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'super_admin'])
          .snapshots(),
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
              'Administrators unavailable',
              'Pentadbir tidak tersedia',
            ),
            message: lang.getText(
              'Check the Firestore query permissions.',
              'Semak kebenaran pertanyaan Firestore.',
            ),
          );
        }
        final documents = snapshot.data?.docs ?? [];
        if (documents.isEmpty) {
          return AppStateView(
            icon: CupertinoIcons.person_2,
            title: lang.getText('No administrators', 'Tiada pentadbir'),
            message: lang.getText(
              'Assigned administrators will appear here.',
              'Pentadbir yang ditetapkan akan muncul di sini.',
            ),
          );
        }
        return AppSettingsGroup(
          children: [
            for (final document in documents)
              AppSettingsRow(
                icon: document.data()['role'] == 'super_admin'
                    ? CupertinoIcons.star_fill
                    : CupertinoIcons.person_fill,
                iconColor: document.data()['role'] == 'super_admin'
                    ? AppTheme.accentGold
                    : AppTheme.primaryGreen,
                title:
                    (document.data()['email'] ??
                            lang.getText('No email', 'Tiada emel'))
                        .toString(),
                subtitle:
                    (document.data()['masjidName'] ??
                            lang.getText(
                              'No mosque assigned',
                              'Tiada masjid ditetapkan',
                            ))
                        .toString(),
                trailing: document.data()['role'] == 'super_admin'
                    ? const Text(
                        'SUPER',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
          ],
        );
      },
    );
  }
}
