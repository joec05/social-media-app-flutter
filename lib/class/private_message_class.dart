import 'package:social_media_app/class/media_data_class.dart';

class PrivateMessageClass {
  String messageID;
  String type; 
  String content; 
  String sender;
  String uploadTime; 
  List<MediaDatasClass> mediasDatas; 
  List<String> deletedList;
  
  PrivateMessageClass(
    this.messageID, this.type, this.content, this.sender, this.uploadTime, this.mediasDatas,
    this.deletedList
  );

  factory PrivateMessageClass.fromMap(Map map, List<MediaDatasClass> mediasDatas){
    return PrivateMessageClass(
      map['message_id'], map['type'], map['content'], map['sender'], map['upload_time'], 
      mediasDatas, List<String>.from(map['deleted_list'])
    );
  }
}