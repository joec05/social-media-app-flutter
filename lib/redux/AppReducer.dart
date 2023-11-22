import 'AppState.dart';
import 'TestReducer.dart';

AppState appReducer(AppState state, action) {
  return AppState(
    currentID: currentIDReducer(state.currentID, action),
    socketID: socketIDReducer(state.socketID, action),
    usersDatasNotifiers: usersDatasNotifiersReducer(state.usersDatasNotifiers, action),
    usersSocialsNotifiers: usersSocialsNotifiersReducer(state.usersSocialsNotifiers, action),
    postsNotifiers: postsNotifiersReducer(state.postsNotifiers, action),
    commentsNotifiers: commentsNotifiersReducer(state.commentsNotifiers, action),
    usersProfilePostsNotifiers: usersProfilePostsNotifiersReducer(state.usersProfilePostsNotifiers, action),
  );
}