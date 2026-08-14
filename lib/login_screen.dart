import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'auth_shell.dart';
import 'language_provider.dart';
import 'password_field.dart';
import 'signup_screen.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(LanguageProvider lang) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      var loginEmail = _identifierController.text.trim();
      if (!loginEmail.contains('@')) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: loginEmail)
            .limit(1)
            .get();
        if (userQuery.docs.isEmpty) {
          throw FirebaseAuthException(code: 'user-not-found');
        }
        final storedEmail = userQuery.docs.first.data()['email'];
        if (storedEmail is! String || storedEmail.isEmpty) {
          throw FirebaseAuthException(code: 'user-not-found');
        }
        loginEmail = storedEmail;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      showAppMessage(context, _authMessage(lang, error.code), isError: true);
    } on FirebaseException {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'Unable to reach your account. Check the connection and try again.',
          'Akaun tidak dapat dicapai. Semak sambungan dan cuba lagi.',
        ),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'Something went wrong. Please try again.',
          'Sesuatu tidak kena. Sila cuba lagi.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword(LanguageProvider lang) async {
    FocusScope.of(context).unfocus();
    final typed = _identifierController.text.trim();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(
        lang: lang,
        initialEmail: typed.contains('@') ? typed : '',
      ),
    );
    if (email == null || !mounted) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      showAppMessage(
        context,
        lang.getText(
          'If that email has an account, a reset link is on its way.',
          'Jika emel itu mempunyai akaun, pautan tetapan semula akan dihantar.',
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      // 'user-not-found' is deliberately not distinguished here: telling a
      // stranger which emails are registered leaks the member list.
      final message = switch (error.code) {
        'invalid-email' => lang.getText(
          'Enter a valid email address.',
          'Masukkan alamat emel yang sah.',
        ),
        'too-many-requests' => lang.getText(
          'Too many attempts. Please wait and try again.',
          'Terlalu banyak percubaan. Sila tunggu dan cuba lagi.',
        ),
        'network-request-failed' => lang.getText(
          'No internet connection. Please try again.',
          'Tiada sambungan internet. Sila cuba lagi.',
        ),
        _ => lang.getText(
          'If that email has an account, a reset link is on its way.',
          'Jika emel itu mempunyai akaun, pautan tetapan semula akan dihantar.',
        ),
      };
      showAppMessage(context, message, isError: error.code != 'user-not-found');
    }
  }

  String _authMessage(LanguageProvider lang, String code) {
    switch (code) {
      case 'user-not-found':
        return lang.getText('Account not found.', 'Akaun tidak ditemui.');
      case 'wrong-password':
      case 'invalid-credential':
        return lang.getText(
          'The email, name or password is incorrect.',
          'Emel, nama atau kata laluan tidak betul.',
        );
      case 'too-many-requests':
        return lang.getText(
          'Too many attempts. Please wait and try again.',
          'Terlalu banyak percubaan. Sila tunggu dan cuba lagi.',
        );
      case 'network-request-failed':
        return lang.getText(
          'No internet connection. Please try again.',
          'Tiada sambungan internet. Sila cuba lagi.',
        );
      default:
        return lang.getText(
          'Sign in failed. Please try again.',
          'Log masuk gagal. Sila cuba lagi.',
        );
    }
  }
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AuthShell(
      title: lang.getText('Welcome back', 'Selamat kembali'),
      subtitle: lang.getText(
        'Your prayers, Quran and community in one calm place.',
        'Solat, al-Quran dan komuniti anda dalam satu ruang yang tenang.',
      ),
      isEnglish: lang.isEnglish,
      onLanguageChanged: lang.setEnglish,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _identifierController,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: lang.getText(
                    'Email or full name',
                    'Emel atau nama penuh',
                  ),
                  prefixIcon: const Icon(CupertinoIcons.person),
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? lang.getText(
                        'Enter your email or full name.',
                        'Masukkan emel atau nama penuh.',
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              AppPasswordField(
                controller: _passwordController,
                label: lang.getText('Password', 'Kata laluan'),
                lang: lang,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: () => _login(lang),
                validator: (value) =>
                    (value?.length ?? 0) < PasswordRules.minLength
                    ? lang.getText(
                        'Password must contain at least ${PasswordRules.minLength} characters.',
                        'Kata laluan mesti mengandungi sekurang-kurangnya ${PasswordRules.minLength} aksara.',
                      )
                    : null,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _isLoading ? null : () => _resetPassword(lang),
                  child: Text(
                    lang.getText('Forgot password?', 'Lupa kata laluan?'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: _isLoading ? null : () => _login(lang),
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textOnPrimary,
                        ),
                      )
                    : Text(lang.getText('Sign in', 'Log masuk')),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang.getText('New to Al Fajr?', 'Baharu di Al Fajr?'),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                    child: Text(lang.getText('Create account', 'Cipta akaun')),
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

/// Asks for the address the reset link should go to, pre-filled with whatever
/// was already typed into the sign-in field.
class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.lang, required this.initialEmail});

  final LanguageProvider lang;
  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialEmail,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return AlertDialog(
      title: Text(lang.getText('Reset password', 'Tetapkan semula kata laluan')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.getText(
                'We will email you a link to choose a new password.',
                'Kami akan menghantar pautan untuk memilih kata laluan baharu.',
              ),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.getText('Cancel', 'Batal')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(lang.getText('Send link', 'Hantar pautan')),
        ),
      ],
    );
  }
}
