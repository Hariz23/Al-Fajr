import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminProfileProvider extends ChangeNotifier {
  String? _masjidName;
  String? _state;
  String? _masjidID;
  String? _role;

  String get masjidName => _masjidName ?? '';
  String get state => _state ?? '';
  String get masjidID => _masjidID ?? '';
  String get role => _role ?? 'user';

  bool get isProfileComplete => _masjidName != null && _masjidName!.isNotEmpty;
  bool get isSuperAdmin => _role == 'super_admin';

  AdminProfileProvider() {
    fetchProfile(); // Initial load
  }

  // THIS IS THE MISSING FUNCTION
  Future<void> fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _masjidName = data['masjidName'];
        _state = data['state'];
        _masjidID = data['masjidID'];
        _role = data['role'];
        notifyListeners();
      }
    }
  }

  // ADD THIS FOR THE PICKER TO CALL
  // Inside your AdminProfileProvider class
Future<void> updateProfile(String id, String name, String state) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'masjidID': id,
        'masjidName': name,
        'state': state,
      });
      // Refresh local variables and notify listeners
      await fetchProfile(); 
    } catch (e) {
      debugPrint("Update Profile Error: $e");
    }
  }
}
}