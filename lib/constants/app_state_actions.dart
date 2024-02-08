import 'package:flutter/material.dart';
import 'package:social_media_app/class/comment/comment_class.dart';
import 'package:social_media_app/class/comment/comment_notifier.dart';
import 'package:social_media_app/class/local-storage/shared_preferences.dart';
import 'package:social_media_app/class/post/post_class.dart';
import 'package:social_media_app/class/post/post_notifier.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/class/user/user_data_notifier.dart';
import 'package:social_media_app/class/user/user_social_class.dart';
import 'package:social_media_app/class/user/user_social_notifier.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/navigation_actions.dart';
import 'package:social_media_app/state/main.dart';

void updateUserData(UserDataClass userDataClass){
  if(appStateClass.usersDataNotifiers.value[userDataClass.userID] != null){
    if(appStateClass.usersDataNotifiers.value[userDataClass.userID]!.notifier.value.isNotEqual(userDataClass)){
      appStateClass.usersDataNotifiers.value[userDataClass.userID]!.notifier.value = userDataClass;
    }
  }else{
    final userDataNotifier = ValueNotifier<UserDataClass>(
      userDataClass
    );
    final userDataNotifierWrapper = UserDataNotifier(userDataClass.userID, userDataNotifier);
    appStateClass.usersDataNotifiers.value[userDataClass.userID] = userDataNotifierWrapper;
  }
}

void updateUserSocials(UserDataClass userDataClass, UserSocialClass userSocialClass){
  if(appStateClass.usersSocialsNotifiers.value[userDataClass.userID] != null){
    if(appStateClass.usersSocialsNotifiers.value[userDataClass.userID]!.notifier.value.isNotEqual(userSocialClass)){
      appStateClass.usersSocialsNotifiers.value[userDataClass.userID]!.notifier.value = userSocialClass;
    }
  }else{
    final userSocialNotifier = ValueNotifier<UserSocialClass>(
      userSocialClass
    );
    final userSocialNotifierWrapper = UserSocialNotifier(userDataClass.userID, userSocialNotifier);
    appStateClass.usersSocialsNotifiers.value[userDataClass.userID] = userSocialNotifierWrapper;
  }
}

void updatePostData(PostClass postDataClass){
  if(appStateClass.postsNotifiers.value[postDataClass.sender] != null && appStateClass.postsNotifiers.value[postDataClass.sender]![postDataClass.postID] != null){
    appStateClass.postsNotifiers.value[postDataClass.sender]![postDataClass.postID]!.notifier.value = postDataClass;
  }else{
    final postNotifier = ValueNotifier<PostClass>(
      postDataClass
    );
    final postNotifierWrapper = PostNotifier(postDataClass.postID, postNotifier);
    if(appStateClass.postsNotifiers.value[postDataClass.sender] == null){
      appStateClass.postsNotifiers.value[postDataClass.sender] = {};
    }
    appStateClass.postsNotifiers.value[postDataClass.sender]![postDataClass.postID] = postNotifierWrapper;
  }
}

void updateCommentData(CommentClass commentDataClass){
  if(appStateClass.commentsNotifiers.value[commentDataClass.sender] != null && appStateClass.commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID] != null){
    appStateClass.commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID]!.notifier.value = commentDataClass;
  }else{
    final commentNotifier = ValueNotifier<CommentClass>(
      commentDataClass
    );
    final commentNotifierWrapper = CommentNotifier(commentDataClass.commentID, commentNotifier);
    if(appStateClass.commentsNotifiers.value[commentDataClass.sender] == null){
      appStateClass.commentsNotifiers.value[commentDataClass.sender] = {};
    }
    appStateClass.commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID] = commentNotifierWrapper;
  }
}

void logOut(BuildContext context) async{
  try {
    if(context.mounted){
      navigateBackToInitialScreen(context);
      SharedPreferencesClass().resetCurrentUser();
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void resetReduxData() async{
  appStateClass.resetSession();
}