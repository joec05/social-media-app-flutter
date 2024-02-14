import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

void updateUserData(UserDataClass userDataClass){
  if(appStateRepo.usersDataNotifiers.value[userDataClass.userID] != null){
    if(appStateRepo.usersDataNotifiers.value[userDataClass.userID]!.notifier.value.isNotEqual(userDataClass)){
      appStateRepo.usersDataNotifiers.value[userDataClass.userID]!.notifier.value = userDataClass;
    }
  }else{
    final userDataNotifier = ValueNotifier<UserDataClass>(
      userDataClass
    );
    final userDataNotifierWrapper = UserDataNotifier(userDataClass.userID, userDataNotifier);
    appStateRepo.usersDataNotifiers.value[userDataClass.userID] = userDataNotifierWrapper;
  }
}

void updateUserSocials(UserDataClass userDataClass, UserSocialClass userSocialClass){
  if(appStateRepo.usersSocialsNotifiers.value[userDataClass.userID] != null){
    if(appStateRepo.usersSocialsNotifiers.value[userDataClass.userID]!.notifier.value.isNotEqual(userSocialClass)){
      appStateRepo.usersSocialsNotifiers.value[userDataClass.userID]!.notifier.value = userSocialClass;
    }
  }else{
    final userSocialNotifier = ValueNotifier<UserSocialClass>(
      userSocialClass
    );
    final userSocialNotifierWrapper = UserSocialNotifier(userDataClass.userID, userSocialNotifier);
    appStateRepo.usersSocialsNotifiers.value[userDataClass.userID] = userSocialNotifierWrapper;
  }
}

void updatePostData(PostClass postDataClass){
  if(appStateRepo.postsNotifiers.value[postDataClass.sender] != null && appStateRepo.postsNotifiers.value[postDataClass.sender]![postDataClass.postID] != null){
    appStateRepo.postsNotifiers.value[postDataClass.sender]![postDataClass.postID]!.notifier.value = postDataClass;
  }else{
    final postNotifier = ValueNotifier<PostClass>(
      postDataClass
    );
    final postNotifierWrapper = PostNotifier(postDataClass.postID, postNotifier);
    if(appStateRepo.postsNotifiers.value[postDataClass.sender] == null){
      appStateRepo.postsNotifiers.value[postDataClass.sender] = {};
    }
    appStateRepo.postsNotifiers.value[postDataClass.sender]![postDataClass.postID] = postNotifierWrapper;
  }
}

void updateCommentData(CommentClass commentDataClass){
  if(appStateRepo.commentsNotifiers.value[commentDataClass.sender] != null && appStateRepo.commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID] != null){
    appStateRepo.commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID]!.notifier.value = commentDataClass;
  }else{
    final commentNotifier = ValueNotifier<CommentClass>(
      commentDataClass
    );
    final commentNotifierWrapper = CommentNotifier(commentDataClass.commentID, commentNotifier);
    if(appStateRepo.commentsNotifiers.value[commentDataClass.sender] == null){
      appStateRepo.commentsNotifiers.value[commentDataClass.sender] = {};
    }
    appStateRepo.commentsNotifiers.value[commentDataClass.sender]![commentDataClass.commentID] = commentNotifierWrapper;
  }
}

void logOut(BuildContext context) async{
  if(context.mounted){
    authRepo.logOut(context);
    navigateBackToInitialScreen(context);
  }
}

void resetReduxData() async{
  appStateRepo.resetSession();
}