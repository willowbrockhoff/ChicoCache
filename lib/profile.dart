import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'sync_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';
import 'dart:async';

import 'dart:convert';

class Profile extends StatefulWidget {
  const Profile({super.key, required this.title});
  final String title;
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Future<DocumentSnapshot>? userDocFuture;

  int _selectedIndex = 0;
  final _imagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SyncManager sm = SyncManager.instance;
  String? _base64Image;
  XFile? _selectedImage;
  String? _profilePic;
  File? _image;

  @override
  void initState() {
    super.initState();
    userDocFuture = _getUserInfo();
  }

  @override
  void dispose() {
    _imagController.dispose();
    super.dispose();
  }

  /*Future<void> _fetchProfilePic() async {

    try {
      //final userProfilePic = await sm.firestore.collection('profilepics')
         
         
         // .doc(FirebaseAuth.instance.currentUser?.uid) 
          .doc('sYiWDc0aOic87BeoWyLMzGrh76i1')
          .get();
      
      if (userProfilePic.exists) {
        setState(() {
          _profilePic = userProfilePic.data()?['profile_pic'];
        });
      }
    } catch (e) {
      print("Error fetching profile picture: $e");
      setState((){
        _profilePic = null;
      });
    }
  }*/

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);
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
  }

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

  Future<void> _getImage() async {
    final ImagePicker picker = ImagePicker();
    // capture an image from the camera
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // Android
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  Future<DocumentSnapshot> _getUserInfo() async {
    // Get user data from firestore
    try {
      DocumentSnapshot fetchedUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser
              ?.uid) // Replace 'userID' with the actual user's ID
          .get();

      return fetchedUserDoc; //Return the fetched data
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow; // Thorw again to catch it
    }
  }

/*

Future<DocumentSnapshot> _getUserInfo() async { // Get user data from firestore
    try {
      DocumentSnapshot fetchedUserDoc = await FirebaseFirestore.instance 
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid) // Replace 'userID' with the actual user's ID
          .get();

      return fetchedUserDoc;//Return the fetched data
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;// Thorw again to catch it
    }
  }

Future<void> _getImage() async {
    final ImagePicker picker = ImagePicker();
    // capture an image from the camera
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if(photo != null) {
      // Android
        setState((){
          _image = File(photo.path);
        });
      }
  }

Future<void> _upload() async {
    // If an image exists:
    if(_image != null) {
      // Generate a v4 (random) id (universally unique identifier)
      const uuid = Uuid();
      final String uid = uuid.v4();
      // Upload image file to storage (using uid) and generate a downloadURL
      final String downloadURL = await _uploadFile(uid);
      // Add downloadURL (ref to the image) to the database
      //await _addItem(downloadURL, uid);
      // Navigate to the photos screen
      if(mounted) {
        context.go('/photos');
      }
    }
  }

Future<String> _uploadFile(String filename) async {
    // Create a reference to file location in Google Cloud Storage object
    Reference ref = FirebaseStorage.instance.ref().child('$filename.jpg');
    // Add metadata to the image file
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
    );
    // Upload the file to Storage
    UploadTask uploadTask;
    
    uploadTask = ref.putFile(_image!, metadata);
  
    TaskSnapshot uploadResult = await uploadTask;
    // After the upload task is complete, get a (String) download URL
    final String downloadURL = await uploadResult.ref.getDownloadURL();
    // Return the download URL (to be used in the database entry)
    return downloadURL;
  }
  // Add entry to Cloud Firestore database (in the photos collection)
Future<void> _addItem(String downloadURL, String id) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
                    'profile_picture': downloadURL,
                    'title' : id,
                  }, SetOptions(merge: true));
  }


Future<DocumentSnapshot> _getUserInfo() async { // Get user data from firestore
    try {
      DocumentSnapshot fetchedUserDoc = await FirebaseFirestore.instance 
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid) // Replace 'userID' with the actual user's ID
          .get();

      return fetchedUserDoc;//Return the fetched data
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;// Thorw again to catch it
    }
  }

*/

  @override
/*Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/images/fishkitten.png',
                      fit: BoxFit.cover,
                    ),
                    
                    
                    //const Icon(Icons.person, size: 100),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90.0),
                    ),
                    backgroundColor: const Color.fromARGB(255, 115, 181, 110),
                    minimumSize: Size(170, 50),
                  ),
                  onPressed: () async {
                      await _showFriendsPopup(context);
                    },
                  child: Text(
                    "Friends",
                    style: GoogleFonts.abrilFatface(
                      fontSize: 20.0,
                      color:  Color.fromARGB(255, 16, 43, 92),
                    ),
                    ),
                ),
                  
                ],
              ),
            ),
              Padding( 
                padding: const EdgeInsets.only(left: 50.0),
                child: Align(alignment: Alignment.centerLeft,
                  child: Text(
                    'username',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 16, 43, 92),
                    ),
                  ),
                ),
              ),
               const SizedBox(height: 30),
               Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(
              "Geocaches found:",
              style: GoogleFonts.abrilFatface(
              fontSize: 30.0,
              color: const Color.fromARGB(255, 16, 43, 92),
              ),
            ),
          )   
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "     0", // Placeholder for Geocaches found count
              style: GoogleFonts.abrilFatface(
                fontSize: 25.0,
                color: const Color.fromARGB(255, 16, 43, 92),
              ),
            ),
          ),
        ),
        const SizedBox(height: 150),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(
              "Geocahces created:",
              style: GoogleFonts.abrilFatface(
              fontSize: 25.0,
              color: const Color.fromARGB(255, 16, 43, 92),
              ),
            ),
          )   
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "     0", // Placeholder for Geocaches created count
              style: GoogleFonts.abrilFatface(
                fontSize: 30.0,
                color: const Color.fromARGB(255, 16, 43, 92),
              ),
            ),
          ),
        ),
        
        
               /*Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    //child: _selectedImage != null
                    /*? Image.file(
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
                    ),*/
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () async{
                      
                      if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                        if (_base64Image == null) {
                          _base64Image = "";
                        }
                        await sm.uploadProfilePic(
                          //FirebaseAuth.instance.currentUser!.uid,
                          'sYiWDc0aOic87BeoWyLMzGrh76i1',
                          _base64Image!,
                        );
                        await _fetchProfilePic();
                      }
                    },
                    child: Text('Submit'),
                  ), 
                ],
              ),*/
              /*SizedBox(height: 20),
              // Display the profile picture below the image info section
              _profilePic != null
                ? Image.memory(
                    base64Decode(_profilePic!),
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  )
                : Text("No profile picture available."),*/
            ], //children
          ),
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
       // Add Positioned button for "Update Profile" in the upper-right corner
    floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    floatingActionButton: Positioned(
      bottom: 20,
      right: 16,
      child: ElevatedButton( // Upper right hand corner, Update Profile button
        onPressed: () async {
          DocumentSnapshot? userDoc = await userDocFuture;
          if(userDoc != null){ // Avoids runtime error if we are still fetching user info
            _showUpdateProfileDialog(userDoc);
           // _showUpdateProfileDialog();
         }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.8), // Blends in with background a bit
          foregroundColor: const Color.fromARGB(255, 16, 43, 92),
          elevation: 0, // No shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1), // Border info
        ),
        child: const Text(
          'Update Profile',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    ),





    );
  }
*/

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: GoogleFonts.abrilFatface(
            fontSize: 32.0,
            color: const Color.fromARGB(255, 16, 43, 92),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          // Use Stack to position elements
          children: [
            // Your existing content goes here
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/fishkitten.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(90.0),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 115, 181, 110),
                            minimumSize: Size(170, 50),
                          ),
                          onPressed: () async {
                            await _showFriendsPopup(context);
                          },
                          child: Text(
                            "Friends",
                            style: GoogleFonts.abrilFatface(
                              fontSize: 20.0,
                              color: Color.fromARGB(255, 16, 43, 92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /* ElevatedButton(
              onPressed: () async {
                DocumentSnapshot? userDoc = await userDocFuture;
                if (userDoc != null) { // Avoids runtime error if we are still fetching user info
                  _showUpdateProfileDialog(userDoc);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.8), // Blends in with background a bit
                foregroundColor: const Color.fromARGB(255, 16, 43, 92),
                elevation: 0, // No shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1), // Border info
              ),
              child: const Text(
                'Update Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),*/

                  // More content (username, geocache counts, etc.)
                  Padding(
                    padding: const EdgeInsets.only(left: 50.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'rwillowb',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 16, 43, 92),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Geocaches found:",
                        style: GoogleFonts.abrilFatface(
                          fontSize: 30.0,
                          color: const Color.fromARGB(255, 16, 43, 92),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "     0", // Placeholder for Geocaches found count
                        style: GoogleFonts.abrilFatface(
                          fontSize: 25.0,
                          color: const Color.fromARGB(255, 16, 43, 92),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 150),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Geocaches created:",
                        style: GoogleFonts.abrilFatface(
                          fontSize: 25.0,
                          color: const Color.fromARGB(255, 16, 43, 92),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "     0", // Placeholder for Geocaches created count
                        style: GoogleFonts.abrilFatface(
                          fontSize: 30.0,
                          color: const Color.fromARGB(255, 16, 43, 92),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Positioned Update Profile button
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
          fontSize: 16.0,
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

  void _showUpdateProfileDialog(DocumentSnapshot? userDoc) {
    TextEditingController usernameController = TextEditingController(
      text: userDoc?.data() != null
          ? (userDoc?.data() as Map<String, dynamic>)['username'] ?? ''
          : '',
    );

    // Show the dialog with an option to pick an image
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  //await _getImage();
                  //await _upload();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Photo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (userId.isEmpty) {
                    print("No user is logged in.");
                    return;
                  }
                  // Update Firestore with new profile information
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .set({
                    'username': usernameController.text,
                  }, SetOptions(merge: true));

                  // Refresh user data and update the UI
                  setState(() {
                    userDocFuture = _getUserInfo();
                  });

                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error updating profile: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFriendsPopup(BuildContext context) async {
    //List<Map<String, dynamic>> friends = await _fetchFriends();
    List<Map<String, dynamic>> friends = [
      {"name": "Drew"},
    ];

    String imagePath = '/mnt/data/kittenterrorist.webp';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Friends'),
          content: friends.isNotEmpty
              ? SizedBox(
                  width: double.maxFinite,
                  height: 300.0,
                  child: ListView.separated(
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset(
                            'assets/images/kittenterrorist.webp', // Make sure the path is correct
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          friends[index]['name'] ?? "Unknown",
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(
                        thickness: 1.0,
                        color: Colors.grey,
                      );
                    },
                  ),
                )
              : const Text('No friends found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

/*Future<List<Map<String, dynamic>>> _fetchFriends() async {
  final db = await sm._getDatabase(); // Replace with your DB access function
  final result = await db.query('friends'); // Query the local 'friends' table
  return result; // Return the list of friends
}*/
}
