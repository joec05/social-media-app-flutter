import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfilePageBookmarksWidget extends StatelessWidget {
  final String userID;
  const ProfilePageBookmarksWidget({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageBookmarksWidgetStateful(userID: userID);
  }
}

class _ProfilePageBookmarksWidgetStateful extends StatefulWidget {
  final String userID;
  const _ProfilePageBookmarksWidgetStateful({required this.userID});

  @override
  State<_ProfilePageBookmarksWidgetStateful> createState() => _ProfilePageBookmarksWidgetStatefulState();
}

class _ProfilePageBookmarksWidgetStatefulState extends State<_ProfilePageBookmarksWidgetStateful>{
  late String userID;
  late ProfileBookmarksController controller;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    controller = ProfileBookmarksController(
      context, 
      userID
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
        title: const Text('Bookmarks'), 
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
                itemCount: postsPaginationLimit,
                itemBuilder: (context, index){
                  return CustomPostWidget(
                    postData: PostClass.getFakeData(),
                    senderData: UserDataClass.getFakeData(), 
                    senderSocials: UserSocialClass.getFakeData(), 
                    pageDisplayType: PostDisplayType.bookmark,
                    skeletonMode: true,
                  );
                }
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
                            List postsList = controller.posts.value;
                            return LoadMoreBottom(
                              addBottomSpace: canPaginateValue,
                              loadMore: () async{
                                if(canPaginateValue){
                                  await controller.loadMoreBookmarks();
                                }
                              },
                              status: loadingStatusValue,
                              refresh: null,
                              child: CustomScrollView(
                                controller: controller.scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: <Widget>[
                                  SliverList(delegate: SliverChildBuilderDelegate(
                                    childCount: postsList.length, 
                                    (context, index) {
                                      if(postsList[index] is DisplayPostDataClass){
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
                                              return ValueListenableBuilder(
                                                valueListenable: appStateRepo.usersSocialsNotifiers.value[postsList[index].sender]!.notifier, 
                                                builder: ((context, userSocials, child) {
                                                  return CustomPostWidget(
                                                    postData: postData, 
                                                    senderData: userData,
                                                    senderSocials: userSocials,
                                                    pageDisplayType: PostDisplayType.bookmark,
                                                    key: UniqueKey(),
                                                    skeletonMode: false,
                                                  );
                                                })
                                              );
                                            }
                                            return Container();
                                          }
                                        );
                                      }else{
                                        if(appStateRepo.commentsNotifiers.value[postsList[index].sender] == null){
                                          return Container();
                                        }
                                        if(appStateRepo.commentsNotifiers.value[postsList[index].sender]![postsList[index].commentID] == null){
                                          return Container();
                                        }
                                        ListenableBuilder(
                                          listenable: Listenable.merge([
                                            appStateRepo.commentsNotifiers.value[postsList[index].sender]![postsList[index].commentID]!.notifier,
                                            appStateRepo.usersDataNotifiers.value[postsList[index].sender]!.notifier
                                          ]),
                                          builder: (context, child){
                                            CommentClass commentData = appStateRepo.commentsNotifiers.value[postsList[index].sender]![postsList[index].commentID]!.notifier.value;
                                            UserDataClass userData = appStateRepo.usersDataNotifiers.value[postsList[index].sender]!.notifier.value;
                                            if(!commentData.deleted){
                                              return ValueListenableBuilder(
                                                valueListenable: appStateRepo.usersSocialsNotifiers.value[postsList[index].sender]!.notifier, 
                                                builder: ((context, userSocials, child) {
                                                  return CustomCommentWidget(
                                                    commentData: commentData, 
                                                    senderData: userData,
                                                    senderSocials: userSocials,
                                                    pageDisplayType: CommentDisplayType.bookmark,
                                                    key: UniqueKey(),
                                                    skeletonMode: false,
                                                  );
                                                })
                                              );
                                            }
                                            return Container();
                                          },
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
}
