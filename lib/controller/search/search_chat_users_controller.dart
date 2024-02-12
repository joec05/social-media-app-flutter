import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchChatUsersController {
  BuildContext context;
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<List<String>> selectedUsersID = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);

  SearchChatUsersController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
      }
    });
  }

  void dispose(){
    searchedController.dispose();
    isSearching.dispose();
    users.dispose();
    paginationStatus.dispose();
    selectedUsersID.dispose();
    verifySearchedFormat.dispose();
  }

  Future<void> searchUsers(bool isPaginating) async{
    if(mounted){
      isSearching.value = true;
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchSearchedChatUsers, 
        {
          'searchedText': searchedController.text,
          'currentID': appStateClass.currentID,
          'currentLength': isPaginating ? users.value.length : 0,
          'paginationLimit': searchChatUsersFetchLimit
        }
      );
      if(mounted) {
        isSearching.value = false;
        if(res != null) {
          List userProfileDataList = res.data['usersProfileData'];
          users.value = [];
          for(int i = 0; i < userProfileDataList.length; i++) {
            Map userProfileData = userProfileDataList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            updateUserData(userDataClass);
            users.value = [...users.value, userProfileData['user_id']];
          }
        }
      }
    }
  }

  void toggleSelectUser(userID){
    List<String> selectedUsersIDList = [...selectedUsersID.value];
    if(selectedUsersIDList.contains(userID)){
      selectedUsersIDList.remove(userID);
    }else{
      selectedUsersIDList.add(userID);
    }
    if(mounted){
      selectedUsersID.value = [...selectedUsersIDList];
    }
  }

  void navigateToChat(){
    if(selectedUsersID.value.length == 1){
      runDelay(() => Navigator.push(
        context,
        SliderRightToLeftRoute(
          page: PrivateChatRoomWidget(chatID: null, recipient: selectedUsersID.value[0])
        )
      ), navigatorDelayTime);
    }else{
      runDelay(() => Navigator.push(
        context,
        SliderRightToLeftRoute(
          page: GroupChatRoomWidget(chatID: null, recipients: [appStateClass.currentID, ...selectedUsersID.value],)
        )
      ), navigatorDelayTime);
    }
  }
}