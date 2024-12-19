import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // fetching uuid
import 'package:cloud_firestore/cloud_firestore.dart'; // fetching profile_pic
import 'package:project/create_account_screen.dart';

import 'sync_manager.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';


class Profile extends StatefulWidget{
  const Profile({super.key, required this.title});
  final String title;
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
 
  int _geocachesCreated = 0;
  int _selectedIndex = 0;
  final _usernameController = TextEditingController();
  final _imageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SyncManager sm = SyncManager();
  String? _base64Image;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchGeocacheCount();
  }

  @override dispose() {
    _usernameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    if(pickedFile != null){
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
  }

Future<void> _fetchGeocacheCount() async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Query the geocaches collection to count documents where creator_id matches the current user's UID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('geocaches')
          .where('creator_id', isEqualTo: currentUserUid)
          .get();

      // Update the geocaches count
      setState(() {
        _geocachesCreated = querySnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching geocache count: $e');
    }
  }

  Future<Map<String, String?>> getProfileData(String userUid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
    if(doc.exists){
      return {
        'profile_pic': doc.data()?['profile_pic'],
        'username': doc.data()?['username'],
      };
    }
    return {'profile_pic' : null, 'username': null};
  }

  Future<List<String>> getFriendsList(String userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists && doc.data() != null) {
    return List<String>.from(doc.data()!['friends'] ?? []);
  }
  return [];
}
      

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding( //DISPLAYS PROFILE PICTURE AND USERNAME
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: FutureBuilder<Map<String, String?>>(
                  future: getProfileData(FirebaseAuth.instance.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container( // PROGRESS INDICATOR
                        height: 250,
                        width: 250,
                        color: Colors.grey[300],
                        child: const CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                      return Column(
                      children: [
                        Container( //PROFILE DEFAULT ICON
                          height: 250,
                          width: 250,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 150),
                        ),  
                      ],
                    );
                    } else { 
                      final data = snapshot.data!;
                      final base64Image = data['profile_pic'];
                      final username = data['username'];
                      return Column(
                        children: [
                          Container( //PROFILE PICTURE DISPLAY
                            height: 250,
                            width: 250,
                            color: Colors.grey[300], // Grey background for the icon and image
                            child: base64Image != null && base64Image.isNotEmpty
                                ? Image.memory(
                                    base64Decode(base64Image),
                                    height: 250,
                                    width: 250,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.person, size: 150),
                          ),
                          const SizedBox(height: 20),
                          username != null && username.isNotEmpty
                              ? Text( // USERNMAE DISPLAY
                                username,
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : const Text( 
                                'Username',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          const SizedBox(height: 20),
                          ElevatedButton( //FRIENDS BUTTON
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(90.0),
                              ),
                              backgroundColor: const Color.fromARGB(255, 115, 181, 110),
                              minimumSize: const Size(170, 50),
                            ),
                            onPressed: () async 
                            {
                              final friends = await getFriendsList(FirebaseAuth.instance.currentUser!.uid);
                               
                               showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Friends"),
                                    content: friends.isNotEmpty
                                        ? SizedBox(
                                            height: 200, 
                                            width: 300,
                                            child: ListView.builder(
                                              itemCount: friends.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Text(friends[index]),
                                                  trailing: IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                                onPressed: () async {
                                                  try {
                                                    final currentUser = FirebaseAuth.instance.currentUser;
                                                    final friendId = friends[index];

                                                    if (currentUser != null && friendId.isNotEmpty) {
                                                      final userId = currentUser.uid;

                                                      // Remove the friend's ID from the current user's friend list in Firestore
                                                      await FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(userId)
                                                          .update({
                                                        'friends': FieldValue.arrayRemove([friendId])
                                                      });

                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Removed $friendId from your list!'),
                                                          duration: const Duration(seconds: 2),
                                                        ),
                                                      );

                                                      Navigator.of(context).pop(); // Close the dialog after removing the friend
                                                    }
                                                  } catch (e) {
                                                    print('Error removing friend: $e');
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to remove friend!'),
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                },
                                              )
                                                );
                                              },
                                            ),
                                          )
                                        : const Text("You have no friends added yet."),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  );
                                },
                              );                        
                            },

                              child: Text(
                              "Friends",
                              style: GoogleFonts.abrilFatface(
                                fontSize: 20.0,
                                color: const Color.fromARGB(255, 16, 43, 92),
                              ),
                            ),                         
                          ),
                          const SizedBox(height: 20),
                            // Displaying the geocache count
                            Text(
                              'Geocaches Created: $_geocachesCreated',
                              style: const TextStyle(
                                fontSize: 20.0,
                                //fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      );

                    }
                  },
                ),
              ),
                
            ),
            
            ],
          )
        ),
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

      floatingActionButton: Padding( //UPDATE PROFILE BUTTON
        padding: const EdgeInsets.only(bottom: 20.0),
        child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.8),
          foregroundColor: const Color.fromARGB(255, 16, 43, 92),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.person),
                          hintText: 'Username',
                          labelText: 'Username',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter a username' : null,
                      ),
                      const SizedBox(height: 20),
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
                                    child: const Icon(Icons.add_a_photo, size: 50),
                                  ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (_base64Image == null) {
                                  _base64Image = "";
                                }
                                await sm.updateProfile(
                                  _usernameController.text,
                                  FirebaseAuth.instance.currentUser!.uid,
                                  _base64Image!,
                                );
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Text(
          'Update Profile',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      ),

    );
}



}