import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CreateCache extends StatefulWidget{
  const CreateCache({super.key, required this.title});
  final String title;
  @override
  State<CreateCache> createState() => _CreateCacheState();
}

class _CreateCacheState extends State<CreateCache> {
  late GoogleMapController mapCont;
  final LatLng _center = const LatLng(-33.86, 151.20);

  void _onMapCreated(GoogleMapController controller) {
    mapCont = controller;
  }
 
  int _selectedIndex = 0;
  
  void _onItemTapped(int index){ // _onItemTapped runs the bottomNavigationBar
    setState((){
      _selectedIndex = index;
    });
    switch(index){
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
        title: Text( // Title at top left of page
          widget.title,
          style: GoogleFonts.abrilFatface(
            fontSize: 32.0,
            color: const Color.fromARGB(255, 16, 43, 92), 
          )
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded (
                  child: Container(
                    height: 400,
                    child: GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 11.0,
                      ),
                    ),
                  ),
                ),
              ], 
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar( // Bottom navigation bar with Home, Upload, and Profile buttons.
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
              icon: Icon(Icons.person,
              color: const Color.fromARGB(255, 115, 181, 110),
              ),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,  
          
          selectedLabelStyle: const TextStyle( //selctedItemColor and unselctedItemColor embolden the Home, Upload, and Profile labels
            fontSize: 16.0,                      // both functions set the values the same with the goal of readabilty (not clarifying which is pressed)
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