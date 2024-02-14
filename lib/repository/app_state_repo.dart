import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class AppStateRepository{
  String currentID;
  String socketID;
  ValueNotifier<Map<String, UserDataNotifier>> usersDataNotifiers;
  ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers;
  ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers;
  ValueNotifier<Map<String, Map<String, CommentNotifier>>> commentsNotifiers;

  AppStateRepository({
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

final appStateRepo = AppStateRepository(
  currentID: '',
  socketID: '',
  usersDataNotifiers: ValueNotifier({}),
  usersSocialsNotifiers: ValueNotifier({}),
  postsNotifiers: ValueNotifier({}),
  commentsNotifiers: ValueNotifier({})
);
