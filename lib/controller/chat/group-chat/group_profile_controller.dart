import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

class GroupProfileController {
  BuildContext context;
  String chatID;
  ValueNotifier<GroupProfileClass> groupProfile;
  
  GroupProfileController(
    this.context,
    this.chatID,
    this.groupProfile
  );

  bool get mounted => context.mounted;

  void initializeController(){
    socket.on("edit-group-profile-page-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          data['newData']['name'], data['newData']['profilePicLink'], data['newData']['description'], groupProfile.value.recipients
        );
      }
    });
    socket.on("send-leave-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of(data['recipients'])
        );
      }
    });
    socket.on("send-add-users-to-group-announcement-$chatID", ( data ) async{
      if(mounted && data != null){
        groupProfile.value = GroupProfileClass(
          groupProfile.value.name, groupProfile.value.profilePicLink, 
          groupProfile.value.description, List<String>.of([...data['recipients'], ...data['addedUsersID']])
        );
      }
    });
  }

  void dispose(){
    groupProfile.dispose();
  }

  void leaveGroup() async{
    try {
      String messageID = const Uuid().v4();
      String senderName = appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.name;
      String content = '$senderName has left the group';
      groupProfile.value.recipients.remove(appStateClass.currentID);
      socket.emit("leave-group-to-server", {
        'chatID': chatID,
        'messageID': messageID,
        'content': content,
        'type': 'leave_group',
        'sender': appStateClass.currentID,
        'recipients': groupProfile.value.recipients,
        'mediasDatas': [],
      });
      String stringified = jsonEncode({
        'chatID': chatID,
        'messageID': messageID,
        'sender': appStateClass.currentID,
        'recipients': groupProfile.value.recipients,
      });
      var res = await dio.patch('$serverDomainAddress/users/leaveGroup', data: stringified);
      if(res.data.isNotEmpty && mounted){
        Navigator.popUntil(context, (route){
          return route.settings.name == '/chats-list';
        });
      }
    } catch (_) {
      if(mounted){
        handler.displaySnackbar(
          context, 
          SnackbarType.error, 
          tErr.api
        );
      }
    }
  }

  
}