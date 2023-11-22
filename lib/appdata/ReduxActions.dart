// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalFunctions.dart';
import 'package:social_media_app/appdata/NavigationActions.dart';
import 'package:social_media_app/class/PostClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import '../caching/sqfliteConfiguration.dart';
import '../class/CommentClass.dart';
import '../class/CommentNotifier.dart';
import '../class/PostNotifier.dart';
import '../class/UserDataNotifier.dart';
import '../class/UserSocialNotifier.dart';
import '../redux/reduxLibrary.dart';

void updateUserData(UserDataClass userDataClass, BuildContext context){
  if(fetchReduxDatabase().usersDatasNotifiers.value[userDataClass.userID] != null){
    if(fetchReduxDatabase().usersDatasNotifiers.value[userDataClass.userID]!.notifier.value.isNotEqual(userDataClass)){
      fetchReduxDatabase().usersDatasNotifiers.value[userDataClass.userID]!.notifier.value = userDataClass;
    }
  }else{
    final userDataNotifier = ValueNotifier<UserDataClass>(
      userDataClass
    );
    final userDataNotifierWrapper = UserDataNotifier(userDataClass.userID, userDataNotifier);
    Map<String, UserDataNotifier> usersDatasNotifiers = fetchReduxDatabase().usersDatasNotifiers.value;
    usersDatasNotifiers[userDataClass.userID] = userDataNotifierWrapper;
    if(context.mounted){
      StoreProvider.of<AppState>(context).dispatch(UsersDatasNotifiers(ValueNotifier(usersDatasNotifiers)));
    }
  }
}

void updateUserSocials(UserDataClass userDataClass, UserSocialClass userSocialClass, BuildContext context){
  if(fetchReduxDatabase().usersSocialsNotifiers.value[userDataClass.userID] != null){
    if(fetchReduxDatabase().usersSocialsNotifiers.value[userDataClass.userID]!.notifier.value.isNotEqual(userSocialClass)){
      fetchReduxDatabase().usersSocialsNotifiers.value[userDataClass.userID]!.notifier.value = userSocialClass;
    }
  }else{
    final userSocialNotifier = ValueNotifier<UserSocialClass>(
      userSocialClass
    );
    final userSocialNotifierWrapper = UserSocialNotifier(userDataClass.userID, userSocialNotifier);
    Map<String, UserSocialNotifier> usersSocialNotifiers = fetchReduxDatabase().usersSocialsNotifiers.value;
    usersSocialNotifiers[userDataClass.userID] = userSocialNotifierWrapper;
    if(context.mounted){
      StoreProvider.of<AppState>(context).dispatch(UsersSocialsNotifiers(ValueNotifier(usersSocialNotifiers)));
    }
  }
}

void updatePostData(PostClass postDataClass, BuildContext context){
  if(fetchReduxDatabase().postsNotifiers.value[postDataClass.sender] != null && fetchReduxDatabase().postsNotifiers.value[postDataClass.sender]![postDataClass.postID] != null){
    fetchReduxDatabase().postsNotifiers.value[postDataClass.sender]![postDataClass.postID]!.notifier.value = postDataClass;
  }else{
    final postNotifier = ValueNotifier<PostClass>(
      postDataClass
    );
    final postNotifierWrapper = PostNotifier(postDataClass.postID, postNotifier);
    Map<String, Map<String, PostNotifier>> postNotifiersValue = fetchReduxDatabase().postsNotifiers.value;
    if(postNotifiersValue[postDataClass.sender] == null){
      postNotifiersValue[postDataClass.sender] = {};
    }
    postNotifiersValue[postDataClass.sender]![postDataClass.postID] = postNotifierWrapper;
    if(context.mounted){
      StoreProvider.of<AppState>(context).dispatch(PostsNotifiers(ValueNotifier(postNotifiersValue)));
    }
  }
}

void updateCommentData(CommentClass commentDataClass, BuildContext context){
  if(fetchReduxDatabase().commentsNotifiers.value[commentDataClass.sender] != null && fetchReduxDatabase().commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID] != null){
    fetchReduxDatabase().commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID]!.notifier.value = commentDataClass;
  }else{
    final commentNotifier = ValueNotifier<CommentClass>(
      commentDataClass
    );
    final commentNotifierWrapper = CommentNotifier(commentDataClass.commentID, commentNotifier);
    Map<String, Map<String, CommentNotifier>> commentNotifiersValue = fetchReduxDatabase().commentsNotifiers.value;
    if(commentNotifiersValue[commentDataClass.sender] == null){
      commentNotifiersValue[commentDataClass.sender] = {};
    }
    commentNotifiersValue[commentDataClass.sender]![commentDataClass.commentID] = commentNotifierWrapper;
    if(context.mounted){
      StoreProvider.of<AppState>(context).dispatch(CommentsNotifiers(ValueNotifier(commentNotifiersValue)));
    }
  }
}

void logOut(BuildContext context) async{
  try {
    if(context.mounted){
      navigateBackToInitialScreen(context);
      await DatabaseHelper().deleteCurrentUser();
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void resetReduxData(BuildContext context) async{
  if(context.mounted){
    StoreProvider.of<AppState>(context).dispatch(CurrentID(''));
    StoreProvider.of<AppState>(context).dispatch(PostsNotifiers(ValueNotifier({})));
    StoreProvider.of<AppState>(context).dispatch(CommentsNotifiers(ValueNotifier({})));
    StoreProvider.of<AppState>(context).dispatch(UsersDatasNotifiers(ValueNotifier({})));
    StoreProvider.of<AppState>(context).dispatch(UsersSocialsNotifiers(ValueNotifier({})));
    StoreProvider.of<AppState>(context).dispatch(UsersProfilePostsNotifiers(ValueNotifier({})));
  }
}