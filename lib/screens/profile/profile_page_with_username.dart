import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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

class _ProfilePageWithUsernameWidgetStatefulState extends State<_ProfilePageWithUsernameWidgetStateful> with SingleTickerProviderStateMixin, LifecycleListenerMixin{
  late ProfileWithUsernameController controller;

  @override
  void initState(){
    super.initState();
    controller = ProfileWithUsernameController(
      context, 
      widget.username,
      TabController(length: 2, vsync: this)
    );
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller.userID,
      builder: (context, userID, child) {
        if(userID.isNotEmpty){
          return Scaffold(
            appBar: AppBar(
              leading: defaultLeadingWidget(context),
              title: const Text('User Account'), 
              titleSpacing: defaultAppBarTitleSpacing,
              flexibleSpace: Container(
                decoration: defaultAppBarDecoration
              ),
              actions: <Widget>[
                appStateRepo.usersDataNotifiers.value[userID] != null ? 
                  ValueListenableBuilder(
                    valueListenable: appStateRepo.usersDataNotifiers.value[userID]!.notifier,
                    builder: ((context, userData, child) {
                      if(!userData.suspended && !userData.deleted){
                        if(userData.userID != appStateRepo.currentID){
                          return ValueListenableBuilder(
                            valueListenable: appStateRepo.usersSocialsNotifiers.value[userID]!.notifier,
                            builder: ((context, userSocials, child) {
                              return PopupMenuButton(
                                onSelected: (result) {
                                  if(result == 'Unmute'){
                                    runDelay(() => unmuteUser(context, userData), actionDelayTime);
                                  }else if(result == 'Mute'){
                                    runDelay(() => muteUser(context, userData), actionDelayTime);
                                  }else if(result == 'Unblock'){
                                    runDelay(() => unblockUser(context, userData), actionDelayTime);
                                  }else if(result == 'Block'){
                                    runDelay(() => blockUser(context, userData, userSocials), actionDelayTime);
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
                              runDelay(() => lockAccount(context, userData), actionDelayTime);
                            }else if(result == 'Unlock Account'){
                              runDelay(() => unlockAccount(context, userData), actionDelayTime);
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
            body: Stack(
              children: [
                RefreshIndicator(
                  color: Colors.blue,
                  notificationPredicate: (notification) {
                    return true;
                  },
                  onRefresh: () async{
                    controller.fetchProfileDataWithUsername();
                  },
                  child: NestedScrollView(
                    controller: controller.scrollController,
                    headerSliverBuilder: (context, bool f) {
                      return <Widget>[
                        SliverToBoxAdapter(
                          child: Center(
                            child: ValueListenableBuilder(
                              valueListenable: controller.isLoading,
                              builder: (context, isLoadingValue, child) {
                                if(!isLoadingValue){
                                  if(userID.isNotEmpty){
                                    if(appStateRepo.usersDataNotifiers.value[userID] != null){
                                      return ValueListenableBuilder(
                                        valueListenable: appStateRepo.usersDataNotifiers.value[userID]!.notifier,
                                        builder: ((context, userData, child) {
                                          return CustomProfileHeader(
                                            userID: userID, userData: userData, key: UniqueKey(),
                                            skeletonMode: false,
                                          );
                                        }),
                                      );
                                    }
                                    return loadingPageWidget();
                                  }else{
                                    return Center(
                                      child: Text('An error occured when fetching the user id', style: TextStyle(fontSize: defaultTextFontSize))
                                    );
                                  }
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
                              controller: controller.tabController,
                              indicatorColor: Colors.orange,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorWeight: 3.0,
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
                      controller: controller.tabController,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: controller.profilePostsWidgetUniqueKey, 
                          builder: (context, uniqueKey, child){
                            if(uniqueKey != null){
                              return ProfilePagePostsWidget(
                                userID: userID, 
                                key: uniqueKey, 
                                absorberContext: context
                              );
                            }
                            return Container();
                          }
                        ),
                        ValueListenableBuilder(
                          valueListenable: controller.profileRepliesWidgetUniqueKey, 
                          builder: (context, uniqueKey, child){
                            if(uniqueKey != null){
                              return ProfilePageRepliesWidget(
                                userID: userID, 
                                key: uniqueKey, 
                                absorberContext: context
                              );
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
              valueListenable: controller.displayFloatingBtn,
              builder: (BuildContext context, bool visible, Widget? child) {
                return Visibility(
                  visible: visible,
                  child: FloatingActionButton( 
                    heroTag: UniqueKey(),
                    onPressed: () {  
                      controller.scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 10),
                        curve: Curves.fastOutSlowIn
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
            leading: defaultLeadingWidget(context),
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
