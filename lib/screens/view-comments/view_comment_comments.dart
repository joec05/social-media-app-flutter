import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ViewCommentCommentsWidget extends StatelessWidget {
  final CommentClass selectedCommentData;

  const ViewCommentCommentsWidget({super.key, required this.selectedCommentData});

  @override
  Widget build(BuildContext context) {
    return ViewCommentCommentsWidgetStateful(selectedCommentData: selectedCommentData);
  }
}

class ViewCommentCommentsWidgetStateful extends StatefulWidget {
  final CommentClass selectedCommentData;
  const ViewCommentCommentsWidgetStateful({super.key, required this.selectedCommentData});

  @override
  State<ViewCommentCommentsWidgetStateful> createState() => _ViewCommentCommentsWidgetStatefulState();
}

class _ViewCommentCommentsWidgetStatefulState extends State<ViewCommentCommentsWidgetStateful> with LifecycleListenerMixin{
  late CommentCommentsController controller;

  @override
  void initState(){
    super.initState();
    controller = CommentCommentsController(
      context,
      widget.selectedCommentData
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
        title: const Text('View Comment'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: ListenableBuilder(
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
                    valueListenable: controller.parentPost, 
                    builder: ((context, parentPost, child) {
                      if(parentPost != null){
                        return parentPost is DisplayPostDataClass ?
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.postsNotifiers.value[parentPost.sender]![parentPost.postID]!.notifier,
                              appStateClass.usersDataNotifiers.value[parentPost.sender]!.notifier
                            ]),
                            builder: (context, child){
                              PostClass postData = appStateClass.postsNotifiers.value[parentPost.sender]![parentPost.postID]!.notifier.value;
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[parentPost.sender]!.notifier.value;
                              if(!postData.deleted){
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersSocialsNotifiers.value[parentPost.sender]!.notifier, 
                                  builder: ((context, userSocials, child) {
                                    return CustomPostWidget(
                                      postData: postData, 
                                      senderData: userData,
                                      senderSocials: userSocials,
                                      pageDisplayType: PostDisplayType.viewPost,
                                      key: UniqueKey(),
                                      skeletonMode: false,
                                    );
                                  })
                                );
                              }
                              return Container();
                            }
                          )
                        : parentPost is DisplayCommentDataClass ?
                          ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.commentsNotifiers.value[parentPost.sender]![parentPost.commentID]!.notifier,
                              appStateClass.usersDataNotifiers.value[parentPost.sender]!.notifier
                            ]),
                            builder: (context, child){
                              CommentClass commentData = appStateClass.commentsNotifiers.value[parentPost.sender]![parentPost.commentID]!.notifier.value;
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[parentPost.sender]!.notifier.value;
                              if(!commentData.deleted){
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersSocialsNotifiers.value[parentPost.sender]!.notifier, 
                                  builder: ((context, userSocials, child) {
                                    return CustomCommentWidget(
                                      commentData: commentData, 
                                      senderData: userData,
                                      senderSocials: userSocials,
                                      pageDisplayType: CommentDisplayType.viewComment,
                                      key: UniqueKey(),
                                      skeletonMode: false,
                                    );
                                  })
                                );
                              }
                              return Container(); 
                            }
                          )
                        : Container();
                      }else{
                        return shimmerSkeletonWidget(
                          CustomPostWidget(
                            postData: PostClass.getFakeData(),
                            senderData: UserDataClass.getFakeData(), 
                            senderSocials: UserSocialClass.getFakeData(), 
                            pageDisplayType: PostDisplayType.viewPost,
                            skeletonMode: true,
                            key: UniqueKey()
                          )
                        ); 
                      }
                    })
                  )
                ),
                SliverToBoxAdapter(
                  child: ValueListenableBuilder(
                    valueListenable: controller.selectedComment, 
                    builder: ((context, selectedComment, child) {
                      if(selectedComment != null){
                        return ListenableBuilder(
                          listenable: Listenable.merge([
                            appStateClass.commentsNotifiers.value[selectedComment.sender]![selectedComment.commentID]!.notifier,
                            appStateClass.usersDataNotifiers.value[selectedComment.sender]!.notifier
                          ]),
                          builder: (context, child){
                            CommentClass commentData = appStateClass.commentsNotifiers.value[selectedComment.sender]![selectedComment.commentID]!.notifier.value;
                            UserDataClass userData = appStateClass.usersDataNotifiers.value[selectedComment.sender]!.notifier.value;
                            if(!commentData.deleted){
                              return ValueListenableBuilder(
                                valueListenable: appStateClass.usersSocialsNotifiers.value[selectedComment.sender]!.notifier, 
                                builder: ((context, userSocials, child) {
                                  return CustomCommentWidget(
                                    commentData: commentData, 
                                    senderData: userData,
                                    senderSocials: userSocials,
                                    pageDisplayType: CommentDisplayType.viewComment,
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
                    }
                    return SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: commentsList.length, 
                      (context, index) {
                        if(appStateClass.commentsNotifiers.value[commentsList[index].sender] == null){
                          return Container();
                        }
                        if(appStateClass.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID] == null){
                          return Container();
                        }
                        return ListenableBuilder(
                          listenable: Listenable.merge([
                            appStateClass.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID]!.notifier,
                            appStateClass.usersDataNotifiers.value[commentsList[index].sender]!.notifier
                          ]),
                          builder: (context, child){
                            CommentClass commentData = appStateClass.commentsNotifiers.value[commentsList[index].sender]![commentsList[index].commentID]!.notifier.value;
                            UserDataClass userData = appStateClass.usersDataNotifiers.value[commentsList[index].sender]!.notifier.value;
                            if(!commentData.deleted){
                              return ValueListenableBuilder(
                                valueListenable: appStateClass.usersSocialsNotifiers.value[commentsList[index].sender]!.notifier, 
                                builder: ((context, userSocials, child) {
                                  return CustomCommentWidget(
                                    commentData: commentData, 
                                    senderData: userData,
                                    senderSocials: userSocials,
                                    pageDisplayType: CommentDisplayType.viewComment,
                                    skeletonMode: false,
                                    key: UniqueKey()
                                  );
                                })
                              );
                            }
                            return Container();    
                          }
                        );
                      })
                    );
                  }
                ))                                    
              ]
            )
          );
        }
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