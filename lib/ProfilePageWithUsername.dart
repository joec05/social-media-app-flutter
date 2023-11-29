// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/ProfileRepliesPage.dart';
import 'package:social_media_app/ProfilePostsPage.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserDataNotifier.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/class/UserSocialNotifier.dart';
import 'package:social_media_app/custom/CustomProfileHeader.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/redux/reduxLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';

class ProfilePageWithUsernameWidget extends StatelessWidget {
  final String username;
  const ProfilePageWithUsernameWidget({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageWithUsernameWidgetStateful(username: username);
  }
}

class _ProfilePageWithUsernameWidgetStateful extends StatefulWidget {
  final String username;
  const _ProfilePageWithUsernameWidgetStateful({required this.username});

  @override
  State<_ProfilePageWithUsernameWidgetStateful> createState() => _ProfilePageWithUsernameWidgetStatefulState();
}

var dio = Dio();

class _ProfilePageWithUsernameWidgetStatefulState extends State<_ProfilePageWithUsernameWidgetStateful> with SingleTickerProviderStateMixin, LifecycleListenerMixin{
  late TabController _tabController;
  ValueNotifier<String> userID = ValueNotifier('');
  late String username;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<UniqueKey?> profilePostsWidgetUniqueKey = ValueNotifier(null);
  ValueNotifier<UniqueKey?> profileRepliesWidgetUniqueKey = ValueNotifier(null);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    username = widget.username;
    runDelay(() async => fetchProfileDataWithUsername(), actionDelayTime);
    _tabController = TabController(length: 2, vsync: this);
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

  @override void dispose(){
    super.dispose();
    _tabController.dispose();
    isLoading.dispose();
    userID.dispose();
    profilePostsWidgetUniqueKey.dispose();
    profileRepliesWidgetUniqueKey.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchProfileDataWithUsername() async{
    try {
      if(mounted){
        isLoading.value = true;
        profilePostsWidgetUniqueKey.value = UniqueKey();
        profileRepliesWidgetUniqueKey.value = UniqueKey();
        String stringified = jsonEncode({
          'username': username,
          'currentID': fetchReduxDatabase().currentID,
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserProfileSocialsWithUsername', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            Map userProfileData = res.data['userProfileData'];
            if(userProfileData['code'] == 0){
            }else{
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              Map userSocialsData = res.data['userSocialsData'];
              UserSocialClass userSocialClass = UserSocialClass.fromMap(userSocialsData);
              if(mounted){
                updateUserData(userDataClass, context);
                updateUserSocials(userDataClass, userSocialClass, context);
                userID.value = userProfileData['user_id'];
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userID,
      builder: (context, userID, child) {
        if(userID.isNotEmpty){
          return Scaffold(
            appBar: AppBar(
              title: const Text('User Account'), 
              titleSpacing: defaultAppBarTitleSpacing,
              flexibleSpace: Container(
                decoration: defaultAppBarDecoration
              ),
              actions: <Widget>[
                StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
                  converter: (store) => store.state.usersDatasNotifiers,
                  builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
                    return StoreConnector<AppState, ValueNotifier<Map<String, UserSocialNotifier>>>(
                      converter: (store) => store.state.usersSocialsNotifiers,
                      builder: (context, ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers){
                        if(usersDatasNotifiers.value[userID] != null){
                          return ValueListenableBuilder(
                            valueListenable: usersDatasNotifiers.value[userID]!.notifier,
                            builder: ((context, userData, child) {
                              if(!userData.suspended && !userData.deleted){
                                if(userData.userID != fetchReduxDatabase().currentID){
                                  return ValueListenableBuilder(
                                    valueListenable: usersSocialsNotifiers.value[userID]!.notifier,
                                    builder: ((context, userSocials, child) {
                                      return PopupMenuButton(
                                        onSelected: (result) {
                                          if(result == 'Unmute'){
                                            runDelay(() => unmuteUser(userData), actionDelayTime);
                                          }else if(result == 'Mute'){
                                            runDelay(() => muteUser(userData), actionDelayTime);
                                          }else if(result == 'Unblock'){
                                            runDelay(() => unblockUser(userData), actionDelayTime);
                                          }else if(result == 'Block'){
                                            runDelay(() => blockUser(userData, userSocials), actionDelayTime);
                                          }
                                        },
                                        itemBuilder: (context) => <PopupMenuEntry>[
                                          PopupMenuItem(
                                            value: userData.mutedByCurrentID ? 'Unmute' : 'Mute',
                                            child: Text(userData.mutedByCurrentID ? 'Unmute ${userData.name}' : 'Mute ${userData.name}')
                                          ),
                                          PopupMenuItem(
                                            value: userData.blockedByCurrentID ? 'Unblock' : 'Block',
                                            child: Text(userData.blockedByCurrentID ? 'Unblock ${userData.name}' : 'Block ${userData.name}')
                                          ),
                                        ]
                                      );
                                    }),
                                  );
                                }
                                return PopupMenuButton(
                                  onSelected: (result) {
                                    if(result == 'Lock Account'){
                                      runDelay(() => lockAccount(userData), actionDelayTime);
                                    }else if(result == 'Unlock Account'){
                                      runDelay(() => unlockAccount(userData), actionDelayTime);
                                    }
                                  },
                                  itemBuilder: (context) => <PopupMenuEntry>[
                                    PopupMenuItem(
                                      value: userData.private ? 'Unlock Account' : 'Lock Account',
                                      child: Text(userData.private ? 'Unlock Account' : 'Lock Account')
                                    ),
                                  ]
                                );
                              }
                              return Container();
                            })
                          );
                        }
                        return Container();
                      }
                    );
                  }
                )
              ]
            ),
            body: Stack(
              children: [
                RefreshIndicator(
                  color: Colors.blue,
                  notificationPredicate: (notification) {
                    return true;
                  },
                  onRefresh: () async{
                    fetchProfileDataWithUsername();
                  },
                  child: NestedScrollView(
                    controller: _scrollController,
                    headerSliverBuilder: (context, bool f) {
                      return <Widget>[
                        SliverToBoxAdapter(
                          child: Center(
                            child: ValueListenableBuilder(
                              valueListenable: isLoading,
                              builder: (context, isLoadingValue, child) {
                                if(!isLoadingValue){
                                  if(userID.isNotEmpty){
                                    return StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
                                      converter: (store) => store.state.usersDatasNotifiers,
                                      builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
                                        return StoreConnector<AppState, ValueNotifier<Map<String, UserSocialNotifier>>>(
                                          converter: (store) => store.state.usersSocialsNotifiers,
                                          builder: (context, ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers){
                                            if(usersDatasNotifiers.value[userID] != null){
                                              return ValueListenableBuilder(
                                                valueListenable: usersDatasNotifiers.value[userID]!.notifier,
                                                builder: ((context, userData, child) {
                                                  return ValueListenableBuilder(
                                                    valueListenable: usersSocialsNotifiers.value[userID]!.notifier,
                                                    builder: ((context, userSocials, child) {
                                                      return CustomProfileHeader(
                                                        userID: userID, userData: userData, userSocials: userSocials, key: UniqueKey()
                                                      );
                                                    }),
                                                  );
                                                }),
                                              );
                                            }
                                            return loadingPageWidget();
                                          }
                                        );
                                      }
                                    );
                                  }else{
                                    return Center(
                                      child: Text('An error occured when fetching the user id', style: TextStyle(fontSize: defaultTextFontSize))
                                    );
                                  }
                                }else{
                                  return loadingPageWidget();
                                }
                              }
                            )
                          ),
                        ),
                        SliverOverlapAbsorber(
                          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                          sliver: SliverAppBar(
                            floating: true, 
                            expandedHeight: 50,
                            pinned: true,
                            snap: true,
                            automaticallyImplyLeading: false,
                            bottom: TabBar(
                              onTap: (selectedIndex) {
                              },
                              isScrollable: false,
                              controller: _tabController,
                              labelColor: Colors.white,
                              indicatorColor: Colors.orange,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 3.0,
                              unselectedLabelColor: Colors.white,
                              tabs: const [
                                Tab(text: 'Posts'),
                                Tab(text: 'Replies'),
                              ],                           
                            )
                          )
                        ),
                      ];
                    },
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: profilePostsWidgetUniqueKey, 
                          builder: (context, uniqueKey, child){
                            if(uniqueKey != null){
                              return ProfilePagePostsWidget(userID: userID, key: uniqueKey, absorberContext: context);
                            }
                            return Container();
                          }
                        ),
                        ValueListenableBuilder(
                          valueListenable: profileRepliesWidgetUniqueKey, 
                          builder: (context, uniqueKey, child){
                            if(uniqueKey != null){
                              return ProfilePageRepliesWidget(userID: userID, key: uniqueKey, absorberContext: context);
                            }
                            return Container();
                          }
                        ),
                      ]
                    )
                  )
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('User Account'), 
            titleSpacing: defaultAppBarTitleSpacing,
            flexibleSpace: Container(
              decoration: defaultAppBarDecoration
            )
          ),
          body: loadingPageWidget()
        );
      }
    );
  }
}
