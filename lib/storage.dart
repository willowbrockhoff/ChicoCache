// To start with we want to setup local storage, then once this is complete we can begin moving this stored data over to firebase.
//  sharedPreferences is generally intended for smaller pieces of data, not massive things like photos. Given we want to store everything locally to start with, what
//  method will support larger data sizes?
// We're gonna go all the way and do a SQFlite database that mirrors firebase.

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class localDatabase {
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
        await db.execute('''
            CREATE TABLE geocaches (
            cache_id TEXT PRIMARY KEY,
            latitude REAL,
            longitude REAL,
            difficulty INTEGER,
            creator_id TEXT,
            creator_comments TEXT,
            creator_photos TEXT
            )
        ''');
        await db.execute('''
            CREATE TABLE comments (
                comment_id TEXT PRIMARY KEY,
                cache_id TEXT,
                user_id TEXT,
                comment_text TEXT,
                timestamp INTEGER,
                comment_photos TEXT,
                FOREIGN KEY (cache_id) REFERENCES geocaches (cache_id)
            )
        ''');
        await db.execute('''
            CREATE TABLE users (
                user_id TEXT PRIMARY KEY,
                username TEXT,
                profile_pic TEXT,
                friends_list TEXT
            )
        ''');
        await db.execute('''
            CREATE TABLE geocaching_statistics (
                user_id TEXT PRIMARY KEY,
                geocaches_found INTEGER,
                time_found TEXT,
                geocaches_created INTEGER,
                FOREIGN KEY (user_id) REFERENCES users (user_id)
            )
        ''');
        await db.execute('''
            CREATE TABLE friends (
                user_id TEXT,
                friend_id TEXT,
                PRIMARY KEY (user_id, friend_id),
                FOREIGN KEY (user_id) REFERENCES users (user_id),
                FOREIGN KEY (friend_id) REFERENCES users (user_id)
            )
        ''');
    }
}