import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

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

class _GroupMembersPageStatefulState extends State<_GroupMembersPageStateful> with LifecycleListenerMixin{
  late GroupMembersController controller;

  @override
  void initState(){
    super.initState();
    controller = GroupMembersController(
      context, 
      widget.usersID
    );
    controller.initializeController();
  }

  @override
  void dispose(){
    super.dispose();
    controller.dispose();
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
                    userDisplayType: UserDisplayType.groupMembers,
                    profilePageUserID: null,
                    isLiked: null,
                    isBookmarked: null,
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
              controller.totalUsersLength,
              controller.users
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = controller.paginationStatus.value;
              List<String> usersList = controller.users.value;
              return LoadMoreBottom(
                addBottomSpace: usersList.length < controller.totalUsersLength.value,
                loadMore: () async{
                  if(usersList.length < controller.totalUsersLength.value){
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
                        if(appStateRepo.usersDataNotifiers.value[usersList[index]] != null){
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier,
                              appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              return CustomUserDataWidget(
                                userData: userData,
                                userSocials: userSocial,
                                userDisplayType: UserDisplayType.groupMembers,
                                isLiked: null,
                                isBookmarked: null,
                                profilePageUserID: null,
                                skeletonMode: false,
                                key: UniqueKey()
                              );
                            }
                          );
                        }
                        return Container();                                                
                      }
                    ))                                    
                  ]
                )
              );
            },
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