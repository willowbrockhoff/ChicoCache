import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'homefeed.dart';
import 'profile.dart';
import 'storage.dart';
import 'create_cache.dart';
import 'friend_feed.dart';
import 'chico_feed.dart';
//import 'createaccount.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder:(context, state) => const HomeFeed(title: 'ChicoCache')
    ),
    GoRoute(
      path: '/profile',
      builder : (context, state) => const Profile(title: 'Profile!')
    ),
    GoRoute(
      path: '/createcache',
      builder: (context, state) => const CreateCache(title: 'Create Cache!')
    ),
    GoRoute(
      path: '/friendfeed',
      builder: (context, state) => const FriendFeed(title: 'Friend Feed!')
    ),
    GoRoute(
      path: '/chicofeed',
      builder: (context, state) => const ChicoFeed(title: 'Chico Feed!')
    ),
    
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
   
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      
        title: Text(widget.title),
      ), 
    );
  }
}
