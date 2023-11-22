// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/GroupChatRoom.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/redux/reduxLibrary.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import 'PrivateChatRoom.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'class/UserDataClass.dart';
import 'class/UserDataNotifier.dart';
import 'custom/CustomSimpleUserDataWidget.dart';
import 'styles/AppStyles.dart';

var dio = Dio();

class SearchChatUsersWidget extends StatelessWidget {
  const SearchChatUsersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SearchChatUsersWidgetStateful();
  }
}

class _SearchChatUsersWidgetStateful extends StatefulWidget {
  const _SearchChatUsersWidgetStateful();

  @override
  State<_SearchChatUsersWidgetStateful> createState() => __SearchChatUsersWidgetStatefulState();
}

class __SearchChatUsersWidgetStatefulState extends State<_SearchChatUsersWidgetStateful> with LifecycleListenerMixin{
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingUsersStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<List<String>> selectedUsersID = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);

  @override
  void initState(){
    super.initState();
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
      }
    });
  }

  @override void dispose(){
    super.dispose();
    searchedController.dispose();
    isSearching.dispose();
    users.dispose();
    loadingUsersStatus.dispose();
    selectedUsersID.dispose();
    verifySearchedFormat.dispose();
  }

  Future<void> searchUsers(bool isPaginating) async{
    try {
      if(mounted){
        isSearching.value = true;
        String stringified = jsonEncode({
          'searchedText': searchedController.text,
          'currentID': fetchReduxDatabase().currentID,
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
                updateUserData(userDataClass, context);
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
      doSomethingWithException(e);
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
          page: GroupChatRoomWidget(chatID: null, recipients: [fetchReduxDatabase().currentID, ...selectedUsersID.value],)
        )
      ), navigatorDelayTime);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Users'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: selectedUsersID,
            builder: (context, selectedUsersID, child){
              return CustomButton(
                width: getScreenWidth() * 0.25, height: kToolbarHeight, 
                buttonColor: Colors.red, buttonText: 'Continue',
                onTapped: selectedUsersID.isNotEmpty ? () => navigateToChat() : null,
                setBorderRadius: false
              );
            }
          )
        ]
      ),
      body: ListView(
        children: [
          containerMargin(
            Row(
              children: [
                SizedBox(
                  width: getScreenWidth() * 0.75,
                  height: getScreenHeight() * 0.075,
                  child: TextField(
                    controller: searchedController,
                    decoration: generateSearchTextFieldDecoration('user'),
                  )
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isSearching,
                  builder: (context, bool isSearchingValue, child){
                    return ValueListenableBuilder<bool>(
                      valueListenable: verifySearchedFormat,
                      builder: (context, bool searchedVerified, child){
                        return CustomButton(
                          width: getScreenWidth() * 0.25, height: getScreenHeight() * 0.075, 
                          buttonColor: Colors.red, buttonText: 'Search',
                          onTapped: !isSearchingValue && searchedVerified ? () => searchUsers(false) : null,
                          setBorderRadius: false
                        );
                      }
                    );
                  }
                )
              ],
            ),
            EdgeInsets.symmetric(vertical: defaultTextFieldVerticalMargin)
          ),
          StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
            converter: (store) => store.state.usersDatasNotifiers,
            builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
              return ValueListenableBuilder(
                valueListenable: users, 
                builder: (context, users, child){
                  return ValueListenableBuilder(
                    valueListenable: selectedUsersID, 
                    builder: (context2, selectedUsersID, child2){
                      return Column(
                        children: [
                          for(int i = 0; i < users.length; i++)
                          InkWell(
                            splashFactory: InkRipple.splashFactory,
                            onTap: (){
                            },
                            child: GestureDetector(
                              onTap: (){
                                toggleSelectUser(users[i]);
                              },
                              child: Container(
                                color: selectedUsersID.contains(users[i]) ? Colors.grey.withOpacity(0.5) : Colors.transparent,
                                child: CustomSimpleUserDataWidget(
                                  userData: usersDatasNotifiers.value[users[i]]!.notifier.value,
                                  key: UniqueKey()
                                )
                              )
                            )
                          )
                        ],
                      );
                    }
                  );
                }
              );
            }
          )
        ],
      ),
    );
  }
}