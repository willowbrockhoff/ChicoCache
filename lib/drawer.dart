import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key, required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 17, 255, 100),
            ),
            child: Text('ChicoCache Drawer'),
          ),
          currentPage == 1
          ? const SizedBox.shrink()
          : ListTile(
            title: const Text('Home'),
            onTap: () {
              context.go('/');
            },
          ),
          /*currentPage == 2
          ? const SizedBox.shrink()
          : ListTile(
            title: const Text('Profile Page'),
            onTap: () {
              context.go('/profile');
            },
          ),
          currentPage == 3
          ? const SizedBox.shrink()
          : ListTile(
            title: const Text('Create Cache'),
            onTap: () {
              context.go('/createcache');
            },
          ),*/
        ],
      )
    );
  }
}
