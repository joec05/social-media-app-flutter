import 'dart:async';
import 'dart:convert';
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
    try {
      if(mounted){
        isSearching.value = true;
        String stringified = jsonEncode({
          'searchedText': searchedController.text,
          'currentID': appStateClass.currentID,
          'currentLength': isPaginating ? users.value.length : 0,
          'paginationLimit': searchChatUsersFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchSearchedChatUsers', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List userProfileDataList = res.data['usersProfileData'];
            if(mounted){
              users.value = [];
            }
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              if(mounted){
                updateUserData(userDataClass);
                users.value = [...users.value, userProfileData['user_id']];
              }
            }
          }
          if(mounted){
            isSearching.value = false;
          }
        }
      }
    } on Exception catch (e) {
      
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