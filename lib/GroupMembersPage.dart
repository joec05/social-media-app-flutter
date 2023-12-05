// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomUserDataWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'custom/CustomPagination.dart';

class GroupMembersPage extends StatelessWidget {
  final List<String> usersID;
  const GroupMembersPage({super.key, required this.usersID});

  @override
  Widget build(BuildContext context) {
    return _GroupMembersPageStateful(usersID: usersID);
  }
}

class _GroupMembersPageStateful extends StatefulWidget {
  final List<String> usersID;
  const _GroupMembersPageStateful({required this.usersID});

  @override
  State<_GroupMembersPageStateful> createState() => _GroupMembersPageStatefulState();
}

var dio = Dio();

class _GroupMembersPageStatefulState extends State<_GroupMembersPageStateful> with LifecycleListenerMixin{
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  late List<String> usersID;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingUsersStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<int> totalUsersLength = ValueNotifier(0);

  @override
  void initState(){
    super.initState();
    usersID = widget.usersID;
    if(mounted){
      totalUsersLength.value = widget.usersID.length;
    }
    runDelay(() async => fetchGroupMembersData(users.value.length, false), actionDelayTime);
    _scrollController.addListener(() {
      if(mounted){
        if(_scrollController.position.pixels > animateToTopMinHeight){
          if(!displayFloatingBtn.value){
            displayFloatingBtn.value = true;
          }
        }else{
          if(displayFloatingBtn.value){
            displayFloatingBtn.value = false;
          }
        }
      }
    });
  }

  @override
  void dispose(){
    super.dispose();
    _scrollController.dispose();
    displayFloatingBtn.dispose();
    isLoading.dispose();
    users.dispose();
    loadingUsersStatus.dispose();
    totalUsersLength.dispose();
  }

  Future<void> fetchGroupMembersData(int currentUsersLength, bool isRefreshing) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'usersID': usersID,
          'currentID': appStateClass.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchGroupMembersData', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List followersProfileDatasList = res.data['usersProfileData'];
            List followersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              users.value = [];
            }
            for(int i = 0; i < followersProfileDatasList.length; i++){
              Map userProfileData = followersProfileDatasList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(followersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass, context);
                updateUserSocials(userDataClass, userSocialClass, context);
                users.value = [userProfileData['user_id'], ...users.value];
              }
            }
          }
          if(mounted){
            isLoading.value = false;
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> loadMoreUsers() async{
    try {
      if(mounted){
        loadingUsersStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchGroupMembersData(users.value.length, false);
          if(mounted){
            loadingUsersStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Group Members'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Builder(
              builder: (BuildContext context) {
                return ValueListenableBuilder(
                  valueListenable: loadingUsersStatus,
                  builder: (context, loadingStatusValue, child){
                    return ValueListenableBuilder(
                      valueListenable: totalUsersLength,
                      builder: (context, totalPostsLengthValue, child){
                        return ValueListenableBuilder(
                          valueListenable: users,
                          builder: ((context, users, child) {
                            return LoadMoreBottom(
                              addBottomSpace: users.length < totalUsersLength.value,
                              loadMore: () async{
                                if(users.length < totalUsersLength.value){
                                  await loadMoreUsers();
                                }
                              },
                              status: loadingStatusValue,
                              refresh: null,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: <Widget>[
                                  SliverList(delegate: SliverChildBuilderDelegate(
                                    childCount: users.length, 
                                    (context, index) {
                                      if(appStateClass.usersDataNotifiers.value[users[index]] != null){
                                        return ValueListenableBuilder(
                                          valueListenable: appStateClass.usersDataNotifiers.value[users[index]]!.notifier, 
                                          builder: ((context, userData, child) {
                                            return ValueListenableBuilder(
                                              valueListenable: appStateClass.usersSocialsNotifiers.value[users[index]]!.notifier, 
                                              builder: ((context, userSocial, child) {
                                                return CustomUserDataWidget(
                                                  userData: userData,
                                                  userSocials: userSocial,
                                                  userDisplayType: UserDisplayType.groupMembers,
                                                  isLiked: null,
                                                  isBookmarked: null,
                                                  profilePageUserID: null,
                                                  key: UniqueKey()
                                                );
                                              })
                                            );
                                          })
                                        );
                                      }
                                      return Container();                                                
                                    }
                                  ))                                    
                                ]
                              )
                            );
                          })
                        );
                      }
                    );
                  }
                );
              }
            )
          ),
          ValueListenableBuilder(
            valueListenable: isLoading,
            builder: ((context, isLoadingValue, child) {
              if(isLoadingValue){
                return loadingPageWidget();
              }
              return Container();
            })
          )
        ]
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 10),
                  curve:Curves.fastOutSlowIn
                  );
              },
              child: const Icon(Icons.arrow_upward),
            )
          );
        }
      )
    );
  }
}