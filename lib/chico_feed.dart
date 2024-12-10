import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'sync_manager.dart';
import 'location_manager.dart';

class ChicoFeed extends StatefulWidget {
  const ChicoFeed({super.key, required this.title});
  final String title;
  @override
  State<ChicoFeed> createState() => _ChicoFeedState();
}

class _ChicoFeedState extends State<ChicoFeed> {
  late GoogleMapController? mapCont;
  late GoogleMapController? miniMapCont;
  StreamSubscription<Position>? _positionStream;
  SyncManager sm = SyncManager.instance;
  Position? _position;
  List<Map<String, dynamic>> _geocacheData = [
    {
      "cache_id": "test1",
      "latitude": 39.7285,
      "longitude": -121.8375,
      "creator_comments": "If this pops up, it hasn't loaded yet",
      "difficulty": 2,
    },
    {
      "cache_id": "test2",
      "latitude": 39.7320,
      "longitude": -121.8450,
      "creator_comments": "This one is gratuitous",
      "difficulty": 3,
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageSetup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _pageSetup() async {
    // Check and request location permissions
    final status = await checkAndRequestPermissions();
    if (status) {
      // Permission granted, fetch location
      _startLocationStream();
    }

    final List<Map<String, dynamic>> geocaches = await sm.loadGeocacheData();
    print("Geocaches loaded: $geocaches");
    if (geocaches.isNotEmpty) {
      print("################ GEOCACHES NOT EMPTY ########################");
      setState(() {
        _geocacheData = geocaches;
      });
    }
    await sm.syncGeocaches();
  }

  void _onMainMapCreated(GoogleMapController controller) {
    mapCont = controller;
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
                zoom: 20,
              ),
            ),
          );
        }
      },
    );
  }

  LatLng initCameraPos(final Map<String, dynamic> geocache) {
    if (geocache['longitude'] != null) {
      if (geocache['latitude'] != null) {
        return LatLng(geocache['latitude'], geocache['longitude']);
      }
    }
    return const LatLng(0.0, 0.0);
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

  Widget _buildGeocacheList() {
    return ListView.builder(
      physics: const PageScrollPhysics(),
      shrinkWrap: true,
      itemCount: _geocacheData.length,
      itemBuilder: (context, index) {
        final geocache = _geocacheData[index];
        return ListTile(
          title: Text(
            geocache['cache_id'] ?? 'No title',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Difficulty: ${geocache['difficulty']}'),
          trailing: const Icon(Icons.place, color: Colors.green),
          onTap: () {
            final LatLng loc =
                LatLng(geocache['latitude'], geocache['longitude']);
            final String? image = geocache['creator_photos'] as String?;
            Uint8List? imageBytes;
            if (image != null) {
              imageBytes = base64Decode(image);
            }

            if (mapCont != null) {
              mapCont!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: loc,
                    zoom: 15,
                  ),
                ),
              );
            }

            showModalBottomSheet(
                context: context,
                builder: (builder) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "lat, lon: ${loc.latitude}, ${loc.longitude}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          leading: imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image,
                                  size: 50,
                                ),
                          title: Text(geocache['creator_comments']),
                        ),
                        ListTile(
                          leading: const Icon(Icons.terrain),
                          title: const Text("Difficulty"),
                          subtitle: Text("${geocache['difficulty']}"),
                        ),
                      ],
                    ),
                  );
                });
          },
        );
      },
    );
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

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              child: GoogleMap(
                onMapCreated: _onMainMapCreated,
                initialCameraPosition: _position == null
                    ? const CameraPosition(target: LatLng(0.0, 0.0), zoom: 20)
                    : CameraPosition(
                        target:
                            LatLng(_position!.latitude, _position!.longitude),
                        zoom: 20,
                      ),
                markers: _geocacheData.map((geocache) {
                  return Marker(
                    markerId: MarkerId(geocache['cache_id']),
                    position:
                        LatLng(geocache['latitude'], geocache['longitude']),
                    infoWindow: InfoWindow(
                      title: geocache['creator_comments'],
                      snippet: 'Difficulty: ${geocache['difficulty']}',
                    ),
                  );
                }).toSet(),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildGeocacheList();
              },
              childCount: 1,
            ),
          ),
        ],
      ),

      // body: Column(
      //   children: [
      //     Padding(
      //       padding: const EdgeInsets.symmetric(vertical: 18.0), // Chico and Friend Feed buttons.
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //         children: [
      //           ElevatedButton(
      //             style: ElevatedButton.styleFrom(
      //               shape: RoundedRectangleBorder(
      //                 borderRadius: BorderRadius.circular(90.0),
      //               ),
      //               backgroundColor: const Color.fromARGB(255, 115, 181, 110),
      //               minimumSize: Size(170, 50),
      //             ),
      //             onPressed: () {
      //                 context.go('/chicofeed');
      //             },
      //             child: Text(
      //               "Chico",
      //               style: GoogleFonts.abrilFatface(
      //                 fontSize: 20.0,
      //                 color:  Color.fromARGB(255, 16, 43, 92),
      //               ),
      //             ),
      //           ),
      //           ElevatedButton(
      //             style: ElevatedButton.styleFrom(
      //               shape: RoundedRectangleBorder(
      //                 borderRadius: BorderRadius.circular(90.0),
      //               ),
      //               backgroundColor: const Color.fromARGB(255, 115, 181, 110),
      //               minimumSize: Size(170, 50),
      //             ),
      //             onPressed: () {
      //               context.go('/friendfeed');
      //             },
      //             child: Text(
      //               "Friends",
      //               style: GoogleFonts.abrilFatface(
      //                 fontSize: 20.0,
      //                 color:  Color.fromARGB(255, 16, 43, 92),
      //               ),
      //               ),
      //           ),
      //         ],
      //       ),
      //     ),
      //     Padding(
      //       padding: const EdgeInsets.symmetric(vertical: 18.0),
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //         children: [
      //           Expanded (
      //             child: Container(
      //               height: 400,
      //               child: GoogleMap(
      //                 onMapCreated: _onMapCreated,
      //                 initialCameraPosition: _position == null
      //                     ? const CameraPosition(target: LatLng(0.0, 0.0), zoom: 20)
      //                     : CameraPosition(
      //                         target: LatLng(_position!.latitude, _position!.longitude),
      //                         zoom: 20,
      //                       ),
      //               ),
      //             )
      //           )
      //         ]
      //       )
      //     )
      //   ],
      // ),

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
