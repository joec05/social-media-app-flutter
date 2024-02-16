import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

class GroupProfileController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The chatID of the group chat that will be passed to the controller
  String chatID;

  /// The group profile that will be passed to the controller
  ValueNotifier<GroupProfileClass> groupProfile;
  
  GroupProfileController(
    this.context,
    this.chatID,
    this.groupProfile
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){

    /// Initialize the socket listeners
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

  /// Dispose everything. Called at every page's dispose function
  void dispose(){
    groupProfile.dispose();
  }

  /// Called when the user pressed the given button
  void leaveGroup() async{
    if(mounted){
      try {
        String messageID = const Uuid().v4();
        String senderName = appStateRepo.usersDataNotifiers.value[appStateRepo.currentID]!.notifier.value.name;
        String content = '$senderName has left the group';
        groupProfile.value.recipients.remove(appStateRepo.currentID);

        /// Call the socket to remove the current user id from the recipients list
        socket.emit("leave-group-to-server", {
          'chatID': chatID,
          'messageID': messageID,
          'content': content,
          'type': 'leave_group',
          'sender': appStateRepo.currentID,
          'recipients': groupProfile.value.recipients,
          'mediasDatas': [],
        });

        /// Call the API to remove the current user id from the recipients list
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestPatch.leaveGroup, 
          {
            'chatID': chatID,
            'messageID': messageID,
            'sender': appStateRepo.currentID,
            'recipients': groupProfile.value.recipients,
          }
        );

        if(res != null && mounted) {
          
          /// Go back to the chats list page
          Navigator.popUntil(context, (route){
            return route.settings.name == '/chats-list';
          });
          
        }

      } catch (_) {
        if(mounted) {
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.api
          );
        }
      }
    }
  }
}