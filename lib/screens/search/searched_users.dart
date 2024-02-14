import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchedUsersWidget extends StatelessWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const SearchedUsersWidget({super.key, required this.searchedText, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _SearchedUsersWidgetStateful(searchedText: searchedText, absorberContext: absorberContext);
  }
}

class _SearchedUsersWidgetStateful extends StatefulWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const _SearchedUsersWidgetStateful({required this.searchedText, required this.absorberContext});

  @override
  State<_SearchedUsersWidgetStateful> createState() => _SearchedUsersWidgetStatefulState();
}

class _SearchedUsersWidgetStatefulState extends State<_SearchedUsersWidgetStateful> with AutomaticKeepAliveClientMixin{
  late SearchedUsersController controller;
  
  @override
  void initState(){
    super.initState();
    controller = SearchedUsersController(
      context, 
      widget.searchedText
    );
    controller.initializeController();
  }

  @override void dispose(){
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
     return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: controller.loadingState,
        builder: ((context, loadingStateValue, child) {
          if(shouldCallSkeleton(loadingStateValue)){
            return shimmerSkeletonWidget(
              CustomScrollView(
                controller: controller.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                  ),
                  SliverList(delegate: SliverChildBuilderDelegate(
                    childCount: usersPaginationLimit, 
                    (context, index) {
                      return CustomUserDataWidget(
                        userData: UserDataClass.getFakeData(), 
                        userSocials: UserSocialClass.getFakeData(), 
                        userDisplayType: UserDisplayType.searchedUsers,
                        profilePageUserID: null,
                        isLiked: null,
                        isBookmarked: null,
                        skeletonMode: true,
                        key: UniqueKey()
                      );
                    }
                  ))
                ]
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
                refresh: controller.refresh,
                child: CustomScrollView(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                    ),
                    SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: usersList.length, 
                      (context, index) {
                        if(appStateRepo.usersDataNotifiers.value[usersList[index]] != null){
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier,
                              appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier,
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              return CustomUserDataWidget(
                                userData: userData,
                                userSocials: userSocial,
                                userDisplayType: UserDisplayType.searchedUsers,
                                profilePageUserID: null,
                                isLiked: null,
                                isBookmarked: null,
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
  
  @override
  bool get wantKeepAlive => true;
}