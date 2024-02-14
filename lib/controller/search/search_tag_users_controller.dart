import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchTagUsersController {
  BuildContext context;
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<List<String>> selectedUsersID = ValueNotifier([]);
  ValueNotifier<List<String>> selectedUsersUsername = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);

  SearchTagUsersController(
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
    selectedUsersID.dispose();
    selectedUsersUsername.dispose();
    verifySearchedFormat.dispose();
  }

  Future<void> searchUsers(bool isPaginating) async{
    if(mounted){
      isSearching.value = true;
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchSearchedTagUsers, 
        {
          'searchedText': searchedController.text,
          'currentID': appStateRepo.currentID,
          'currentLength': isPaginating ? users.value.length : 0,
          'paginationLimit': searchTagUsersFetchLimit
        }
      );
      if(mounted) {
        isSearching.value = false;
        if(res != null) {
          List userProfileDataList = res['usersProfileData'];
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

  void toggleSelectUser(userID, username){
    List<String> selectedUsersIDList = [...selectedUsersID.value];
    if(selectedUsersIDList.contains(userID)){
      selectedUsersIDList.remove(userID);
      selectedUsersUsername.value.remove(username);
    }else{
      selectedUsersIDList.add(userID);
      selectedUsersUsername.value.add(username);
    }
    if(mounted){
      selectedUsersID.value = [...selectedUsersIDList];
    }
  }
}