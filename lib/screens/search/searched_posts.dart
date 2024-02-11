import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchedPostsWidget extends StatelessWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const SearchedPostsWidget({super.key, required this.searchedText, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _SearchedPostsWidgetStateful(searchedText: searchedText, absorberContext: absorberContext);
  }
}

class _SearchedPostsWidgetStateful extends StatefulWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const _SearchedPostsWidgetStateful({required this.searchedText, required this.absorberContext});

  @override
  State<_SearchedPostsWidgetStateful> createState() => _SearchedPostsWidgetStatefulState();
}

class _SearchedPostsWidgetStatefulState extends State<_SearchedPostsWidgetStateful> with AutomaticKeepAliveClientMixin{
  late SearchedPostsController controller;

  @override
  void initState(){
    super.initState();
    controller = SearchedPostsController(
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
                    childCount: postsPaginationLimit, 
                    (context, index) {
                      return CustomPostWidget(
                        postData: PostClass.getFakeData(),
                        senderData: UserDataClass.getFakeData(), 
                        senderSocials: UserSocialClass.getFakeData(), 
                        pageDisplayType: PostDisplayType.searchedPost,
                        skeletonMode: true,
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
              controller.totalPostsLength,
              controller.posts
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = controller.paginationStatus.value;
              int totalPostsLengthValue = controller.totalPostsLength.value;
              List<DisplayPostDataClass> postsList = controller.posts.value;
              return LoadMoreBottom(
                addBottomSpace: postsList.length < totalPostsLengthValue,
                loadMore: () async{
                  if(postsList.length < totalPostsLengthValue){
                    await controller.loadMorePosts();
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
                      childCount: postsList.length, 
                      (context, index) {
                        if(appStateClass.postsNotifiers.value[postsList[index].sender] == null){
                          return Container();
                        }
                        if(appStateClass.postsNotifiers.value[postsList[index].sender]![postsList[index].postID] == null){
                          return Container();
                        }
                        return ListenableBuilder(
                          listenable: Listenable.merge([
                            appStateClass.postsNotifiers.value[postsList[index].sender]![postsList[index].postID]!.notifier,
                            appStateClass.usersDataNotifiers.value[postsList[index].sender]!.notifier,
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
                                      pageDisplayType: PostDisplayType.searchedPost,
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
