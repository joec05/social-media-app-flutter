import 'package:social_media_app/class/MediaDataClass.dart';

class PostClass {
  final String postID;
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
  bool deleted;
  
  PostClass(
    this.postID, this.type, this.content, this.sender, this.uploadTime, this.mediasDatas,
    this.likesCount, this.likedByCurrentID, this.bookmarksCount, this.bookmarkedByCurrentID, 
    this.commentsCount, this.deleted
  );

  Map<String, dynamic> convertToMap(){
    return {
      'postID': postID,
      'type': type,
      'content': content,
      'sender': sender,
      'uploadTime': uploadTime,
      'mediasDatas': mediasDatas,
      'likesCount': likesCount,
      'likedByCurrentID:': likedByCurrentID,
      'bookmarksCount': bookmarksCount,
      'bookmarkedByCurrentID': bookmarkedByCurrentID,
      'commentsCount': commentsCount,
      'deleted': deleted
    };
  }

  factory PostClass.fromMap(Map map, List<MediaDatasClass> mediasDatas){
    return PostClass(
      map['post_id'], 
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
      map['deleted']
    );
  }
}