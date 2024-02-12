import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

void followUser(
  BuildContext context,
  UserDataClass userData, 
  UserSocialClass userSocials
) async{
  String currentID = appStateClass.currentID;
  if(userData.private){
    RequestsFromDataStreamClass().emitData(
      RequestsFromDataStreamControllerClass(
        userData.userID,
        'send_follow_request_$currentID'
      )
    );
    appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
      userData.userID, userData.name, userData.username, userData.profilePicLink, 
      userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
      userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
      true, userData.requestsToCurrentID, userData.verified, userData.suspended, userData.deleted
    );
  }else{
    UserSocialClass updatedFollowedUserSocialDataClass = UserSocialClass(userSocials.followersCount+ 1, userSocials.followingCount, true, userSocials.followsCurrentID);
    appStateClass.usersSocialsNotifiers.value[userData.userID]!.notifier.value = updatedFollowedUserSocialDataClass;
  
    UserSocialClass currentUserSocialDataClass = appStateClass.usersSocialsNotifiers.value[currentID]!.notifier.value;    
    UserSocialClass updatedCurrentUserSocialDataClass = UserSocialClass(currentUserSocialDataClass.followersCount, currentUserSocialDataClass.followingCount+ 1, false, false);
    appStateClass.usersSocialsNotifiers.value[currentID]!.notifier.value = updatedCurrentUserSocialDataClass;
  
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

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.followUser, 
    {
      'currentID': currentID,
      'followedID': userData.userID
    }
  );
}

void unfollowUser(
  BuildContext context,
  UserDataClass userData, 
  UserSocialClass userSocials
) async{
  String currentID = appStateClass.currentID;
  UserSocialClass updatedFollowedUserSocialDataClass = UserSocialClass(userSocials.followersCount- 1, userSocials.followingCount, false, userSocials.followsCurrentID);
  appStateClass.usersSocialsNotifiers.value[userData.userID]!.notifier.value = updatedFollowedUserSocialDataClass;
  
  UserSocialClass currentUserSocialDataClass = appStateClass.usersSocialsNotifiers.value[currentID]!.notifier.value;    
  UserSocialClass updatedCurrentUserSocialDataClass = UserSocialClass(currentUserSocialDataClass.followersCount, currentUserSocialDataClass.followingCount- 1, false, false);
  appStateClass.usersSocialsNotifiers.value[currentID]!.notifier.value = updatedCurrentUserSocialDataClass;
  
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unfollowUser, 
    {
      'currentID': currentID,
      'followedID': userData.userID
    }
  );
}

void likePost(
  BuildContext context,
  PostClass postData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
    postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
    postData.mediasDatas, postData.likesCount+ 1, true, postData.bookmarksCount, postData.bookmarkedByCurrentID, 
    postData.commentsCount, postData.deleted
  );
  
  UserDataStreamClass().emitData(
    UserDataStreamControllerClass(
      currentID, postData.postID, UserDataStreamsUpdateType.addPostLikes
    )
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.likePost, 
    {
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    }
  );
}

void unlikePost(
  BuildContext context,
  PostClass postData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
    postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
    postData.mediasDatas, postData.likesCount- 1, false, postData.bookmarksCount, postData.bookmarkedByCurrentID, 
    postData.commentsCount, postData.deleted
  );
  
  UserDataStreamClass().emitData(
    UserDataStreamControllerClass(
      currentID, postData.postID, UserDataStreamsUpdateType.removePostLikes
    )
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unlikePost, 
    {
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    }
  );
}

void bookmarkPost(
  BuildContext context,
  PostClass postData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
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

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.bookmarkPost, 
    {
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    }
  );
}

void unbookmarkPost(
  BuildContext context,
  PostClass postData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
    postData.postID, postData.type, postData.content, postData.sender, postData.uploadTime, 
    postData.mediasDatas, postData.likesCount, postData.likedByCurrentID, postData.bookmarksCount- 1, false, 
    postData.commentsCount, postData.deleted
  );
  
  UserDataStreamClass().emitData(
    UserDataStreamControllerClass(
      currentID, postData.postID, UserDataStreamsUpdateType.removePostBookmarks
    )
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unbookmarkPost, 
    {
      'currentID': currentID,
      'sender': postData.sender,
      'postID': postData.postID
    }
  );
}

void deletePost(
  BuildContext context,
  PostClass postData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.postsNotifiers.value[postData.sender]![postData.postID]!.notifier.value = PostClass(
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

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.deletePost, 
    {
      'sender': currentID,
      'postID': postData.postID
    }
  );
}

void likeComment(
  BuildContext context,
  CommentClass commentData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
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

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.likeComment, 
    {
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    }
  );
}

void unlikeComment(
  BuildContext context,
  CommentClass commentData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unlikeComment, 
    {
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    }
  );
}

void bookmarkComment(
  BuildContext context,
  CommentClass commentData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
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

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.bookmarkComment, 
    {
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    }
  );
}

void unbookmarkComment(
  BuildContext context,
  CommentClass commentData
)async{
  String currentID = appStateClass.currentID;
  appStateClass.commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = CommentClass(
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unbookmarkComment, 
    {
      'currentID': currentID,
      'sender': commentData.sender,
      'commentID': commentData.commentID
    }
  );
}

void deleteComment(
  BuildContext context,
  CommentClass commentData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.commentsNotifiers.value[commentData.sender]![commentData.commentID]!.notifier.value = 
  CommentClass(
    commentData.commentID, commentData.type, commentData.content, commentData.sender, commentData.uploadTime, 
    commentData.mediasDatas, commentData.likesCount, commentData.likedByCurrentID, commentData.bookmarksCount, commentData.bookmarkedByCurrentID, commentData.commentsCount, 
    commentData.parentPostType, commentData.parentPostID, commentData.parentPostSender, 
    true
  );
  
  if(commentData.parentPostType == 'post'){
    if(appStateClass.postsNotifiers.value[commentData.parentPostSender] != null && appStateClass.postsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID] != null){
      PostClass parentPostClass = appStateClass.postsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID]!.notifier.value;
      updatePostData(
        PostClass(
          parentPostClass.postID, parentPostClass.type, parentPostClass.content, parentPostClass.sender, 
          parentPostClass.uploadTime, parentPostClass.mediasDatas, parentPostClass.likesCount, parentPostClass.likedByCurrentID, 
          parentPostClass.bookmarksCount, parentPostClass.bookmarkedByCurrentID, parentPostClass.commentsCount- 1, parentPostClass.deleted
        )
      );
    }
  }else{
    if(appStateClass.commentsNotifiers.value[commentData.parentPostSender] != null && appStateClass.commentsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID] != null){
      CommentClass parentCommentClass = appStateClass.commentsNotifiers.value[commentData.parentPostSender]![commentData.parentPostID]!.notifier.value;
      updateCommentData(
        CommentClass(
          parentCommentClass.commentID, parentCommentClass.type, parentCommentClass.content, parentCommentClass.sender, 
          parentCommentClass.uploadTime, parentCommentClass.mediasDatas, parentCommentClass.likesCount, parentCommentClass.likedByCurrentID, 
          parentCommentClass.bookmarksCount, parentCommentClass.bookmarkedByCurrentID, parentCommentClass.commentsCount- 1, parentCommentClass.parentPostType, 
          parentCommentClass.parentPostID, parentCommentClass.parentPostSender, parentCommentClass.deleted
        )
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.deleteComment, 
    {
      'sender': currentID,
      'commentID': commentData.commentID,
      'parentPostType': commentData.parentPostType,
      'parentPostID': commentData.parentPostID,
      'parentPostSender': commentData.parentPostSender
    }
  );
}

void deleteAccount(BuildContext context) async{
  dynamic res = await fetchDataRepo.fetchData(
    context, 
    RequestDelete.deleteAccount, 
    {
      'currentID': appStateClass.currentID,
    }
  );
  if(res != null && context.mounted){
    SharedPreferencesClass().resetCurrentUser();
    appStateClass.resetSession();
    navigateBackToInitialScreen(context);
  }
}

void muteUser(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.muteUser, 
    {
      'userID': userData.userID,
      'currentID': currentID
    }
  );
}

void unmuteUser(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
    userData.birthDate, userData.bio, false, userData.blockedByCurrentID, userData.blocksCurrentID,
    userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
    userData.verified, userData.suspended, userData.deleted
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unmuteUser, 
    {
      'userID': userData.userID,
      'currentID': currentID
    }
  );
}

void blockUser(
  BuildContext context,
  UserDataClass userData, 
  UserSocialClass userSocials
) async{
  String currentID = appStateClass.currentID;
  UserSocialClass currentUserSocialClass = appStateClass.usersSocialsNotifiers.value[currentID]!.notifier.value;
  
  appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
    userData.birthDate, userData.bio, userData.mutedByCurrentID, true, userData.blocksCurrentID,
    userData.private, false, false, userData.verified, userData.suspended, userData.deleted
  );
  
  appStateClass.usersSocialsNotifiers.value[userData.userID]!.notifier.value = UserSocialClass(
    userSocials.followedByCurrentID ? userSocials.followersCount - 1 : userSocials.followersCount, 
    userSocials.followsCurrentID ? userSocials.followingCount - 1 : userSocials.followingCount, 
    false, false
  );
  
  appStateClass.usersSocialsNotifiers.value[currentID]!.notifier.value = UserSocialClass(
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.blockUser, 
    {
      'userID': userData.userID,
      'currentID': currentID
    }
  );
}

void unblockUser(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
    userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID,
    userData.private, userData.requestedByCurrentID, userData.requestsToCurrentID,
    userData.verified, userData.suspended, userData.deleted
  );
  
  socket.emit("unblock-user-to-server", {
    'senderID': currentID,
    'unblockedUserID': userData.userID
  });

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unblockUser, 
    {
      'userID': userData.userID,
      'currentID': currentID
    }
  );
}

void lockAccount(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = userData.userID;
  appStateClass.usersDataNotifiers.value[currentID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, userData.dateJoined, 
    userData.birthDate, userData.bio, userData.mutedByCurrentID, false, userData.blocksCurrentID,
    true, userData.requestedByCurrentID, userData.requestsToCurrentID,
    userData.verified, userData.suspended, userData.deleted
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.lockAccount, 
    {
      'currentID': currentID
    }
  );
}

void unlockAccount(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = userData.userID;
  appStateClass.usersDataNotifiers.value[currentID]!.notifier.value = UserDataClass(
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
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.unlockAccount, 
    {
      'currentID': currentID
    }
  );
}

void acceptFollowRequest(
  BuildContext context,
  String userID
) async{
  String currentID = appStateClass.currentID;
  UserDataClass userData = appStateClass.usersDataNotifiers.value[userID]!.notifier.value;
  appStateClass.usersDataNotifiers.value[userID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, 
    userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
    userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
    userData.requestedByCurrentID, false, userData.verified, userData.suspended, userData.deleted
  );
  
  UserSocialClass userSocialClass = appStateClass.usersSocialsNotifiers.value[userID]!.notifier.value;
  appStateClass.usersSocialsNotifiers.value[userID]!.notifier.value = UserSocialClass(
    userSocialClass.followersCount, userSocialClass.followingCount + 1, userSocialClass.followedByCurrentID, 
    true
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.acceptFollowRequest, 
    {
      'userID': userID,
      'currentID': currentID
    }
  );
}

void rejectFollowRequest(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, 
    userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
    userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
    userData.requestedByCurrentID, false, userData.verified, userData.suspended, userData.deleted
  );

  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.rejectFollowRequest, 
    {
      'userID': userData.userID,
      'currentID': currentID
    }
  );
}

void cancelFollowRequest(
  BuildContext context,
  UserDataClass userData
) async{
  String currentID = appStateClass.currentID;
  appStateClass.usersDataNotifiers.value[userData.userID]!.notifier.value = UserDataClass(
    userData.userID, userData.name, userData.username, userData.profilePicLink, 
    userData.dateJoined, userData.birthDate, userData.bio, userData.mutedByCurrentID, 
    userData.blockedByCurrentID, userData.blocksCurrentID, userData.private, 
    false, userData.requestsToCurrentID, userData.verified, userData.suspended, userData.deleted
  );
  
  await fetchDataRepo.fetchData(
    context, 
    RequestPatch.cancelFollowRequest, 
    {
      'userID': userData.userID,
      'currentID': currentID
    }
  );
}

