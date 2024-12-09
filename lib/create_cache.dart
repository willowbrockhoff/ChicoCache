import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'location_manager.dart';
import 'sync_manager.dart';

class CreateCache extends StatefulWidget{
  const CreateCache({super.key, required this.title});
  final String title;
  @override
  State<CreateCache> createState() => _CreateCacheState();
}

class _CreateCacheState extends State<CreateCache> {
  final _nameController = TextEditingController();
  final _longController = TextEditingController();
  final _latiController = TextEditingController();
  final _descController = TextEditingController();
  final _diffController = TextEditingController();
  final _imagController = TextEditingController();
  StreamSubscription<Position>? _positionStream;
  final _formKey = GlobalKey<FormState>();
  late GoogleMapController? mapCont;
  SyncManager sm = SyncManager.instance;
  String? _base64Image;
  XFile? _selectedImage;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _locationSetup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _nameController.dispose();
    _longController.dispose();
    _latiController.dispose();
    _descController.dispose();
    _imagController.dispose();
    super.dispose();
  }

  Future<void> _locationSetup() async {
    final status = await checkAndRequestPermissions();
    if (status) {
      _startLocationStream();
    }
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
            zoom: 20,
          ),
        ),
      );
    }
  }

  Future<void> _startLocationStream() async {
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        setState(() {
          _position = position;
          _longController.text = position.longitude.toString();
          _latiController.text = position.latitude.toString();
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera); 
    // We can add the option for gallery as well by usering 'ImageSource.gallery'

    if (pickedFile != null) {
      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        "${pickedFile.path}_compressed.jpg",
        minWidth: 640,
        minHeight: 480,
        quality: 80,
      );

      if (compressedFile != null) {
        // Iteratively compress until size < maxSizeInKB
        int fileSizeInKB = await compressedFile.length() ~/ 1024;
        int currentQuality = 80;

        while (fileSizeInKB > 300 && currentQuality > 10) {
          currentQuality -= 10; // Reduce quality in steps
          compressedFile = await FlutterImageCompress.compressAndGetFile(
            compressedFile!.path,
            "${compressedFile!.path}_compressed.jpg",
            quality: currentQuality,
          );
          if (compressedFile == null) return;
          fileSizeInKB = await compressedFile.length() ~/ 1024;
        }

        var bytes = await compressedFile?.readAsBytes();
        if (bytes != null) {
          String temp64Image = base64Encode(bytes!);
          if (compressedFile != null) {
            setState(() {
              _selectedImage = compressedFile;
              _base64Image = temp64Image;
            });
          }
        }
      }
    }

    // File? imageFile;
    // if (pickedFile != null) {
    //   imageFile = File(pickedFile!.path);
    // }

    // if (imageFile != null) {
    //   File? compressedFile = await FlutterImageCompress.compressAndGetFile(
    //     imageFile.path,
    //     "${imageFile.path}_compressed.jpg",
    //     minWidth: 640,
    //     minHeight: 480,
    //     quality: 80, // Initial quality setting
    //   );

    //   if (compressedFile != null) {
    //     // Iteratively compress until size < maxSizeInKB
    //     int fileSizeInKB = compressedFile.lengthSync() ~/ 1024;
    //     int currentQuality = 80;

    //     while (fileSizeInKB > 300 && currentQuality > 10) {
    //       currentQuality -= 10; // Reduce quality in steps
    //       compressedFile = await FlutterImageCompress.compressAndGetFile(
    //         compressedFile!.path,
    //         "${compressedFile!.path}_compressed.jpg",
    //         quality: currentQuality,
    //       );
    //       if (compressedFile == null) return;
    //       fileSizeInKB = compressedFile.lengthSync() ~/ 1024;
    //     }

    //     if (compressedFile != null) {
    //       setState(() {
    //         _selectedImage = compressedFile;
    //         _base64Image = compressedFile?.readAsBytesSync() != null
    //           ? base64Encode(compressedFile!.readAsBytesSync())
    //           : "";
    //       });
    //     }
    //   }
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

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                child: SizedBox (
                      height: MediaQuery.of(context).size.height * .3,
                      width: MediaQuery.of(context).size.width,
                      child: GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: _position == null
                            ? const CameraPosition(target: LatLng(0.0, 0.0), zoom: 20)
                            : CameraPosition(
                                target: LatLng(_position!.latitude, _position!.longitude),
                                zoom: 20,
                              ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.newspaper),
                          hintText: 'Bridge Pocket',
                          labelText: 'Geocache Title',
                        ),
                        validator: (value)
                            => value == null || value.isEmpty ? 'Please enter a name' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _longController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.location_pin),
                                hintText: '0.0',
                                labelText: 'Longitude',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a longitude';
                                }
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return 'Please enter a valid longitude';
                                }
                                return null;
                              },
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _latiController,
                              decoration: const InputDecoration(
                                icon: Icon(Icons.location_pin),
                                hintText: '0.0',
                                labelText: 'Latitude',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a latitude';
                                }
                                try {
                                  double.parse(value);
                                } catch (e) {
                                  return 'Please enter a valid latitude';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.comment),
                          hintText: 'It\'s hidden!',
                          labelText: 'Description',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            value = ""; // Default to empty description
                            return null;
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _diffController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.dangerous),
                          hintText: '1-5',
                          labelText: 'Difficulty',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a difficulty level';
                          }
                          try {
                            int diff = int.parse(value);
                            if (diff < 1 || diff > 5) {
                              throw RangeError('Value out of range');
                            }
                          } catch (e) {
                            return 'Please enter a valid integer between 1 and 5';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: _selectedImage != null
                              ? Image.file(
                                  File(_selectedImage!.path),
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                height: 150,
                                width: 150,
                                color: Colors.grey[300],
                                child: Icon(Icons.add_a_photo, size: 50),
                              ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () async{
                              if (_formKey.currentState!.validate()) {
                                if (_base64Image == null) {
                                  _base64Image = "";
                                }
                                await sm.uploadGeocache(
                                  _nameController.text,
                                  _descController.text,
                                  "example string for user id upload geocache form",
                                  _base64Image!,
                                  LatLng(double.parse(_latiController.text), double.parse(_longController.text)),
                                  int.parse(_diffController.text),
                                );
                              }
                            },
                            child: Text('Submit'),
                          ) 
                        ]
                      )         
                    ]
                  ),
                )
              )
            ],
          ),
        )
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