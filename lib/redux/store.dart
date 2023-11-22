import 'package:flutter/cupertino.dart';
import 'package:redux/redux.dart';
import 'AppState.dart';
import 'AppReducer.dart';

final Store<AppState> store = Store<AppState>(appReducer, initialState: AppState(
  currentID: '', socketID: '', usersDatasNotifiers: ValueNotifier({}),
  postsNotifiers: ValueNotifier({}), commentsNotifiers: ValueNotifier({}),
  usersSocialsNotifiers: ValueNotifier({}), 
  usersProfilePostsNotifiers: ValueNotifier({}),
),);
