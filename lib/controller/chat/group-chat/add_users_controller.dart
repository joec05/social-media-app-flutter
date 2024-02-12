import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

class AddUsersToGroupController {
  BuildContext context;
  String chatID;
  ValueNotifier<GroupProfileClass> groupProfile;
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<List<String>> selectedUsersID = ValueNotifier([]);
  ValueNotifier<List<String>> selectedUsersName = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);
  int groupMembersMaxLimit = 30;

  AddUsersToGroupController(
    this.context,
    this.chatID,
    this.groupProfile
  );

  bool get mounted => context.mounted;

  void initializeController(){
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
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
    searchedController.dispose();
    isSearching.dispose();
    users.dispose();
    selectedUsersID.dispose();
    selectedUsersName.dispose();
    verifySearchedFormat.dispose();
  }

  Future<void> searchUsers(bool isPaginating) async{
    if(mounted){
      if(!isSearching.value){
        isSearching.value = true;
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchSearchedAddToGroupUsers, 
          {
            'searchedText': searchedController.text,
            'recipients': groupProfile.value.recipients,
            'currentID': appStateClass.currentID,
            'currentLength': isPaginating ? users.value.length : 0,
            'paginationLimit': searchTagUsersFetchLimit
          }
        );
        if(mounted) {
          isSearching.value = false;
          if(res != null){
            List userProfileDataList = res.data['usersProfileData'];
            users.value = [];
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              updateUserData(userDataClass);
              users.value = [...users.value, userProfileData['user_id']];
            }
          }
        }
      }
    }
  }

  void toggleSelectUser(userID, name){
    if(mounted){
      List<String> selectedUsersIDList = [...selectedUsersID.value];
      if(selectedUsersIDList.contains(userID)){
        selectedUsersIDList.remove(userID);
        selectedUsersName.value.remove(name);
      }else{
        selectedUsersIDList.add(userID);
        selectedUsersName.value.add(name);
      }
      selectedUsersID.value = [...selectedUsersIDList];
    }
  }

  void addUsersToGroup() async{
    if(mounted){
      try {
        Navigator.pop(context);
        if(selectedUsersID.value.length + groupProfile.value.recipients.length > groupMembersMaxLimit){
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            'Failed to add user(s). Only a maximum of $groupMembersMaxLimit members are allowed for a group chat.'
          );
        }else{
          List<String> messagesID = List.filled(selectedUsersName.value.length, 0).map((e) => const Uuid().v4()).toList();
          String senderName = appStateClass.usersDataNotifiers.value[appStateClass.currentID]!.notifier.value.name;
          List<String> contentsList = selectedUsersName.value.map((e) => '$senderName has added $e to the group').toList();
          List<Map> addedUsersDataList = [];
          for(int i = 0; i < selectedUsersID.value.length; i++){
            addedUsersDataList.add(appStateClass.usersDataNotifiers.value[selectedUsersID.value[i]]!.notifier.value.toMap());
          }
          socket.emit("add-users-to-group-to-server", {
            'chatID': chatID,
            'messagesID': messagesID,
            'contentsList': contentsList,
            'type': 'add_users_to_group',
            'sender': appStateClass.currentID,
            'recipients': groupProfile.value.recipients,
            'mediasDatas': [],
            'addedUsersID': selectedUsersID.value,
            'groupProfileData': {
              'name': groupProfile.value.name,
              'profilePicLink': groupProfile.value.profilePicLink,
              'description': groupProfile.value.description
            },
            'addedUsersData': addedUsersDataList
          });
          await fetchDataRepo.fetchData(
            context,
            RequestPatch.addUsersToGroup,
            {
              'chatID': chatID,
              'messagesID': messagesID,
              'sender': appStateClass.currentID,
              'recipients': groupProfile.value.recipients,
              'addedUsersID': selectedUsersID.value,
            }
          );
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
}