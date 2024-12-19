import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_manager.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key, required this.title});
  final String title;
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  late GoogleMapController? mapCont;
  StreamSubscription<Position>? _positionStream;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _locationSetup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _locationSetup() async {
    // Check and request location permissions
    final status = await checkAndRequestPermissions();

    if (status) {
      // Permission granted, fetch location
      _startLocationStream();
    }
    // In the else case, they denied permissions. Sucks to be them.
    // Map works normally but doesn't follow and starts at (0.0, 0.0)
    // They should've been prompted with app settings, so it's on them at this point.
  }

  void _onMapCreated(GoogleMapController controller) {
    mapCont = controller;

    if (_position != null && mapCont != null) {
      mapCont!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _position != null
                ? LatLng(_position!.latitude, _position!.longitude)
                : const LatLng(0.0, 0.0),
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> _startLocationStream() async {
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          _position = position;
        });

        // Automatically move the map to the user's location
        if (mapCont != null && _position != null) {
          mapCont!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(_position!.latitude, _position!.longitude),
                zoom: 15,
              ),
            ),
          );
        }
      },
    );
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    // _onItemTapped runs the bottomNavigationBar
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/createcache');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
            // Title at top left of page
            widget.title,
            style: GoogleFonts.abrilFatface(
              fontSize: 32.0,
              color: const Color.fromARGB(255, 16, 43, 92),
            )),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90.0),
                    ),
                    backgroundColor: const Color.fromARGB(255, 115, 181, 110),
                    minimumSize: Size(170, 50),
                  ),
                  onPressed: () {
                    context.go('/chicofeed');
                  },
                  child: Text(
                    "Chico",
                    style: GoogleFonts.abrilFatface(
                      fontSize: 20.0,
                      color: const Color.fromARGB(255, 16, 43, 92),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90.0),
                    ),
                    backgroundColor: const Color.fromARGB(255, 115, 181, 110),
                    minimumSize: const Size(170, 50),
                  ),
                  onPressed: () {
                    context.go('/friendfeed');
                  },
                  child: Text(
                    "Friends",
                    style: GoogleFonts.abrilFatface(
                      fontSize: 20.0,
                      color: const Color.fromARGB(255, 16, 43, 92),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    height: 400,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _position == null
                          ? const CameraPosition(
                              target: LatLng(0.0, 0.0), zoom: 15)
                          : CameraPosition(
                              target: LatLng(
                                  _position!.latitude, _position!.longitude),
                              zoom: 15,
                            ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Bottom navigation bar with Home, Upload, and Profile buttons.
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: const Color.fromARGB(255, 115, 181, 110),
            ),
            label: 'Home',
            backgroundColor: const Color.fromARGB(255, 115, 181, 110),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_circle,
              color: const Color.fromARGB(255, 115, 181, 110),
            ),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: const Color.fromARGB(255, 115, 181, 110),
            ),
            label: 'Profile',
          ),
        ],

        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,

        selectedLabelStyle: const TextStyle(
          //selctedItemColor and unselctedItemColor embolden the Home, Upload, and Profile labels
          fontSize:
              16.0, // both functions set the values the same with the goal of readabilty (not clarifying which is pressed)
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),

        onTap: _onItemTapped,
      ),
    );
  }
}
