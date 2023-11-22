class NotificationClass {
  final String type;
  final String sender;
  final String referencedPostID;
  final String referencedPostType;
  final String time;
  final String content;
  final List mediasDatas;
  final String senderName;
  final String senderProfilePicLink;
  final String parentPostType;
  bool postDeleted;
  
  NotificationClass(
    this.type, this.sender, this.referencedPostID, this.referencedPostType, this.time, this.content, this.mediasDatas,
    this.senderName, this.senderProfilePicLink, this.parentPostType, this.postDeleted
  );
}