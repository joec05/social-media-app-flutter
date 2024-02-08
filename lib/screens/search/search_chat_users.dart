import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/constants/app_state_actions.dart';
import 'package:social_media_app/constants/global_enums.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/basic-widget/custom_button.dart';
import 'package:social_media_app/custom/user/custom_simple_user_data_widget.dart';
import 'package:social_media_app/mixin/lifecycle_listener.dart';
import 'package:social_media_app/screens/chat/group-chat/group_chat_room.dart';
import 'package:social_media_app/screens/chat/private-chat/private_chat_room.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/transition/navigation.dart';

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
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
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
          page: GroupChatRoomWidget(chatID: null, recipients: [appStateClass.currentID, ...selectedUsersID.value],)
        )
      ), navigatorDelayTime);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Message Users'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: selectedUsersID,
            builder: (context, selectedUsersID, child){
              return Padding(
                padding: EdgeInsets.symmetric(vertical: kToolbarHeight * 0.15, horizontal: getScreenWidth() * 0.025),
                child: CustomButton(
                  width: getScreenWidth() * 0.25, height: kToolbarHeight, 
                  buttonColor: Colors.red, buttonText: 'Continue',
                  onTapped: selectedUsersID.isNotEmpty ? () => navigateToChat() : null,
                  setBorderRadius: true
                ),
              );
            }
          )
        ]
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isSearching,
            builder: (context, bool isSearchingValue, child){
              return ValueListenableBuilder<bool>(
                valueListenable: verifySearchedFormat,
                builder: (context, bool searchedVerified, child){
                  return SizedBox(
                    width: getScreenWidth(),
                    height: getScreenHeight() * 0.075,
                    child: TextField(
                      controller: searchedController,
                      decoration: generateSearchTextFieldDecoration('user', Icons.search, !isSearchingValue && searchedVerified ? () => searchUsers(false) : null),
                    )
                  );
                }
              );
            }
          ),
          ValueListenableBuilder(
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
                              userData: appStateClass.usersDataNotifiers.value[users[i]]!.notifier.value,
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
          )
        ],
      ),
    );
  }
}