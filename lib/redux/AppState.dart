import 'package:flutter/cupertino.dart';
import 'package:social_media_app/class/DisplayPostDataNotifier.dart';
import 'package:social_media_app/class/PostNotifier.dart';
import 'package:social_media_app/class/UserDataNotifier.dart';
import '../class/CommentNotifier.dart';
import '../class/UserSocialNotifier.dart';

class AppState{
  String currentID = '';
  String socketID = '';
  ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, Map<String, CommentNotifier>>> commentsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, DisplayPostDataNotifier>> usersProfilePostsNotifiers = ValueNotifier({});

  AppState({
    required this.currentID, required this.socketID, required this.usersDatasNotifiers, 
    required this.usersSocialsNotifiers, required this.postsNotifiers, 
    required this.commentsNotifiers, required this.usersProfilePostsNotifiers, 
  });

  AppState.fromAppState(AppState another){
    currentID = another.currentID;
    socketID = another.socketID;
    usersDatasNotifiers = another.usersDatasNotifiers;
    usersSocialsNotifiers = another.usersSocialsNotifiers;
    postsNotifiers = another.postsNotifiers;
    commentsNotifiers = another.commentsNotifiers;
    usersProfilePostsNotifiers = another.usersProfilePostsNotifiers;
  }
  @override
  String toString() {
    return 'AppState: {currentID: $currentID, socketID: $socketID}';
  }
}