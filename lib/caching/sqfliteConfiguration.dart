// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DatabaseHelper{
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  late Database? _database;
  Future<Database> get database async{
    if(_database != null){
      return _database!;
    }
    await initDatabase();
    return _database!;
  }

  Future<void> initDatabase() async{
    final dbPath = await getDatabasesPath();
    final pathToDatabase = path.join(dbPath, 'cache_database.db');
    _database = await openDatabase(
      pathToDatabase,
      version: 2,
      onCreate: (Database db, int version) async{
        await db.execute(
          """
          CREATE TABLE IF NOT EXISTS feed_posts_data(
            post_data TEXT NOT NULL
          )
          """
        );

        await db.execute(
          """
          CREATE TABLE IF NOT EXISTS feed_comments_data(
            comment_data TEXT NOT NULL
          )
          """
        );
        await db.execute(
          """
          CREATE TABLE IF NOT EXISTS searched_posts_data(
            post_data TEXT NOT NULL
          )
          """
        );
        await db.execute(
          """
          CREATE TABLE IF NOT EXISTS searched_comments_data(
            comment_data TEXT NOT NULL
          )
          """
        );
        await db.execute(
          """
          CREATE TABLE IF NOT EXISTS searched_users_data(
            user_id TEXT NOT NULL
          )
          """
        );
      },
      onUpgrade: ((db, oldVersion, newVersion) async{
        if(oldVersion < 2){
          
        }
      })
    );
  }

  Future<void> replaceFeedPosts(List feedPosts) async{
    final db = await database;
    await db.delete('feed_posts_data');
    await db.transaction((txn) async{
      for(final post in feedPosts){
        await txn.insert('feed_posts_data', {
          'post_data': jsonEncode(post)
        });
      }
    });
  }

  Future<List> fetchPaginatedFeedPosts(int currentLength, int paginationLimit) async{
    final db = await database;
    List<Map> getAllFeedPosts = [];
    await db.query(
      'feed_posts_data',
      offset: currentLength,
      limit: paginationLimit
    ).then((value) async{
      getAllFeedPosts = value;
    });
    final List results = getAllFeedPosts.map((e) => jsonDecode(e['post_data'])).toList();    
    return results;
  }

  Future<void> replaceFeedComments(List feedComments) async{
    final db = await database;
    await db.delete('feed_comments_data');
    await db.transaction((txn) async{
      for(final comment in feedComments){
        await txn.insert('feed_comments_data', {
          'comment_data': jsonEncode(comment)
        });
      }
    });
  }

  Future<List> fetchPaginatedFeedComments(int currentLength, int paginationLimit) async{
    final db = await database;
    List<Map> getAllFeedComments = [];
    await db.query(
      'feed_comments_data',
      offset: currentLength,
      limit: paginationLimit
    ).then((value) async{
      getAllFeedComments = value;
    });
    final List results = getAllFeedComments.map((e) => jsonDecode(e['comment_data'])).toList();    
    return results;
  }


  Future<void> replaceAllSearchedPosts(List searchedPosts) async{
    final db = await database;
    await db.delete('searched_posts_data');
    await db.transaction((txn) async{
      for(final post in searchedPosts){
        await txn.insert('searched_posts_data', {
          'post_data': jsonEncode(post)
        });
      }
    });
  }

  Future<List> fetchPaginatedSearchedPosts(int currentLength, int paginationLimit) async{
    final db = await database;
    List<Map> getAllSearchedPosts = [];
    await db.query(
      'searched_posts_data',
      offset: currentLength,
      limit: paginationLimit
    ).then((value) async{
      getAllSearchedPosts = value;
    });
    final List results = getAllSearchedPosts.map((e) => jsonDecode(e['post_data'])).toList();    
    return results;
  }

  Future<void> replaceAllSearchedComments(List searchedComments) async{
    final db = await database;
    await db.delete('searched_comments_data');
    await db.transaction((txn) async{
      for(final comment in searchedComments){
        await txn.insert('searched_comments_data', {
          'comment_data': jsonEncode(comment)
        });
      }
    });
  }

  Future<List> fetchPaginatedSearchedComments(int currentLength, int paginationLimit) async{
    final db = await database;
    List<Map> getAllSearchedComments = [];
    await db.query(
      'searched_comments_data',
      offset: currentLength,
      limit: paginationLimit
    ).then((value) async{
      getAllSearchedComments = value;
    });
    final List results = getAllSearchedComments.map((e) => jsonDecode(e['comment_data'])).toList();    
    return results;
  }

  Future<void> replaceAllSearchedUsers(List searchedUsers) async{
    final db = await database;
    await db.delete('searched_users_data');
    await db.transaction((txn) async{
      for(final userID in searchedUsers){
        await txn.insert('searched_users_data', {
          'user_id': userID
        });
      }
    });
  }

  Future<List> fetchPaginatedSearchedUsers(int currentLength, int paginationLimit) async{
    final db = await database;
    List<Map> getAllSearchedUsers = [];
    await db.query(
      'searched_users_data',
      offset: currentLength,
      limit: paginationLimit
    ).then((value) async{
      getAllSearchedUsers = value;
    });
    final List results = getAllSearchedUsers.map((e) => e['user_id']).toList();
    
    
    return results;
  }
}