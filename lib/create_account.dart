import 'sync_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthCheck extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SyncManager _syncManager = SyncManager.instance;

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser; //Get current user

    if (currentUser != null) {
      // If a user is already loggin in
      _syncManager.syncDataForAuthenticatedUser().then((_) {
        // Sync their data
        context.go('/'); // Proceed to home feed
      });
      return const Center(child: CircularProgressIndicator()); //Loading symbol
    } else {
      // If no user is loggin in
      context.go('/createaccountscreen'); // Proceed to account creation page
      return const SizedBox.shrink(); // Empty box
    }
  }
}
