import 'package:flutter/cupertino.dart';
import 'package:redux/redux.dart';
import 'package:social_media_app/class/UserDataNotifier.dart';
import '../class/CommentNotifier.dart';
import '../class/DisplayPostDataNotifier.dart';
import '../class/PostNotifier.dart';
import '../class/UserSocialNotifier.dart';
import 'AppState.dart';

class ViewModel {
  String currentID = '';
  String socketID = '';
  ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, Map<String, CommentNotifier>>> commentsNotifiers = ValueNotifier({});
  ValueNotifier<Map<String, DisplayPostDataNotifier>> usersProfilePostsNotifiers = ValueNotifier({});

  ViewModel({
    required this.currentID, required this.socketID, required this.usersDatasNotifiers,
    required this.usersSocialsNotifiers, required this.postsNotifiers, 
    required this.commentsNotifiers, required this.usersProfilePostsNotifiers, 
  });

  static ViewModel fromStore(Store<AppState> store) {
    return ViewModel(
      currentID: store.state.currentID,
      socketID: store.state.socketID,
      usersDatasNotifiers: store.state.usersDatasNotifiers,
      usersSocialsNotifiers: store.state.usersSocialsNotifiers,
      postsNotifiers: store.state.postsNotifiers,
      commentsNotifiers: store.state.commentsNotifiers,
      usersProfilePostsNotifiers: store.state.usersProfilePostsNotifiers,
    );
  }
}
