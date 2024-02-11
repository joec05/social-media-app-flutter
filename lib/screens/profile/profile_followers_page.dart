import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfilePageFollowersWidget extends StatelessWidget {
  final String userID;
  const ProfilePageFollowersWidget({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageFollowersWidgetStateful(userID: userID);
  }
}

class _ProfilePageFollowersWidgetStateful extends StatefulWidget {
  final String userID;
  const _ProfilePageFollowersWidgetStateful({required this.userID});

  @override
  State<_ProfilePageFollowersWidgetStateful> createState() => _ProfilePageFollowersWidgetStatefulState();
}

class _ProfilePageFollowersWidgetStatefulState extends State<_ProfilePageFollowersWidgetStateful> with LifecycleListenerMixin{
  late ProfileFollowersController controller;

  @override
  void initState(){
    super.initState();
    controller = ProfileFollowersController(
      context,
      widget.userID
    );
    controller.initializeController();
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
        title: const Text('Followers'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: ValueListenableBuilder(
        valueListenable: controller.loadingState,
        builder: ((context, loadingStateValue, child) {
          if(shouldCallSkeleton(loadingStateValue)){
            return shimmerSkeletonWidget(
              ListView.builder(
                itemCount: usersPaginationLimit,
                itemBuilder: (context, index) {
                  return CustomUserDataWidget(
                    userData: UserDataClass.getFakeData(), 
                    userSocials: UserSocialClass.getFakeData(), 
                    userDisplayType: UserDisplayType.followers,
                    isLiked: null,
                    isBookmarked: null,
                    profilePageUserID: null,
                    skeletonMode: true,
                    key: UniqueKey()
                  );
                }
              )
            ); 
          }
          return ListenableBuilder(
            listenable: Listenable.merge([
              controller.paginationStatus,
              controller.canPaginate,
              controller.users
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = controller.paginationStatus.value;
              bool canPaginateValue = controller.canPaginate.value;
              List<String> usersList = controller.users.value;
              return LoadMoreBottom(
                addBottomSpace: canPaginateValue,
                loadMore: () async{
                  if(canPaginateValue){
                    await controller.loadMoreUsers();
                  }
                },
                status: loadingStatusValue,
                refresh: null,
                child: CustomScrollView(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: usersList.length, 
                      (context, index) {
                        if(appStateClass.usersDataNotifiers.value[usersList[index]] != null){
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier,
                              appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              return CustomUserDataWidget(
                                userData: userData,
                                userSocials: userSocial,
                                userDisplayType: UserDisplayType.followers,
                                isLiked: null,
                                isBookmarked: null,
                                profilePageUserID: widget.userID,
                                skeletonMode: false,
                                key: UniqueKey()
                              );
                            },
                          );
                        }
                        return Container();                                                
                      }
                    ))                                    
                  ]
                )
              );
            }
          );
        })
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