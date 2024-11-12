// To start with we want to setup local storage, then once this is complete we can begin moving this stored data over to firebase.
//  sharedPreferences is generally intended for smaller pieces of data, not massive things like photos. Given we want to store everything locally to start with, what
//  method will support larger data sizes?
// We're gonna go all the way and do a SQFlite database that mirrors firebase.

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class localDatabase extends Sqflite{
    static Database? _database;

    // By utilizing a private constructor, we prevent other parts of the
    //  app from erroneously trying to create their own db.
    // Because we made it static, it will be globally accessible, so
    //  other parts of the app still have *a* database to access 
    localDatabase._privateConstructor();
    static final localDatabase instance = localDatabase._privateConstructor();

    // This is called 'lazy' because we only initialize the db on the
    //  first request to access it, NOT when the app starts up for
    //  the first time.
    Future<Database> get database async {
        // If the database exists, use it
        if (_database != null) return _database!;
        // Implicit else, initialize the database
        _database = await _initDatabase();
        return _database!;
    }

    Future<Database> _initDatabase() async {
        final documentsDirector = await getApplicationDocumentsDirectory();
        final path = join(documentsDirector.path, 'chicocache.db');

        return await openDatabase(
            path,
            version: 1,
            onCreate: _onCreate,
        );
    }

    FutureOr<void> _onCreate(Database db, int version) async {
        // Users table gets generated first, because it hurts my brain the most
        //  on instantiation of a new user, we create a new document in firebase
        //  and then we use the auto-generated document id to set the user_id
        //  for the rest of the database, we save data relative to the user_id
        //  that we store when the account is created.
        //  I'm going to cry if this doesn't work.
        await db.execute('''
            CREATE TABLE users (
                user_id TEXT PRIMARY KEY,
                username TEXT,
                profile_pic TEXT,
                geocaches_found INTEGER,
                geocaches_created INTEGER
            )
        ''');
        // creator_id is set to user_id
        // firebase uses a 'geopoint' data type that stores both long. and lat.
        await db.execute('''
            CREATE TABLE geocaches (
            cache_id TEXT PRIMARY KEY,
            creator_comments TEXT,
            creator_id TEXT,
            creator_photos TEXT,
            difficulty INTEGER,
            latitude REAL,
            longitude REAL,
            FOREIGN KEY (creator_id) REFERENCES users (user_id)
            )
        ''');
        // Utilize user_id to fetch username from user table.
        //  Maybe profile references too if we feel particularly masochistic.
        await db.execute('''
            CREATE TABLE comments (
                comment_id TEXT PRIMARY KEY,
                cache_id TEXT,
                user_id TEXT,
                comment_text TEXT,
                timestamp INTEGER,
                comment_photos TEXT,
                FOREIGN KEY (cache_id) REFERENCES geocaches (cache_id)
                FOREIGN KEY (user_id) REFERENCES users (user_id)
            )
        ''');
        // Utilize user_id to fetch username from user table.
        await db.execute('''
            CREATE TABLE friends (
                user_id TEXT,
                friend_id TEXT,
                PRIMARY KEY (user_id, friend_id),
                FOREIGN KEY (user_id) REFERENCES users (user_id),
                FOREIGN KEY (friend_id) REFERENCES users (user_id)
            )
        ''');
        // This table is used to minimize the synchronization done with firebase
        await db.execute('''
            CREATE TABLE SyncStatus (
              collectionName TEXT PRIMARY KEY,
              lastSyncTime INTEGER
            )
        ''');
    }
}