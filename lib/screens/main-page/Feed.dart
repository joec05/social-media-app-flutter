import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FeedWidget extends StatelessWidget {
  const FeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeedWidgetStateful();
  }
}

class _FeedWidgetStateful extends StatefulWidget {
  const _FeedWidgetStateful();

  @override
  State<_FeedWidgetStateful> createState() => __FeedWidgetStatefulState();
}

class __FeedWidgetStatefulState extends State<_FeedWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin{
  late FeedController controller;

  @override
  void initState(){
    super.initState();
    controller = FeedController(context);
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
              ListView.builder(
                itemCount: postsPaginationLimit,
                itemBuilder: (context, index) {
                  return CustomPostWidget(
                    postData: PostClass.getFakeData(), 
                    senderData: UserDataClass.getFakeData(),
                    senderSocials: UserSocialClass.getFakeData(),
                    pageDisplayType: PostDisplayType.feed,
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
              controller.totalPostsLength,
              controller.posts,
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = controller.paginationStatus.value;
              int totalPostsLengthValue = controller.totalPostsLength.value;
              List postsList = controller.posts.value;
              return LoadMoreBottom(
                addBottomSpace: true,
                loadMore: () async{
                  if(totalPostsLengthValue > postsList.length){
                    await controller.loadMorePosts();
                  }
                },
                status: loadingStatusValue,
                refresh: controller.refresh,
                child: CustomScrollView(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: postsList.length, 
                      (context, index) {
                        if(postsList[index] is DisplayPostDataClass){
                          if(appStateClass.postsNotifiers.value[postsList[index].sender] == null){
                            return Container();
                          }
                          if(appStateClass.postsNotifiers.value[postsList[index].sender]![postsList[index].postID] == null){
                            return Container();
                          }
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.postsNotifiers.value[postsList[index].sender]![postsList[index].postID]!.notifier,
                              appStateClass.usersDataNotifiers.value[postsList[index].sender]!.notifier
                            ]),
                            builder: (context, child){
                              PostClass postData = appStateClass.postsNotifiers.value[postsList[index].sender]![postsList[index].postID]!.notifier.value;
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[postsList[index].sender]!.notifier.value;
                              if(!postData.deleted){
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersSocialsNotifiers.value[postsList[index].sender]!.notifier, 
                                  builder: ((context, userSocials, child) {
                                    return CustomPostWidget(
                                      postData: postData, 
                                      senderData: userData,
                                      senderSocials: userSocials,
                                      pageDisplayType: PostDisplayType.feed,
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
                          if(appStateClass.commentsNotifiers.value[postsList[index].sender] == null){
                            return Container();
                          }
                          if(appStateClass.commentsNotifiers.value[postsList[index].sender]![postsList[index].commentID] == null){
                            return Container();
                          }
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.commentsNotifiers.value[postsList[index].sender]![postsList[index].commentID]!.notifier,
                              appStateClass.usersDataNotifiers.value[postsList[index].sender]!.notifier
                            ]),
                            builder: (context, child){
                              CommentClass commentData = appStateClass.commentsNotifiers.value[postsList[index].sender]![postsList[index].commentID]!.notifier.value;
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[postsList[index].sender]!.notifier.value;
                              if(!commentData.deleted){
                                return ValueListenableBuilder(
                                  valueListenable: appStateClass.usersSocialsNotifiers.value[postsList[index].sender]!.notifier, 
                                  builder: ((context, userSocials, child) {
                                    return CustomCommentWidget(
                                      commentData: commentData, 
                                      senderData: userData,
                                      senderSocials: userSocials,
                                      pageDisplayType: CommentDisplayType.feed,
                                      skeletonMode: false,
                                      key: UniqueKey()
                                    );
                                  })
                                );
                              }
                              return Container();
                            }
                          );
                        }
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
