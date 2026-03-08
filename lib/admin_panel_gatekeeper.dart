import 'package:flutter/material.dart';
import 'admin_post_screen.dart';

class AdminPanelGatekeeper {
  static void openAdminPanel(BuildContext context, bool isProfileComplete) {
    if (!isProfileComplete) {
      // The "Small Window" (Dialog) you requested
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Access Denied"),
          content: const Text("Please enter Masjid/Surau Name and State in Settings to access the admin panel."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to Settings Screen
              },
              child: const Text("Go to Settings"),
            ),
          ],
        ),
      );
    } else {
      // If complete, go to the actual posting screen
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPostScreen()));
    }
  }
}