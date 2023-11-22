import 'package:flutter/cupertino.dart';
import 'package:redux/redux.dart';
import 'package:social_media_app/class/DisplayPostDataNotifier.dart';
import 'package:social_media_app/class/UserDataNotifier.dart';
import 'package:social_media_app/class/PostNotifier.dart';
import '../class/CommentNotifier.dart';
import '../class/UserSocialNotifier.dart';
import 'Actions.dart';

final currentIDReducer = TypedReducer<String, CurrentID>(_currentIDReducer);

String _currentIDReducer(String state, CurrentID action) {
  return action.payload;
}

final socketIDReducer = TypedReducer<String, SocketID>(_socketIDReducer);

String _socketIDReducer(String state, SocketID action) {
  return action.payload;
}

final usersDatasNotifiersReducer = TypedReducer<ValueNotifier<Map<String, UserDataNotifier>>, UsersDatasNotifiers>(_usersDatasNotifiersReducer);

ValueNotifier<Map<String, UserDataNotifier>> _usersDatasNotifiersReducer(ValueNotifier<Map<String, UserDataNotifier>> state, UsersDatasNotifiers action){
  return action.payload;
}

final usersSocialsNotifiersReducer = TypedReducer<ValueNotifier<Map<String, UserSocialNotifier>>, UsersSocialsNotifiers>(_usersSocialsNotifiersReducer);

ValueNotifier<Map<String, UserSocialNotifier>> _usersSocialsNotifiersReducer(ValueNotifier<Map<String, UserSocialNotifier>> state, UsersSocialsNotifiers action){
  return action.payload;
}

final postsNotifiersReducer = TypedReducer<ValueNotifier<Map<String, Map<String, PostNotifier>>>, PostsNotifiers>(_postsNotifiersReducer);

ValueNotifier<Map<String, Map<String, PostNotifier>>> _postsNotifiersReducer(ValueNotifier<Map<String, Map<String, PostNotifier>>> state, PostsNotifiers action){
  return action.payload;
}

final commentsNotifiersReducer = TypedReducer<ValueNotifier<Map<String, Map<String, CommentNotifier>>>, CommentsNotifiers>(_commentsNotifiersReducer);

ValueNotifier<Map<String, Map<String, CommentNotifier>>> _commentsNotifiersReducer(ValueNotifier<Map<String, Map<String, CommentNotifier>>> state, CommentsNotifiers action){
  return action.payload;
}

final usersProfilePostsNotifiersReducer = TypedReducer<ValueNotifier<Map<String, DisplayPostDataNotifier>>, UsersProfilePostsNotifiers>(_usersProfilePostsNotifiersReducer);

ValueNotifier<Map<String, DisplayPostDataNotifier>> _usersProfilePostsNotifiersReducer(ValueNotifier<Map<String, DisplayPostDataNotifier>> state, UsersProfilePostsNotifiers action){
  return action.payload;
}