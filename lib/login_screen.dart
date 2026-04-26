import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Add this
import 'language_provider.dart'; // Add this
import 'signup_screen.dart'; 
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); 
  bool _isLoading = false;

  Future<void> _login(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Localized Error Messages
      String errorMessage = lang.getText(
        "Login failed. Please check your credentials.", 
        "Log masuk gagal. Sila semak maklumat anda."
      );
      
      if (e.code == 'user-not-found') {
        errorMessage = lang.getText("No user found with this email.", "Tiada pengguna ditemui dengan emel ini.");
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
                const Text("Al-Fajr", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Text(
                  lang.getText("Sign in to your community", "Log masuk ke komuniti anda"), 
                  style: const TextStyle(color: Colors.grey)
                ),
                const SizedBox(height: 40),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: lang.getText("Email", "Emel"),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (val) => val!.isEmpty 
                    ? lang.getText("Enter an email", "Masukkan emel") 
                    : null,
                ),
                const SizedBox(height: 15),
                
                // Password Field
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
                
                // Login Button
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
                
                // Link to SignUp
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: Text(
                    lang.getText(
                      "Don't have an account? Sign Up", 
                      "Tiada akaun? Daftar Sini"
                    ),
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