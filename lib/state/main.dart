import 'package:flutter/material.dart';
import 'package:social_media_app/class/CommentNotifier.dart';
import 'package:social_media_app/class/PostNotifier.dart';
import 'package:social_media_app/class/UserDataNotifier.dart';
import 'package:social_media_app/class/UserSocialNotifier.dart';

class AppStateClass{
  String currentID;
  String socketID;
  ValueNotifier<Map<String, UserDataNotifier>> usersDataNotifiers;
  ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers;
  ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers;
  ValueNotifier<Map<String, Map<String, CommentNotifier>>> commentsNotifiers;

  AppStateClass({
    required this.currentID,
    required this.socketID,  
    required this.usersDataNotifiers,
    required this.usersSocialsNotifiers,
    required this.postsNotifiers,
    required this.commentsNotifiers
  });

  void resetSession(){
    currentID = '';
    usersDataNotifiers = ValueNotifier({});
    usersSocialsNotifiers = ValueNotifier({});
    postsNotifiers = ValueNotifier({});
    commentsNotifiers = ValueNotifier({});
  }
}

final appStateClass = AppStateClass(
  currentID: '',
  socketID: '',
  usersDataNotifiers: ValueNotifier({}),
  usersSocialsNotifiers: ValueNotifier({}),
  postsNotifiers: ValueNotifier({}),
  commentsNotifiers: ValueNotifier({})
);
