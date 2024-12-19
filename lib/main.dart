import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'homefeed.dart';
import 'profile.dart';
import 'storage.dart';
import 'create_cache.dart';
import 'friend_feed.dart';
import 'chico_feed.dart';
import 'sync_manager.dart';
import 'create_account_screen.dart';
import 'create_account.dart';

void main() async {
  // Ensure the flutter framework is initialized before using await
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  // Initialize database before we need to access it
  await localDatabase.instance.database;
  await Firebase.initializeApp();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser = _auth.currentUser;
  print("Current User: $currentUser");//Debug statement
  // If currentUser is null (No account made) set initial route as creation page
  // Else, set initial route as the home feed
  final String initialRoute = currentUser == null ? '/createaccountscreen' : '/';
  print("Initial Route: $initialRoute");//Debug statement

  runApp(MyApp(initialRoute: initialRoute)); 
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      initialLocation: initialRoute, 
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeFeed(title: 'ChicoCache'),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Profile(title: 'Profile!'),
        ),
        GoRoute(
          path: '/createcache',
          builder: (context, state) => const CreateCache(title: 'Create Cache!'),
        ),
        GoRoute(
          path: '/friendfeed',
          builder: (context, state) => const FriendFeed(title: 'Friend Feed!'),
        ),
        GoRoute(
          path: '/chicofeed',
          builder: (context, state) => const ChicoFeed(title: 'Chico Feed!'),
        ),
        GoRoute(
          path: '/createaccountscreen',
          builder: (context, state) => const CreateAccount(title: 'Create Account!'),
        ),
        
      ],
    );

    return MaterialApp.router(
      title: 'ChicoCache',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 41, 209, 26)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
