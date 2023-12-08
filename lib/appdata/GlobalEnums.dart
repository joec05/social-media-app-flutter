enum PaginationStatus{
  loading, error, loaded
}

enum PrivateMessageActions{
  deleteChat
}

enum GroupMessageActions{
  deleteChat
}

enum MediaType{
  image, video, websiteCard
}

enum MediaSourceType {
  network, file, 
}

enum FollowRequestType{
  From, To
}

enum PostDisplayType{
  feed, profilePost, viewPost, searchedPost, bookmark, explore
}

enum UserDisplayType{
  followers, following, likes, bookmarks, searchedUsers, groupMembers, explore
}

enum LoadingState{
  loaded, loading, paginating, refreshing
}