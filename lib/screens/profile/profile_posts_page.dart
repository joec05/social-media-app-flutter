import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfilePagePostsWidget extends StatelessWidget {
  final String userID;
  final BuildContext absorberContext;
  const ProfilePagePostsWidget({super.key, required this.userID, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _ProfilePagePostsWidgetStateful(userID: userID, absorberContext: absorberContext);
  }
}

class _ProfilePagePostsWidgetStateful extends StatefulWidget {
  final String userID;
  final BuildContext absorberContext;
  const _ProfilePagePostsWidgetStateful({required this.userID, required this.absorberContext});

  @override
  State<_ProfilePagePostsWidgetStateful> createState() => _ProfilePagePostsWidgetStatefulState();
}

class _ProfilePagePostsWidgetStatefulState extends State<_ProfilePagePostsWidgetStateful> with AutomaticKeepAliveClientMixin{
  late String userID;
  late ProfilePostsController controller;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    controller = ProfilePostsController(
      context,
      userID
    );
    controller.initializeController();
  }

  @override void dispose() async{
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
                    childCount: postsPaginationLimit, 
                    (context, index) {
                      return CustomPostWidget(
                        postData: PostClass.getFakeData(),
                        senderData: UserDataClass.getFakeData(), 
                        senderSocials: UserSocialClass.getFakeData(), 
                        pageDisplayType: PostDisplayType.profilePost,
                        skeletonMode: true,
                      );
                    }
                  ))
                ]
              )
            ); 
          }
          return ValueListenableBuilder(
            valueListenable: controller.paginationStatus,
            builder: (context, loadingStatusValue, child){
              if(appStateRepo.usersDataNotifiers.value[userID] != null){
                return ValueListenableBuilder(
                  valueListenable: appStateRepo.usersDataNotifiers.value[userID]!.notifier, 
                  builder: ((context, profilePageUserData, child) {
                    if(profilePageUserData.blocksCurrentID){
                      return Container();
                    }
                    return ValueListenableBuilder(
                      valueListenable: appStateRepo.usersSocialsNotifiers.value[userID]!.notifier, 
                      builder: ((context, profilePageUserSocials, child) {
                        if(profilePageUserData.private && !profilePageUserSocials.followedByCurrentID && userID != appStateRepo.currentID){
                          return Container();
                        }
                        return ListenableBuilder(
                          listenable: Listenable.merge([
                            controller.canPaginate,
                            controller.posts
                          ]),
                          builder: (context, child){
                            bool canPaginateValue = controller.canPaginate.value;
                            List<DisplayPostDataClass> postsList = controller.posts.value;
                            return LoadMoreBottom(
                              addBottomSpace: canPaginateValue,
                              loadMore: () async{
                                if(canPaginateValue){
                                  await controller.loadMorePosts();
                                }
                              },
                              status: loadingStatusValue,
                              refresh: null,
                              child: CustomScrollView(
                                controller: controller.scrollController,
                                primary: false,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: <Widget>[
                                  SliverOverlapInjector(
                                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                                  ),
                                  SliverList(delegate: SliverChildBuilderDelegate(
                                    addAutomaticKeepAlives: true,
                                    childCount: postsList.length, 
                                    (context, index) {
                                      if(appStateRepo.postsNotifiers.value[postsList[index].sender] == null){
                                        return Container();
                                      }
                                      if(appStateRepo.postsNotifiers.value[postsList[index].sender]![postsList[index].postID] == null){
                                        return Container();
                                      }
                                      return ListenableBuilder(
                                        listenable: Listenable.merge([
                                          appStateRepo.postsNotifiers.value[postsList[index].sender]![postsList[index].postID]!.notifier,
                                          appStateRepo.usersDataNotifiers.value[postsList[index].sender]!.notifier
                                        ]),
                                        builder: (context, child){
                                          PostClass postData = appStateRepo.postsNotifiers.value[postsList[index].sender]![postsList[index].postID]!.notifier.value;
                                          UserDataClass userData = appStateRepo.usersDataNotifiers.value[postsList[index].sender]!.notifier.value;
                                          if(!postData.deleted){
                                            if(userData.blocksCurrentID){
                                              return Container();
                                            }
                                            return ValueListenableBuilder(
                                              valueListenable: appStateRepo.usersSocialsNotifiers.value[postsList[index].sender]!.notifier, 
                                              builder: ((context, userSocials, child) { 
                                                if(userData.private && !userSocials.followedByCurrentID && userData.userID != appStateRepo.currentID){
                                                  return Container();
                                                }
                                                return CustomPostWidget(
                                                  postData: postData, 
                                                  senderData: userData,
                                                  senderSocials: userSocials,
                                                  pageDisplayType: PostDisplayType.profilePost,
                                                  key: UniqueKey(),
                                                  skeletonMode: false,
                                                );
                                              })
                                            );
                                          }
                                          return Container();
                                        }
                                      );
                                    }
                                  ))                                    
                                ]
                              )
                            );
                          },
                        );
                      })
                    );
                  })
                );
              }
              return Container();
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
