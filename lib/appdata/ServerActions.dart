import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalFunctions.dart';
import 'package:social_media_app/appdata/GlobalVariables.dart';
import 'package:social_media_app/class/CommentClass.dart';
import 'package:social_media_app/class/DisplayCommentDataClass.dart';
import 'package:social_media_app/class/DisplayPostDataClass.dart';
import 'package:social_media_app/class/NotificationClass.dart';
import 'package:social_media_app/redux/reduxLibrary.dart';
import 'package:social_media_app/streams/BookmarkDataStreamClass.dart';
import 'package:social_media_app/streams/NotificationDataStreamClass.dart';
import '../caching/sqfliteConfiguration.dart';
import '../class/PostClass.dart';
import '../class/UserDataClass.dart';
import '../class/UserSocialClass.dart';
import '../socket/main.dart';
import '../streams/RequestsFromDataStreamClass.dart';
import '../streams/RequestsToDataStreamClass.dart';
import '../streams/UserDataStreamClass.dart';
import 'NavigationActions.dart';
import 'ReduxActions.dart';

var dio = Dio();

void followUser(UserDataClass userData, UserSocialClass userSocials) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    if(userData.private){
      RequestsFromDataStreamClass().emitData(
        RequestsFromDataStreamControllerClass(
          userData.userID,
          'send_follow_request_$currentID'
        )
      );
      fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
        userData.userID, userData.name, userData.username, userData.profilePicLink, 
        userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
        userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
        true, userData.requestsToCurrentID, userData.verified, userData.suspended, userData.deleted
      );
    }else{
      UserSocialClass updatedFollowedUserSocialDataClass = UserSocialClass(userSocials.followersCount+ 1, userSocials.followingCount, true, userSocials.followsCurrentID);
      fetchReduxDatabase().usersSocialsNotifiers.value[userData.userID]!.notifier.value = updatedFollowedUserSocialDataClass;
    
      UserSocialClass currentUserSocialDataClass = fetchReduxDatabase().usersSocialsNotifiers.value[currentID]!.notifier.value;    
      UserSocialClass updatedCurrentUserSocialDataClass = UserSocialClass(currentUserSocialDataClass.followersCount, currentUserSocialDataClass.followingCount+ 1, false, false);
      fetchReduxDatabase().usersSocialsNotifiers.value[currentID]!.notifier.value = updatedCurrentUserSocialDataClass;
    
      UserDataStreamClass().emitData(
        UserDataStreamControllerClass(
          userData.userID, currentID, UserDataStreamsUpdateType.addFollowing
        )
      );
      UserDataStreamClass().emitData(
        UserDataStreamControllerClass(
          currentID, userData.userID, UserDataStreamsUpdateType.addFollowers
        )
      );
    }
    String stringified = jsonEncode({
      'currentID': currentID,
      'followedID': userData.userID
    });
    var res = await dio.patch('$serverDomainAddress/users/followUser', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unfollowUser(UserDataClass userData, UserSocialClass userSocials) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    UserSocialClass updatedFollowedUserSocialDataClass = UserSocialClass(userSocials.followersCount- 1, userSocials.followingCount, false, userSocials.followsCurrentID);
    fetchReduxDatabase().usersSocialsNotifiers.value[userData.userID]!.notifier.value = updatedFollowedUserSocialDataClass;
    
    UserSocialClass currentUserSocialDataClass = fetchReduxDatabase().usersSocialsNotifiers.value[currentID]!.notifier.value;    
    UserSocialClass updatedCurrentUserSocialDataClass = UserSocialClass(currentUserSocialDataClass.followersCount, currentUserSocialDataClass.followingCount- 1, false, false);
    fetchReduxDatabase().usersSocialsNotifiers.value[currentID]!.notifier.value = updatedCurrentUserSocialDataClass;
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        userData.userID, currentID, UserDataStreamsUpdateType.removeFollowing
      )
    );
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, userData.userID, UserDataStreamsUpdateType.removeFollowers
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID,
      'followedID': userData.userID
    });
    var res = await dio.patch('$serverDomainAddress/users/unfollowUser', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void likePost(PostClass postData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
      postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
      postData.mediasDatas, postData.likesCount+ 1, true, postData.bookmarksCount, postData.bookmarkedByCurrentID, 
      postData.commentsCount, postData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, postData.postID, UserDataStreamsUpdateType.addPostLikes
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    });
    var res = await dio.patch('$serverDomainAddress/users/likePost', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unlikePost(PostClass postData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
      postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
      postData.mediasDatas, postData.likesCount- 1, false, postData.bookmarksCount, postData.bookmarkedByCurrentID, 
      postData.commentsCount, postData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, postData.postID, UserDataStreamsUpdateType.removePostLikes
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    });
    var res = await dio.patch('$serverDomainAddress/users/unlikePost', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
   doSomethingWithException(e);
  }
}

void bookmarkPost(PostClass postData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
      postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
      postData.mediasDatas, postData.likesCount, postData.likedByCurrentID, postData.bookmarksCount+ 1, true, 
      postData.commentsCount, postData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, postData.postID, UserDataStreamsUpdateType.addPostBookmarks
      )
    );

    BookmarkDataStreamClass().emitData(
      BookmarkDataStreamControllerClass(
        DisplayPostDataClass(postData.sender, postData.postID), 
        'add_bookmarks_$currentID'
      )
    );

    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    });
    var res = await dio.patch('$serverDomainAddress/users/bookmarkPost', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unbookmarkPost(PostClass postData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
      postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
      postData.mediasDatas, postData.likesCount, postData.likedByCurrentID, postData.bookmarksCount- 1, false, 
      postData.commentsCount, postData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, postData.postID, UserDataStreamsUpdateType.removePostBookmarks
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    });
    var res = await dio.patch('$serverDomainAddress/users/unbookmarkPost', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}


void deletePost(PostClass postData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
      postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
      postData.mediasDatas, postData.likesCount, postData.likedByCurrentID, postData.bookmarksCount,
      postData.bookmarkedByCurrentID, postData.commentsCount, true
    );
    NotificationDataStreamClass().emitData(
      NotificationDataStreamControllerClass(
        NotificationClass(
          '', currentID, postData.postID, 'post', '', '', [], '', '', '', false
        ),
        'delete_content_notifications'
      )
    );
    String stringified = jsonEncode({
      'sender': currentID,
      'postID': postData.postID
    });
    var res = await dio.patch('$serverDomainAddress/users/deletePost', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void likeComment(CommentClass commentData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
      commentData.commentID, commentData.type, commentData.content, commentData.sender, commentData.uploadTime, 
      commentData.mediasDatas, commentData.likesCount+ 1, true, commentData.bookmarksCount, commentData.bookmarkedByCurrentID, commentData.commentsCount, 
      commentData.parentPostType, commentData.parentPostID, commentData.parentPostSender, 
      commentData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, commentData.commentID, UserDataStreamsUpdateType.addCommentLikes
      )
    );
    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    });
    var res = await dio.patch('$serverDomainAddress/users/likeComment', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unlikeComment(CommentClass commentData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
      commentData.commentID, commentData.type, commentData.content, commentData.sender, commentData.uploadTime, 
      commentData.mediasDatas, commentData.likesCount- 1, false, commentData.bookmarksCount, commentData.bookmarkedByCurrentID, commentData.commentsCount, 
      commentData.parentPostType, commentData.parentPostID, commentData.parentPostSender, 
      commentData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, commentData.commentID, UserDataStreamsUpdateType.removeCommentLikes
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    });
    var res = await dio.patch('$serverDomainAddress/users/unlikeComment', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void bookmarkComment(CommentClass commentData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
      commentData.commentID, commentData.type, commentData.content, commentData.sender, commentData.uploadTime, 
      commentData.mediasDatas, commentData.likesCount, commentData.likedByCurrentID, commentData.bookmarksCount+ 1, true, commentData.commentsCount, 
      commentData.parentPostType, commentData.parentPostID, commentData.parentPostSender, 
      commentData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, commentData.commentID, UserDataStreamsUpdateType.addCommentBookmarks
      )
    );

    BookmarkDataStreamClass().emitData(
      BookmarkDataStreamControllerClass(
        DisplayCommentDataClass(commentData.sender, commentData.commentID),
        'add_bookmarks_$currentID'
      )
    );

    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    });
    var res = await dio.patch('$serverDomainAddress/users/bookmarkComment', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unbookmarkComment(CommentClass commentData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
      commentData.commentID, commentData.type, commentData.content, commentData.sender, commentData.uploadTime, 
      commentData.mediasDatas, commentData.likesCount, commentData.likedByCurrentID, commentData.bookmarksCount- 1, false, commentData.commentsCount, 
      commentData.parentPostType, commentData.parentPostID, commentData.parentPostSender, 
      commentData.deleted
    );
    
    UserDataStreamClass().emitData(
      UserDataStreamControllerClass(
        currentID, commentData.commentID, UserDataStreamsUpdateType.removeCommentBookmarks
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    });
    var res = await dio.patch('$serverDomainAddress/users/unbookmarkComment', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void deleteComment(CommentClass commentData, BuildContext context) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = 
    CommentClass(
      commentData.commentID, commentData.type, commentData.content, commentData.sender, commentData.uploadTime, 
      commentData.mediasDatas, commentData.likesCount, commentData.likedByCurrentID, commentData.bookmarksCount, commentData.bookmarkedByCurrentID, commentData.commentsCount, 
      commentData.parentPostType, commentData.parentPostID, commentData.parentPostSender, 
      true
    );
    
    if(commentData.parentPostType == 'post'){
      if(fetchReduxDatabase().postsNotifiers.value[commentData.parentPostSender] != null && fetchReduxDatabase().postsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID] != null){
        PostClass parentPostClass = fetchReduxDatabase().postsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID]!.notifier.value;
        updatePostData(
          PostClass(
            parentPostClass.postID, parentPostClass.type, parentPostClass.content, parentPostClass.sender, 
            parentPostClass.uploadTime, parentPostClass.mediasDatas, parentPostClass.likesCount, parentPostClass.likedByCurrentID, 
            parentPostClass.bookmarksCount, parentPostClass.bookmarkedByCurrentID, parentPostClass.commentsCount- 1, parentPostClass.deleted
          ), context
        );
      }
    }else{
      if(fetchReduxDatabase().commentsNotifiers.value[commentData.parentPostSender] != null && fetchReduxDatabase().commentsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID] != null){
        CommentClass parentCommentClass = fetchReduxDatabase().commentsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID]!.notifier.value;
        updateCommentData(
          CommentClass(
            parentCommentClass.commentID, parentCommentClass.type, parentCommentClass.content, parentCommentClass.sender, 
            parentCommentClass.uploadTime, parentCommentClass.mediasDatas, parentCommentClass.likesCount, parentCommentClass.likedByCurrentID, 
            parentCommentClass.bookmarksCount, parentCommentClass.bookmarkedByCurrentID, parentCommentClass.commentsCount- 1, parentCommentClass.parentPostType, 
            parentCommentClass.parentPostID, parentCommentClass.parentPostSender, parentCommentClass.deleted
          ), context
        );
      }
    }
    NotificationDataStreamClass().emitData(
      NotificationDataStreamControllerClass(
        NotificationClass(
          '', '', commentData.commentID, 'comment', '', '', [], '', '', '', false
        ), 
        'delete_content_notifications'
      )
    );
    String stringified = jsonEncode({
      'sender': currentID,
      'commentID': commentData.commentID,
      'parentPostType': commentData.parentPostType,
      'parentPostID': commentData.parentPostID,
      'parentPostSender': commentData.parentPostSender
    });
    var res = await dio.patch('$serverDomainAddress/users/deleteComment', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void deleteAccount(context) async{
  try {

    String stringified = jsonEncode({
      'currentID': fetchReduxDatabase().currentID,
    });
    var res = await dio.delete('$serverDomainAddress/users/deleteAccount', data: stringified);
    if(res.data.isNotEmpty){
      await DatabaseHelper().deleteCurrentUser();
      StoreProvider.of<AppState>(context).dispatch(CurrentID(''));
      StoreProvider.of<AppState>(context).dispatch(PostsNotifiers(ValueNotifier({})));
      StoreProvider.of<AppState>(context).dispatch(CommentsNotifiers(ValueNotifier({})));
      StoreProvider.of<AppState>(context).dispatch(UsersDatasNotifiers(ValueNotifier({})));
      StoreProvider.of<AppState>(context).dispatch(UsersSocialsNotifiers(ValueNotifier({})));
      StoreProvider.of<AppState>(context).dispatch(UsersProfilePostsNotifiers(ValueNotifier({})));
      navigateBackToInitialScreen(context);
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void muteUser(UserDataClass userData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
      userData.birthDate, userData.bio, true, userData.blockedByCurrentID, userData.blocksCurrentID,
      userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID, 
      userData.verified, userData.suspended, userData.deleted
    );
    
    NotificationDataStreamClass().emitData(
      NotificationDataStreamControllerClass(
        NotificationClass(
          '', userData.userID, '', '', '', '', [], '', '', '', false
        ),
        'blacklist_user_notifications'
      )
    );
    
    String stringified = jsonEncode({
      'userID': userData.userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/muteUser', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unmuteUser(UserDataClass userData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
      userData.birthDate, userData.bio, false, userData.blockedByCurrentID, userData.blocksCurrentID,
      userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
      userData.verified, userData.suspended, userData.deleted
    );
    
    String stringified = jsonEncode({
      'userID': userData.userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/unmuteUser', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void blockUser(UserDataClass userData, UserSocialClass userSocials) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    UserSocialClass currentUserSocialClass = fetchReduxDatabase().usersSocialsNotifiers.value[currentID]!.notifier.value;
    
    fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
      userData.birthDate, userData.bio, userData.mutedByCurrentID, true, userData.blocksCurrentID,
      userData.private, false, false, userData.verified, userData.suspended, userData.deleted
    );
    
    fetchReduxDatabase().usersSocialsNotifiers.value[userData.userID]!.notifier.value = UserSocialClass(
      userSocials.followedByCurrentID ? userSocials.followersCount - 1 : userSocials.followersCount, 
      userSocials.followsCurrentID ? userSocials.followingCount - 1 : userSocials.followingCount, 
      false, false
    );
    
    fetchReduxDatabase().usersSocialsNotifiers.value[currentID]!.notifier.value = UserSocialClass(
      userSocials.followsCurrentID ? currentUserSocialClass.followersCount - 1 : currentUserSocialClass.followersCount, 
      userSocials.followedByCurrentID ? currentUserSocialClass.followingCount - 1 : currentUserSocialClass.followingCount, 
      false, 
      false
    );
    
    NotificationDataStreamClass().emitData(
      NotificationDataStreamControllerClass(
        NotificationClass(
          '', userData.userID, '', '', '', '', [], '', '', '', false
        ),
        'blacklist_user_notifications'
      )
    );
    
    socket.emit("block-user-to-server", {
      'senderID': currentID,
      'blockedUserID': userData.userID
    });
    
    String stringified = jsonEncode({
      'userID': userData.userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/blockUser', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unblockUser(UserDataClass userData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
      userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID,
      userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
      userData.verified, userData.suspended, userData.deleted
    );
    
    socket.emit("unblock-user-to-server", {
      'senderID': currentID,
      'unblockedUserID': userData.userID
    });
    
    String stringified = jsonEncode({
      'userID': userData.userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/unblockUser', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void lockAccount(UserDataClass userData) async{
  try {
    String currentID = userData.userID;
    fetchReduxDatabase().usersDatasNotifiers.value[currentID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
      userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID,
      true, userData.requestedByCurrentID, userData.requestsToCurrentID,
      userData.verified, userData.suspended, userData.deleted
    );
    
    String stringified = jsonEncode({
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/lockAccount', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void unlockAccount(UserDataClass userData) async{
  try {
    String currentID = userData.userID;
    fetchReduxDatabase().usersDatasNotifiers.value[currentID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
      userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID,
      false, userData.requestedByCurrentID, userData.requestsToCurrentID,
      userData.verified, userData.suspended, userData.deleted
    );
    RequestsToDataStreamClass().emitData(
      RequestsToDataStreamControllerClass(
        userData.userID,
        'unlock_account_$currentID'
      )
    );
    
    String stringified = jsonEncode({
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/unlockAccount', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void acceptFollowRequest(String userID) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    
    UserDataClass userData = fetchReduxDatabase().usersDatasNotifiers.value[userID]!.notifier.value;
    fetchReduxDatabase().usersDatasNotifiers.value[userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, 
      userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
      userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
      userData.requestedByCurrentID, false, userData.verified, userData.suspended, userData.deleted
    );
    
    UserSocialClass userSocialClass = fetchReduxDatabase().usersSocialsNotifiers.value[userID]!.notifier.value;
    fetchReduxDatabase().usersSocialsNotifiers.value[userID]!.notifier.value = UserSocialClass(
      userSocialClass.followersCount, userSocialClass.followingCount + 1, userSocialClass.followedByCurrentID, 
      true
    );
    
    String stringified = jsonEncode({
      'userID': userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/acceptFollowRequest', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void rejectFollowRequest(UserDataClass userData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    
    fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, 
      userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
      userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
      userData.requestedByCurrentID, false, userData.verified, userData.suspended, userData.deleted
    );
    
    String stringified = jsonEncode({
      'userID': userData.userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/rejectFollowRequest', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

void cancelFollowRequest(UserDataClass userData) async{
  try {
    String currentID = fetchReduxDatabase().currentID;
    
    fetchReduxDatabase().usersDatasNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, 
      userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
      userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
      false, userData.requestsToCurrentID, userData.verified, userData.suspended, userData.deleted
    );
    
    String stringified = jsonEncode({
      'userID': userData.userID,
      'currentID': currentID
    });
    var res = await dio.patch('$serverDomainAddress/users/cancelFollowRequest', data: stringified);
    if(res.data.isNotEmpty){
    }
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
}

