import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Photos extends StatelessWidget {
  const Photos({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('User Photos'),
      ),
      
      body: Center(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            switch(snapshot.connectionState) {
              case ConnectionState.waiting:
                return const Center(child: CircularProgressIndicator());
              default:
                if(snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.all(4.0),
                    itemCount: snapshot.data!.size,
                    itemBuilder: (context, index) {
                      return PhotoWidget(snap: snapshot, idx: index);
                    }
                  );
                }
            }
          }
        ),
      ),
    );
  }
}

class PhotoWidget extends StatelessWidget {
  const PhotoWidget({ super.key, required this.snap, required this.idx });

  final AsyncSnapshot<QuerySnapshot> snap;
  final int idx;

  @override
  Widget build(BuildContext context) {
    try {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(snap.data!.docs[idx]['title']),
              subtitle: snap.data!.docs[idx].data().toString().contains('timestamp')
              ? Text(
                DateTime.fromMillisecondsSinceEpoch(snap.data!.docs[idx]['timestamp'].seconds * 1000).toString())
              : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 400,
                child: Image.network(snap.data!.docs[idx]['downloadURL'])),
            ),
          ],
        ),
      );
    } catch(e) {
      return Text('Error: ${snap.error} (no data)');
    }
  }
}
