import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class CommentLikesListWidget extends StatelessWidget {
  final String commentID;
  final String commentSender;
  const CommentLikesListWidget({super.key, required this.commentID, required this.commentSender});

  @override
  Widget build(BuildContext context) {
    return _CommentLikesListWidgetStateful(commentID: commentID, commentSender: commentSender);
  }
}

class _CommentLikesListWidgetStateful extends StatefulWidget {
  final String commentID;
  final String commentSender;
  const _CommentLikesListWidgetStateful({required this.commentID, required this.commentSender});

  @override
  State<_CommentLikesListWidgetStateful> createState() => _CommentLikesListWidgetStatefulState();
}

class _CommentLikesListWidgetStatefulState extends State<_CommentLikesListWidgetStateful> with LifecycleListenerMixin{
  late CommentLikesController controller;

  @override
  void initState(){
    super.initState();
    controller = CommentLikesController(
      context,
      widget.commentID
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
        title: const Text('Users'), 
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
                    userDisplayType: UserDisplayType.likes,
                    isLiked: false,
                    isBookmarked: null,
                    profilePageUserID: null,
                    key: UniqueKey(),
                    skeletonMode: true,
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
                        if(appStateRepo.usersDataNotifiers.value[usersList[index]] != null){
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier,
                              appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier,
                              appStateRepo.commentsNotifiers.value[widget.commentSender]![widget.commentID]!.notifier
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateRepo.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateRepo.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              CommentClass commentData = appStateRepo.commentsNotifiers.value[widget.commentSender]![widget.commentID]!.notifier.value;
                              return CustomUserDataWidget(
                                userData: userData,
                                userSocials: userSocial,
                                userDisplayType: UserDisplayType.likes,
                                isLiked: commentData.likedByCurrentID,
                                isBookmarked: null,
                                profilePageUserID: null,
                                key: UniqueKey(),
                                skeletonMode: false,
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
}