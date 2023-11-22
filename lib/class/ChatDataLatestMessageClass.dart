class ChatDataLatestMessageClass {
  final String messageID;
  final String type;
  final String sender;
  final String content;
  final String uploadTime;
  
  ChatDataLatestMessageClass(
    this.messageID,
    this.type,
    this.sender,
    this.content,
    this.uploadTime
  );

  factory ChatDataLatestMessageClass.fromMap(Map map){
    return ChatDataLatestMessageClass(
      map['latest_message_id'], map['latest_message_type'], map['latest_message_sender'],
      map['latest_message_content'], 
      map['latest_message_upload_time'],
    );
  }
}