import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ViewPostCommentsWidget extends StatelessWidget {
  final PostClass selectedPostData;

  const ViewPostCommentsWidget({super.key, required this.selectedPostData});

  @override
  Widget build(BuildContext context) {
    return ViewPostCommentsWidgetStateful(selectedPostData: selectedPostData);
  }
}

class ViewPostCommentsWidgetStateful extends StatefulWidget {
  final PostClass selectedPostData;
  const ViewPostCommentsWidgetStateful({super.key, required this.selectedPostData});

  @override
  State<ViewPostCommentsWidgetStateful> createState() => _ViewPostCommentsWidgetStatefulState();
}

class _ViewPostCommentsWidgetStatefulState extends State<ViewPostCommentsWidgetStateful> with LifecycleListenerMixin{
  late PostCommentsController controller;

  @override
  void initState(){
    super.initState();
    controller = PostCommentsController(
      context, 
      widget.selectedPostData
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
        title: const Text('View Post'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Builder(
              builder: (BuildContext context) {
                return ListenableBuilder(
                  listenable: Listenable.merge([
                    controller.paginationStatus,
                    controller.canPaginate,
                    controller.comments
                  ]),
                  builder: (context, child){
                    PaginationStatus loadingStatusValue = controller.paginationStatus.value;
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: <Widget>[
                          SliverToBoxAdapter(
                            child: ValueListenableBuilder(
                              valueListenable: controller.selectedPost, 
                              builder: ((context, selectedPost, child) {
                                if(selectedPost != null){
                                  return ListenableBuilder(
                                    listenable: Listenable.merge([
                                      appStateRepo.postsNotifiers.value[selectedPost.sender]![selectedPost.postID]!.notifier,
                                      appStateRepo.usersDataNotifiers.value[selectedPost.sender]!.notifier
                                    ]),
                                    builder: (context, child){
                                      PostClass postData = appStateRepo.postsNotifiers.value[selectedPost.sender]![selectedPost.postID]!.notifier.value;
                                      UserDataClass userData = appStateRepo.usersDataNotifiers.value[selectedPost.sender]!.notifier.value;
                                      if(!postData.deleted){
                                        return ValueListenableBuilder(
                                          valueListenable: appStateRepo.usersSocialsNotifiers.value[selectedPost.sender]!.notifier, 
                                          builder: ((context, userSocials, child) {
                                            return CustomPostWidget(
                                              postData: postData, 
                                              senderData: userData,
                                              senderSocials: userSocials,
                                              pageDisplayType: PostDisplayType.viewPost,
                                              skeletonMode: false,
                                              key: UniqueKey()
                                            );
                                          })
                                        );
                                      }
                                      return Container();
                                    }
                                  );
                                }else{
                                  return shimmerSkeletonWidget(
                                    CustomPostWidget(
                                      postData: PostClass.getFakeData(),
                                      senderData: UserDataClass.getFakeData(), 
                                      senderSocials: UserSocialClass.getFakeData(), 
                                      pageDisplayType: PostDisplayType.viewPost,
                                      skeletonMode: true,
                                    )
                                  );
                                }
                              })
                            )
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: defaultVerticalPadding / 2),
                                Divider(color: Colors.grey, height: getScreenHeight() * 0.005),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
                                  child: const Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                ),
                              ]
                            )
                          ),
                          ValueListenableBuilder(
                            valueListenable: controller.loadingState,
                            builder: ((context, loadingStateValue, child) {
                              if(shouldCallSkeleton(loadingStateValue)){
                                return SliverList(delegate: SliverChildBuilderDelegate(
                                  childCount: postsPaginationLimit, 
                                  (context, index) {
                                    return shimmerSkeletonWidget(
                                      CustomCommentWidget(
                                        commentData: CommentClass.getFakeData(), 
                                        senderData: UserDataClass.getFakeData(),
                                        senderSocials: UserSocialClass.getFakeData(),
                                        pageDisplayType: CommentDisplayType.viewComment,
                                        key: UniqueKey(),
                                        skeletonMode: true,
                                      )
                                    );
                                  },
                                ));
                              }else{
                                return SliverList(delegate: SliverChildBuilderDelegate(
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
                                        appStateRepo.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID]!.notifier,
                                        appStateRepo.usersDataNotifiers.value[commentsList[index].sender]!.notifier
                                      ]),
                                      builder: (context, child){
                                        CommentClass commentData = appStateRepo.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID]!.notifier.value;
                                        UserDataClass userData = appStateRepo.usersDataNotifiers.value[commentsList[index].sender]!.notifier.value;
                                        if(!commentData.deleted){
                                          return ValueListenableBuilder(
                                            valueListenable: appStateRepo.usersSocialsNotifiers.value[commentsList[index].sender]!.notifier, 
                                            builder: ((context, userSocials, child) {
                                              return CustomCommentWidget(
                                                commentData: commentData, 
                                                senderData: userData,
                                                senderSocials: userSocials,
                                                pageDisplayType: CommentDisplayType.viewComment,
                                                key: UniqueKey(),
                                                skeletonMode: false
                                              );
                                            })
                                          );
                                        }
                                        return Container();
                                      }
                                    );
                                  }
                                ));
                              }
                            })
                          ),                                  
                        ]
                      )
                    );
                  }
                );
              }
            )
          ),
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