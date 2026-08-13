import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
import 'theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp(LanguageProvider lang) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    User? createdUser;
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      createdUser = credential.user;
      if (createdUser == null) throw StateError('User was not created');

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(createdUser.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim().toLowerCase(),
              'role': 'user',
              'createdAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {
        await createdUser.delete();
        rethrow;
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'email-already-in-use' => lang.getText(
          'This email is already registered.',
          'Emel ini telah didaftarkan.',
        ),
        'invalid-email' => lang.getText(
          'Enter a valid email address.',
          'Masukkan alamat emel yang sah.',
        ),
        'weak-password' => lang.getText(
          'Choose a stronger password.',
          'Pilih kata laluan yang lebih kukuh.',
        ),
        'network-request-failed' => lang.getText(
          'No internet connection. Please try again.',
          'Tiada sambungan internet. Sila cuba lagi.',
        ),
        _ => lang.getText(
          'Account could not be created. Please try again.',
          'Akaun tidak dapat dicipta. Sila cuba lagi.',
        ),
      };
      showAppMessage(context, message, isError: true);
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'We could not finish creating your account. Nothing was saved; please try again.',
          'Akaun anda tidak dapat disiapkan. Tiada data disimpan; sila cuba lagi.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AppPage(
      title: lang.getText('Create account', 'Cipta akaun'),
      subtitle: lang.getText(
        'Join the Al Fajr community',
        'Sertai komuniti Al Fajr',
      ),
      showBackButton: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                children: [
                  AppSurface(
                    color: AppTheme.mint,
                    borderColor: AppTheme.mintStrong,
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: AppTheme.borderRadiusSm,
                          ),
                          child: Image.asset('assets/icon.png'),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            lang.getText(
                              'Save preferences and stay connected to your mosque.',
                              'Simpan pilihan dan kekal terhubung dengan masjid anda.',
                            ),
                            style: const TextStyle(
                              color: AppTheme.primaryGreenDark,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _nameController,
                    autofillHints: const [AutofillHints.name],
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: lang.getText('Full name', 'Nama penuh'),
                      prefixIcon: const Icon(CupertinoIcons.person),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? lang.getText(
                            'Enter your full name.',
                            'Masukkan nama penuh anda.',
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: lang.getText('Email', 'Emel'),
                      prefixIcon: const Icon(CupertinoIcons.mail),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return lang.getText(
                          'Enter a valid email address.',
                          'Masukkan alamat emel yang sah.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(lang),
                    decoration: InputDecoration(
                      labelText: lang.getText('Password', 'Kata laluan'),
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? lang.getText(
                                'Show password',
                                'Tunjukkan kata laluan',
                              )
                            : lang.getText(
                                'Hide password',
                                'Sembunyikan kata laluan',
                              ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) < 6
                        ? lang.getText(
                            'Use at least 6 characters.',
                            'Gunakan sekurang-kurangnya 6 aksara.',
                          )
                        : null,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : () => _signUp(lang),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.textOnPrimary,
                              ),
                            )
                          : Text(lang.getText('Create account', 'Cipta akaun')),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    lang.getText(
                      'By continuing, you agree to use accurate account information.',
                      'Dengan meneruskan, anda bersetuju menggunakan maklumat akaun yang tepat.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
