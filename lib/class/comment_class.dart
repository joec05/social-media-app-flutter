import 'package:social_media_app/class/media_data_class.dart';

class CommentClass {
  final String commentID;
  final String type;
  String content;
  final String sender;
  final String uploadTime;
  List<MediaDatasClass> mediasDatas;
  int likesCount;
  bool likedByCurrentID;
  int bookmarksCount;
  bool bookmarkedByCurrentID;
  int commentsCount;
  final String parentPostID;
  final String parentPostSender;
  final String parentPostType;
  bool deleted;
  
  CommentClass(
    this.commentID, this.type, this.content, this.sender, this.uploadTime, 
    this.mediasDatas, this.likesCount, this.likedByCurrentID, this.bookmarksCount, this.bookmarkedByCurrentID, 
    this.commentsCount, this.parentPostType, this.parentPostID, this.parentPostSender, 
    this.deleted
  );

  factory CommentClass.fromMap(Map map, List<MediaDatasClass> mediasDatas){
    return CommentClass(
      map['comment_id'], 
      map['type'], 
      map['content'], 
      map['sender'], 
      map['upload_time'], 
      mediasDatas,
      map['likes_count'],
      map['liked_by_current_id'], 
      map['bookmarks_count'],
      map['bookmarked_by_current_id'], 
      map['comments_count'],  
      map['parent_post_type'],
      map['parent_post_id'],
      map['parent_post_sender'],
      map['deleted']
    );
  }

  factory CommentClass.getFakeData(){
    return CommentClass('', '', '', '', '', [], 0, false, 0, false, 0, '', '', '', false);
  }
}