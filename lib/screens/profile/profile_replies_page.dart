import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfilePageRepliesWidget extends StatelessWidget {
  final String userID;
  final BuildContext absorberContext;
  const ProfilePageRepliesWidget({super.key, required this.userID, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageRepliesWidgetStateful(userID: userID, absorberContext: absorberContext);
  }
}

class _ProfilePageRepliesWidgetStateful extends StatefulWidget {
  final String userID;
  final BuildContext absorberContext;
  const _ProfilePageRepliesWidgetStateful({required this.userID, required this.absorberContext});

  @override
  State<_ProfilePageRepliesWidgetStateful> createState() => _ProfilePageRepliesWidgetStatefulState();
}

class _ProfilePageRepliesWidgetStatefulState extends State<_ProfilePageRepliesWidgetStateful> with AutomaticKeepAliveClientMixin{
  late String userID;
  late ProfileRepliesController controller;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    controller = ProfileRepliesController(
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
                      return CustomCommentWidget(
                        commentData: CommentClass.getFakeData(), 
                        senderData: UserDataClass.getFakeData(),
                        senderSocials: UserSocialClass.getFakeData(),
                        pageDisplayType: CommentDisplayType.profileComment,
                        key: UniqueKey(),
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
                            controller.comments
                          ]),
                          builder: (context, child){
                            bool canPaginateValue = controller.canPaginate.value;
                            List<DisplayCommentDataClass> commentsList = controller.comments.value;
                            return LoadMoreBottom(
                              addBottomSpace: canPaginateValue,
                              loadMore: () async{
                                if(canPaginateValue){
                                  await controller.loadMoreComments();
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
                                    childCount: commentsList.length, 
                                    (context, index) {
                                      if(appStateRepo.commentsNotifiers.value[commentsList[index].sender] == null){
                                        return Container();
                                      }
                                      if(appStateRepo.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID] == null){
                                        return Container();
                                      }
                                      return ListenableBuilder(
                                        listenable: Listenable.merge([
                                          appStateRepo.usersDataNotifiers.value[commentsList[index].sender]!.notifier,
                                          appStateRepo.usersSocialsNotifiers.value[commentsList[index].sender]!.notifier
                                        ]),
                                        builder: (context, child){
                                          CommentClass commentData = appStateRepo.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID]!.notifier.value;
                                          UserDataClass userData = appStateRepo.usersDataNotifiers.value[commentsList[index].sender]!.notifier.value;
                                          if(!commentData.deleted){
                                            if(userData.blocksCurrentID){
                                              return Container();
                                            }
                                            return ValueListenableBuilder(
                                              valueListenable: appStateRepo.usersSocialsNotifiers.value[commentsList[index].sender]!.notifier, 
                                              builder: ((context, userSocials, child) {
                                                if(userData.private && !userSocials.followedByCurrentID && userData.userID != appStateRepo.currentID){
                                                  return Container();
                                                }
                                                return CustomCommentWidget(
                                                  commentData: commentData, 
                                                  senderData: userData,
                                                  senderSocials: userSocials,
                                                  pageDisplayType: CommentDisplayType.profileComment,
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
                          }
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
