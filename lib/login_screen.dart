import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_ui.dart';
import 'language_provider.dart';
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
  bool _obscurePassword = true;

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
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 62, 24, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 104,
                              height: 104,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: AppTheme.borderRadiusLg,
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Image.asset('assets/icon.png'),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            lang.getText('Welcome back', 'Selamat kembali'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.getText(
                              'Your prayers, Quran and community in one calm place.',
                              'Solat, al-Quran dan komuniti anda dalam satu ruang yang tenang.',
                            ),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 30),
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
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? lang.getText(
                                    'Enter your email or full name.',
                                    'Masukkan emel atau nama penuh.',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            autofillHints: const [AutofillHints.password],
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(lang),
                            decoration: InputDecoration(
                              labelText: lang.getText(
                                'Password',
                                'Kata laluan',
                              ),
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
                                    'Password must contain at least 6 characters.',
                                    'Kata laluan mesti mengandungi sekurang-kurangnya 6 aksara.',
                                  )
                                : null,
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
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
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      CupertinoPageRoute<void>(
                                        builder: (_) => const SignUpScreen(),
                                      ),
                                    ),
                              child: Text(
                                lang.getText(
                                  'New to Al Fajr? Create an account',
                                  'Baharu di Al Fajr? Cipta akaun',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 18,
              child: Semantics(
                button: true,
                label: lang.getText('Change language', 'Tukar bahasa'),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(44, 44),
                  color: AppTheme.surface,
                  borderRadius: AppTheme.borderRadiusLg,
                  onPressed: lang.toggleLanguage,
                  child: Text(
                    lang.isEnglish ? 'BM' : 'EN',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
