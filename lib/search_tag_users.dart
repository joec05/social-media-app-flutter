import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/custom/custom_button.dart';
import 'package:social_media_app/mixin/lifecycle_listener_mixin.dart';
import 'package:social_media_app/appdata/global_library.dart';
import 'package:social_media_app/state/main.dart';
import 'class/user_data_class.dart';
import 'custom/custom_simple_user_data_widget.dart';
import 'styles/app_styles.dart';

var dio = Dio();

class SearchTagUsersWidget extends StatelessWidget {
  final Function onUserIsSelected;
  const SearchTagUsersWidget({super.key, required this.onUserIsSelected});

  @override
  Widget build(BuildContext context) {
    return _SearchTagUsersWidgetStateful(onUserIsSelected: onUserIsSelected);
  }
}

class _SearchTagUsersWidgetStateful extends StatefulWidget {
  final Function onUserIsSelected;
  const _SearchTagUsersWidgetStateful({required this.onUserIsSelected});

  @override
  State<_SearchTagUsersWidgetStateful> createState() => __SearchTagUsersWidgetStatefulState();
}

class __SearchTagUsersWidgetStatefulState extends State<_SearchTagUsersWidgetStateful> with LifecycleListenerMixin{
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<bool> isSearching = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<List<String>> selectedUsersID = ValueNotifier([]);
  ValueNotifier<List<String>> selectedUsersUsername = ValueNotifier([]);
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
    selectedUsersID.dispose();
    selectedUsersUsername.dispose();
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
          'paginationLimit': searchTagUsersFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchSearchedTagUsers', data: stringified);
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

  void continueTag(){
    Navigator.pop(context);
    widget.onUserIsSelected(selectedUsersUsername.value, selectedUsersID.value);
  }

  @override
  Widget build(BuildContext context){
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 56, 54, 54),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0)
        )
      ),
      child: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: getScreenHeight() * 0.015),
              Container(
                height: getScreenHeight() * 0.01,
                width: getScreenWidth() * 0.15,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(10))
                )
              ),
              SizedBox(height: getScreenHeight() * 0.015),
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
            ]
          ),
          Flexible(
            child: SingleChildScrollView(
              child: ValueListenableBuilder(
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
                                toggleSelectUser(users[i], appStateClass.usersDataNotifiers.value[users[i]]!.notifier.value.username);
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
              ),
            ),
          ),
          Column(
            children: [
              ValueListenableBuilder(
                valueListenable: selectedUsersID,
                builder: (context, selectedUsersID, child){
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: getScreenHeight() * 0.025, horizontal: getScreenWidth() * 0.025),
                    child: CustomButton(
                      width: double.infinity, height: getScreenHeight() * 0.08,
                      buttonColor: Colors.red, buttonText: 'Continue',
                      onTapped: selectedUsersID.isNotEmpty ? () => continueTag() : null,
                      setBorderRadius: true
                    ),
                  );
                }
              )
            ]
          )
        ],
      ),
    );
  }
}