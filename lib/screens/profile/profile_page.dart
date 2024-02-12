import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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

class _ProfilePageWidgetStatefulState extends State<_ProfilePageWidgetStateful> with SingleTickerProviderStateMixin, LifecycleListenerMixin{
  late String userID;
  late ProfileController controller;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    controller = ProfileController(
      context,
      userID,
      TabController(length: 2, vsync: this)
    );
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
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
      body: RefreshIndicator(
        color: Colors.blue,
        notificationPredicate: (notification) {
          return true;
        },
        onRefresh: controller.fetchProfileData,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller.scrollController,
          headerSliverBuilder: (context, bool f) {
            return <Widget>[
              SliverToBoxAdapter(
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: controller.isLoading,
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
                    controller: controller.tabController,
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
