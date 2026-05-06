import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for name lookup
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'signup_screen.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Handles Email or Name
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 
  bool _isLoading = false;

  Future<void> _login(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String loginEmail = _identifierController.text.trim();

      // If the input is not an email format, we search for the Name in Firestore
      if (!loginEmail.contains('@')) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('name', isEqualTo: loginEmail)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          throw FirebaseAuthException(code: 'user-not-found');
        }
        // Retrieve the actual email associated with that name
        loginEmail = userQuery.docs.first.get('email');
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = lang.getText(
        "Login failed. Please check your credentials.", 
        "Log masuk gagal. Sila semak maklumat anda."
      );
      
      if (e.code == 'user-not-found') {
        errorMessage = lang.getText("User not found.", "Pengguna tidak ditemui.");
      } else if (e.code == 'wrong-password') {
        errorMessage = lang.getText("Incorrect password.", "Kata laluan salah.");
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mosque, size: 80, color: AppTheme.primaryGreen),
                const SizedBox(height: 20),
                const Text("Hijrah", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Text(
                  lang.getText("Sign in to your community", "Log masuk ke komuniti anda"), 
                  style: const TextStyle(color: Colors.grey)
                ),
                const SizedBox(height: 40),
                
                TextFormField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    labelText: lang.getText("Email or Name", "Emel atau Nama"),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (val) => val!.isEmpty 
                    ? lang.getText("Enter email or name", "Masukkan emel atau nama") 
                    : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: lang.getText("Password", "Kata Laluan"),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (val) => val!.length < 6 
                    ? lang.getText("Minimum 6 characters", "Minimum 6 aksara") 
                    : null,
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          lang.getText("LOGIN", "LOG MASUK"), 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                  },
                  child: Text(
                    lang.getText("Don't have an account? Sign Up", "Tiada akaun? Daftar Sini"),
                    style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}