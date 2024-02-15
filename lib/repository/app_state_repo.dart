import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class AppStateRepository{
  String currentID = '';
  String socketID = '';
  ValueNotifier<Map<String, UserDataNotifier>> usersDataNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, Map<String, CommentNotifier>>> commentsNotifiers = ValueNotifier({});
  ValueNotifier<ThemeData> appTheme = ValueNotifier(globalTheme.dark);

  void resetSession(){
    currentID = '';
    usersDataNotifiers = ValueNotifier({});
    usersSocialsNotifiers = ValueNotifier({});
    postsNotifiers = ValueNotifier({});
    commentsNotifiers = ValueNotifier({});
  }
}

final AppStateRepository appStateRepo = AppStateRepository();
