import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'storage.dart';

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:flutter/material.dart';
//import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class SyncManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final localDatabase _dbInstance = localDatabase.instance;
  //final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Database> _getDataBase() async {
    return await _dbInstance.database;
  }

  Future<void> syncUsers() async {
    final db = await _getDataBase();

    int? lastSync = await _getLastSyncTime('users');
    Query query = _firestore.collection('users');
    // Only query data newer than our most current local record
    if (lastSync != null) {
      query = query.where(
        'updatedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastSync)
      );
    }

    final batch = db.batch();
    QuerySnapshot qs = await query.get();
    DateTime maxLastUpdated = DateTime(1970, 1, 1);
    for (final doc in qs.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final lastUpdated = data['lastUpdated'] as Timestamp;
      final lastUpdatedDate = lastUpdated.toDate();

      if (lastUpdatedDate.isAfter(maxLastUpdated)) {
        // This checks helps keep our timestamps sane, if Firebase returns
        //  an illogical value, this will ensure it gets updated to Jan 1 1970,
        //  which ensures the next time we request data it'll be updated.
        maxLastUpdated = lastUpdatedDate;
      }

      batch.insert(
        'users',
        {
          'user_id': doc.id,
          'username': data['username'],
          'profile_pic': data['profile_pic'],
          'geocaches_found': data['geocaches_found'],
          'geocaches_created': data['geocaches_created'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _setLastSyncTime('users', maxLastUpdated);
      await batch.commit();
    }
  }

  Future<void> syncGeocaches() async {
    final db = await _getDataBase();

    int? lastSync = await _getLastSyncTime('geocaches');
    Query query = _firestore.collection('geocaches');
    // Only query data newer than our most current local record
    if (lastSync != null) {
      query = query.where(
        'updatedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastSync)
      );
    }

    final batch = db.batch();
    QuerySnapshot qs = await query.get();
    DateTime maxLastUpdated = DateTime(1970, 1, 1);
    for (final doc in qs.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final geoPoint =data['location'] as GeoPoint;
      final lat = geoPoint.latitude;
      final long = geoPoint.longitude; // Appreciate long not being reserved

      final lastUpdated = data['lastUpdated'] as Timestamp;
      final lastUpdatedDate = lastUpdated.toDate();

      if (lastUpdatedDate.isAfter(maxLastUpdated)) {
        maxLastUpdated = lastUpdatedDate;
      }

      batch.insert(
        'geocaches',
        {
          'cache_id': doc.id,
          'creator_comments': data['creator_comments'],
          'creator_id': data['creator_id'],
          'creator_photos': data['creator_photos'],
          'difficulty': data['difficulty'],
          'latitude': lat,
          'longitude': long,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _setLastSyncTime('geocaches', maxLastUpdated);
      await batch.commit();
    }
  }

  Future<void> syncComments() async {
    final db = await _getDataBase();

    int? lastSync = await _getLastSyncTime('comments');
    Query query = _firestore.collection('comments');
    // Only query data newer than our most current local record
    if (lastSync != null) {
      query = query.where(
        'updatedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastSync)
      );
    }

    final batch = db.batch();
    QuerySnapshot qs = await query.get();
    DateTime maxLastUpdated = DateTime(1970, 1, 1);
    for (final doc in qs.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final lastUpdated = data['lastUpdated'] as Timestamp;
      final lastUpdatedDate = lastUpdated.toDate();

      if (lastUpdatedDate.isAfter(maxLastUpdated)) {
        maxLastUpdated = lastUpdatedDate;
      }

      batch.insert(
        'comments',
        {
          'comment_id': doc.id,
          'cache_id': data['cache_id'],
          'comment_photos': data['comment_photos'],
          'comment_text': data['comment_text'],
          'timestamp': (data['timestamp'] as Timestamp).toDate().microsecondsSinceEpoch,
          'user_id': data['user_id'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _setLastSyncTime('friends', maxLastUpdated);
      await batch.commit();
    }
  }

  Future<void> syncFriends() async {
    final db = await _getDataBase();

    int? lastSync = await _getLastSyncTime('friends');
    Query query = _firestore.collection('friends');
    // Only query data newer than our most current local record
    if (lastSync != null) {
      query = query.where(
        'updatedAt', isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(lastSync)
      );
    }

    final batch = db.batch();
    QuerySnapshot qs = await query.get();
    DateTime maxLastUpdated = DateTime(1970, 1, 1);
    for (final doc in qs.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final lastUpdated = data['lastUpdated'] as Timestamp;
      final lastUpdatedDate = lastUpdated.toDate();

      if (lastUpdatedDate.isAfter(maxLastUpdated)) {
        maxLastUpdated = lastUpdatedDate;
      }

      batch.insert(
        'friends',
        {
          'user_id': data['friendOne'],
          'friend_id': data['friendTwo'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _setLastSyncTime('friends', maxLastUpdated);
      await batch.commit();
    }
  }

  Future<void> syncUserData(User user) async {
    try {
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid); 
      await userRef.set({
        'name': user.displayName ?? 'Unknown',
        'email': user.email ?? 'No email',
        'createdAt': Timestamp.now(),
      });
      print('User data synced to Firestore');
    } catch (e) {
      print('Error syncing user data to Firestore: $e');
    }
  }
  Future<void> syncDataForAuthenticatedUser() async {
    try {
      await syncUsers();    // Sync users data
      await syncGeocaches();// Sync geocache data
      await syncComments(); // Sync comments data
      await syncFriends(); // Sync friends data
    } catch (e) {
      print("Error syncing data for authenticated user: $e");
    }
  }

  Future<int?> _getLastSyncTime(String collectionName) async {
    final db = await _getDataBase();
    final List<Map<String, dynamic>> result = await db.query(
      'SyncStatus',
      columns: ['lastSyncTime'],
      where: 'collectionName = ?',
      whereArgs: [collectionName],
    );

    if (result.isNotEmpty) {
      return Future.value(result.first['lastSyncTime'] as int?);
    }
    return Future.value(null);
  }

  Future<void> _setLastSyncTime(String collectionName, DateTime timestamp) async {
    final db = await _getDataBase();
    await db.insert(
      'SyncStatus',
      {
        'collectionName': collectionName,
        'lastSyncTime': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}