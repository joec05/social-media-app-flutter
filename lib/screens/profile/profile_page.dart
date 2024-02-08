import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/class/user/user_social_class.dart';
import 'package:social_media_app/constants/app_state_actions.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/constants/server_actions.dart';
import 'package:social_media_app/custom/profile/custom_profile_header.dart';
import 'package:social_media_app/mixin/lifecycle_listener.dart';
import 'package:social_media_app/screens/profile/profile_posts_page.dart';
import 'package:social_media_app/screens/profile/profile_replies_page.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';

class ProfilePageWidget extends StatelessWidget {
  final String userID;
  const ProfilePageWidget({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageWidgetStateful(userID: userID);
  }
}

class _ProfilePageWidgetStateful extends StatefulWidget {
  final String userID;
  const _ProfilePageWidgetStateful({required this.userID});

  @override
  State<_ProfilePageWidgetStateful> createState() => _ProfilePageWidgetStatefulState();
}

var dio = Dio();

class _ProfilePageWidgetStatefulState extends State<_ProfilePageWidgetStateful> with SingleTickerProviderStateMixin, LifecycleListenerMixin{
  late TabController _tabController;
  late String userID;
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  ValueNotifier<UniqueKey?> profilePostsWidgetUniqueKey = ValueNotifier(null);
  ValueNotifier<UniqueKey?> profileRepliesWidgetUniqueKey = ValueNotifier(null);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    _tabController = TabController(length: 2, vsync: this);
    runDelay(() async => fetchProfileData(), 0);
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
    profilePostsWidgetUniqueKey.dispose();
    profileRepliesWidgetUniqueKey.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchProfileData() async{
    try {
      if(mounted){
        isLoading.value = true;
        profilePostsWidgetUniqueKey.value = UniqueKey();
        profileRepliesWidgetUniqueKey.value = UniqueKey();
        String stringified = jsonEncode({
          'userID': userID,
          'currentID': appStateClass.currentID,
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserProfileSocials', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            Map userProfileData = res.data['userProfileData'];
            if(userProfileData['code'] == 0){
            }else{
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              Map userSocialsData = res.data['userSocialsData'];
              UserSocialClass userSocialClass = UserSocialClass.fromMap(userSocialsData);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
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
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('User Account'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        ),
        actions: <Widget>[
          appStateClass.usersDataNotifiers.value[userID] != null ?
            ValueListenableBuilder(
              valueListenable: appStateClass.usersDataNotifiers.value[userID]!.notifier,
              builder: ((context, userData, child) {
                if(!userData.suspended && !userData.deleted){
                  if(userData.userID != appStateClass.currentID){
                    return ValueListenableBuilder(
                      valueListenable: appStateClass.usersSocialsNotifiers.value[userID]!.notifier,
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
            )
          : Container()
        ]
      ),
      body: RefreshIndicator(
        color: Colors.blue,
        notificationPredicate: (notification) {
          return true;
        },
        onRefresh: fetchProfileData,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          headerSliverBuilder: (context, bool f) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: isLoading,
                    builder: (context, isLoadingValue, child) {
                      if(!isLoadingValue){
                        if(appStateClass.usersDataNotifiers.value[userID] != null){
                          return ValueListenableBuilder(
                            valueListenable: appStateClass.usersDataNotifiers.value[userID]!.notifier,
                            builder: ((context, userData, child) {
                              return CustomProfileHeader(
                                userID: userID, userData: userData, key: UniqueKey(),
                                skeletonMode: false,
                              );
                            }),
                          );
                        }
                        return Container();
                      }else{
                        return shimmerSkeletonWidget(
                          CustomProfileHeader(
                            userID: userID, 
                            userData: UserDataClass.getFakeData(), 
                            skeletonMode: true,
                            key: UniqueKey()
                          ),
                        );
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
