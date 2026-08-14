import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'auth_shell.dart';
import 'language_provider.dart';
import 'password_field.dart';
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
    return AuthShell(
      title: lang.getText('Create account', 'Cipta akaun'),
      subtitle: lang.getText(
        'Join the Al Fajr community.',
        'Sertai komuniti Al Fajr.',
      ),
      isEnglish: lang.isEnglish,
      onLanguageChanged: lang.setEnglish,
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSurface(
                color: AppTheme.mint,
                borderColor: AppTheme.mintStrong,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lang.getText(
                          'Save preferences and stay connected to your mosque.',
                          'Simpan pilihan dan kekal terhubung dengan masjid anda.',
                        ),
                        style: const TextStyle(
                          color: AppTheme.primaryGreenDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                validator: (value) =>
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(
                      value?.trim() ?? '',
                    )
                    ? null
                    : lang.getText(
                        'Enter a valid email address.',
                        'Masukkan alamat emel yang sah.',
                      ),
              ),
              const SizedBox(height: 14),
              AppPasswordField(
                controller: _passwordController,
                label: lang.getText('Password', 'Kata laluan'),
                lang: lang,
                showStrength: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: () => _signUp(lang),
                validator: (value) =>
                    (value?.length ?? 0) < PasswordRules.minLength
                    ? lang.getText(
                        'Use at least ${PasswordRules.minLength} characters.',
                        'Gunakan sekurang-kurangnya ${PasswordRules.minLength} aksara.',
                      )
                    : null,
              ),
              const SizedBox(height: 22),
              FilledButton(
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang.getText(
                      'Already registered?',
                      'Sudah mempunyai akaun?',
                    ),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.maybePop(context),
                    child: Text(lang.getText('Sign in', 'Log masuk')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
