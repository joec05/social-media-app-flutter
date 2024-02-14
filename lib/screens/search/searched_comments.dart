import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchedCommentsWidget extends StatelessWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const SearchedCommentsWidget({super.key, required this.searchedText, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _SearchedCommentsWidgetStateful(searchedText: searchedText, absorberContext: absorberContext);
  }
}

class _SearchedCommentsWidgetStateful extends StatefulWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const _SearchedCommentsWidgetStateful({required this.searchedText, required this.absorberContext});

  @override
  State<_SearchedCommentsWidgetStateful> createState() => _SearchedCommentsWidgetStatefulState();
}

class _SearchedCommentsWidgetStatefulState extends State<_SearchedCommentsWidgetStateful> with AutomaticKeepAliveClientMixin{
  late SearchedCommentsController controller;

  @override
  void initState(){
    super.initState();
    controller = SearchedCommentsController(
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
                      return CustomCommentWidget(
                        commentData: CommentClass.getFakeData(), 
                        senderData: UserDataClass.getFakeData(),
                        senderSocials: UserSocialClass.getFakeData(),
                        pageDisplayType: CommentDisplayType.searchedComment,
                        key: UniqueKey(),
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
              controller.totalCommentsLength,
              controller.comments
            ]),
            builder: (context, child){
              PaginationStatus loadingStatusValue = controller.paginationStatus.value;
              int totalCommentsLengthValue = controller.totalCommentsLength.value;
              List<DisplayCommentDataClass> commentsList = controller.comments.value;
              return LoadMoreBottom(
                addBottomSpace: commentsList.length < totalCommentsLengthValue,
                loadMore: () async{
                  if(commentsList.length < totalCommentsLengthValue){
                    await controller.loadMoreComments();
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
                            appStateRepo.usersDataNotifiers.value[commentsList[index].sender]!.notifier, 
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
                                    pageDisplayType: CommentDisplayType.searchedComment,
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
