import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';
import 'package:uuid/uuid.dart';

/// Controller which is used when the user wants to add other user(s) to the group chat
class AddUsersToGroupController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The chatID of the group chat that will be passed to the controller
  String chatID;

  /// The group profile that will be passed to the controller
  ValueNotifier<GroupProfileClass> groupProfile;

  /// An editing controller for the user to insert a search input
  TextEditingController searchedController = TextEditingController();

  /// True if an API function is running
  ValueNotifier<bool> isSearching = ValueNotifier(false);

  /// A list containing the id of the searched users
  ValueNotifier<List<String>> users = ValueNotifier([]);

  /// A list containing the id of the selected users
  ValueNotifier<List<String>> selectedUsersID = ValueNotifier([]);

  /// A list containing the name of the selected users
  ValueNotifier<List<String>> selectedUsersName = ValueNotifier([]);

  /// True if the search input is in acceptable format
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);

  /// Maximum amount of members a group can contain
  int groupMembersMaxLimit = 30;

  AddUsersToGroupController(
    this.context,
    this.chatID,
    this.groupProfile
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
      }
    });

    /// Listen to sockets to handle group profile data
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
    searchedController.dispose();
    isSearching.dispose();
    users.dispose();
    selectedUsersID.dispose();
    selectedUsersName.dispose();
    verifySearchedFormat.dispose();
  }

  /// Called when the user pressed the search button
  Future<void> searchUsers(bool isPaginating) async{
    if(mounted){
      if(!isSearching.value){
        isSearching.value = true;

        /// Call the API to search for the users based on the search input
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchSearchedAddToGroupUsers, 
          {
            'searchedText': searchedController.text,
            'recipients': groupProfile.value.recipients,
            'currentID': appStateRepo.currentID,
            'currentLength': isPaginating ? users.value.length : 0,
            'paginationLimit': searchTagUsersFetchLimit
          }
        );

        if(mounted) {
          isSearching.value = false;

          /// API successfully ran and the users has been successfully fetched
          if(res != null){

            /// Update the local state
            List userProfileDataList = res['usersProfileData'];
            users.value = [];

            /// Update the users' data in the app state repository as well
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

  /// Called when the user pressed the user widget
  void toggleSelectUser(userID, name){
    if(mounted){
      List<String> selectedUsersIDList = [...selectedUsersID.value];
      if(selectedUsersIDList.contains(userID)){

        /// If the selected users list contains the given user id, remove it from the list
        selectedUsersIDList.remove(userID);
        selectedUsersName.value.remove(name);

      }else{

        /// If the selected users list doesn't contain the given user id, add it to the list
        selectedUsersIDList.add(userID);
        selectedUsersName.value.add(name);

      }
      selectedUsersID.value = [...selectedUsersIDList];
    }
  }

  /// Called when the user pressed the given button
  void addUsersToGroup() async{
    if(mounted){
      try {

        /// Navigate the user out of the page
        Navigator.pop(context);

        if(selectedUsersID.value.length + groupProfile.value.recipients.length > groupMembersMaxLimit){

          /// Display a snackbar error if the expected total amount of members exceeds the maximum amount of group members allowed
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            'Failed to add user(s). Only a maximum of $groupMembersMaxLimit members are allowed for a group chat.'
          );

        }else{
          List<String> messagesID = List.filled(selectedUsersName.value.length, 0).map((e) => const Uuid().v4()).toList();
          String senderName = appStateRepo.usersDataNotifiers.value[appStateRepo.currentID]!.notifier.value.name;
          List<String> contentsList = selectedUsersName.value.map((e) => '$senderName has added $e to the group').toList();
          List<Map> addedUsersDataList = [];
          for(int i = 0; i < selectedUsersID.value.length; i++){
            addedUsersDataList.add(appStateRepo.usersDataNotifiers.value[selectedUsersID.value[i]]!.notifier.value.toMap());
          }

          /// Call the socket to add the selected users to the group members list
          socket.emit("add-users-to-group-to-server", {
            'chatID': chatID,
            'messagesID': messagesID,
            'contentsList': contentsList,
            'type': 'add_users_to_group',
            'sender': appStateRepo.currentID,
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
          
          /// Call the API to add the selected users to the group members list
          await fetchDataRepo.fetchData(
            context,
            RequestPatch.addUsersToGroup,
            {
              'chatID': chatID,
              'messagesID': messagesID,
              'sender': appStateRepo.currentID,
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