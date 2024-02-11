import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class CommentBookmarksListWidget extends StatelessWidget {
  final String commentID;
  final String commentSender;
  const CommentBookmarksListWidget({super.key, required this.commentID, required this.commentSender});

  @override
  Widget build(BuildContext context) {
    return _CommentBookmarksListWidgetStateful(commentID: commentID, commentSender: commentSender);
  }
}

class _CommentBookmarksListWidgetStateful extends StatefulWidget {
  final String commentID;
  final String commentSender;
  const _CommentBookmarksListWidgetStateful({required this.commentID, required this.commentSender});

  @override
  State<_CommentBookmarksListWidgetStateful> createState() => _CommentBookmarksListWidgetStatefulState();
}

class _CommentBookmarksListWidgetStatefulState extends State<_CommentBookmarksListWidgetStateful> with LifecycleListenerMixin{
  late CommentBookmarksController controller;

  @override
  void initState(){
    super.initState();
    controller = CommentBookmarksController(
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
                    userDisplayType: UserDisplayType.bookmarks,
                    isLiked: null,
                    isBookmarked: false,
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
                        if(appStateClass.usersDataNotifiers.value[usersList[index]] != null){
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier,
                              appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier,
                              appStateClass.commentsNotifiers.value[widget.commentSender]![widget.commentID]!.notifier
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              CommentClass commentData = appStateClass.commentsNotifiers.value[widget.commentSender]![widget.commentID]!.notifier.value;
                              return CustomUserDataWidget(
                                userData: userData,
                                userSocials: userSocial,
                                userDisplayType: UserDisplayType.bookmarks,
                                isLiked: null,
                                isBookmarked: commentData.bookmarkedByCurrentID,
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