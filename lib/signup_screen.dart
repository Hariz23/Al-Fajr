import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';
import 'theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp(LanguageProvider lang) async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText("Please fill all fields", "Sila isi semua ruangan"))),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create User Document with Name
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String errorMsg = lang.getText("Registration failed", "Pendaftaran gagal");
      if (e.code == 'email-already-in-use') {
        errorMsg = lang.getText("Email already registered.", "Emel telah berdaftar.");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText("Sign Up", "Daftar Akaun")),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Image.asset('assets/horizontal_logo.png', width: 150, height: 130),
            
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: lang.getText("Full Name", "Nama Penuh"),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: lang.getText("Email", "Emel"),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: lang.getText("Password", "Kata Laluan"),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _signUp(lang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(
                      lang.getText("CREATE ACCOUNT", "DAFTAR AKAUN"), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}