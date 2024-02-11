import 'package:social_media_app/global_files.dart';

class GroupMessageClass {
  String messageID;
  String type; 
  String content; 
  String sender;
  String uploadTime; 
  List<MediaDatasClass> mediasDatas; 
  List<String> deletedList;
  
  GroupMessageClass(
    this.messageID, this.type, this.content, this.sender, this.uploadTime, this.mediasDatas,
    this.deletedList
  );

  factory GroupMessageClass.fromMap(Map map, List<MediaDatasClass> mediasDatas){
    return GroupMessageClass(
      map['message_id'], map['type'], map['content'], map['sender'], map['upload_time'], 
      mediasDatas, List<String>.from(map['deleted_list'])
    );
  }
}