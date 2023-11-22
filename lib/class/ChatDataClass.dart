import 'package:social_media_app/class/GroupProfileClass.dart';
import 'ChatDataLatestMessageClass.dart';

class ChatDataClass {
  final String chatID;
  final String type;
  final String recipient;
  final ChatDataLatestMessageClass latestMessageData;
  final GroupProfileClass? groupProfileData;
  final bool deleted;
  
  ChatDataClass(
    this.chatID,
    this.type,
    this.recipient,
    this.latestMessageData,
    this.groupProfileData,
    this.deleted
  );

  factory ChatDataClass.fromMap(Map map){
    return ChatDataClass(
      map['chat_id'], map['type'], map['recipient'], ChatDataLatestMessageClass.fromMap(map), 
      map['group_profile_data'] == null ? null : GroupProfileClass(
        map['group_profile_data']['name'], map['group_profile_data']['profile_pic_link'], 
        map['group_profile_data']['description'], List<String>.from(map['members'])
      ), map['deleted']
    );
  }
}