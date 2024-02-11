import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class PostLikesListWidget extends StatelessWidget {
  final String postID;
  final String postSender;
  const PostLikesListWidget({super.key, required this.postID, required this.postSender});

  @override
  Widget build(BuildContext context) {
    return _PostLikesListWidgetStateful(postID: postID, postSender: postSender);
  }
}

class _PostLikesListWidgetStateful extends StatefulWidget {
  final String postID;
  final String postSender;
  const _PostLikesListWidgetStateful({required this.postID, required this.postSender});

  @override
  State<_PostLikesListWidgetStateful> createState() => _PostLikesListWidgetStatefulState();
}

class _PostLikesListWidgetStatefulState extends State<_PostLikesListWidgetStateful> with LifecycleListenerMixin{
  late PostLikesController controller;

  @override
  void initState(){
    super.initState();
    controller = PostLikesController(
      context,
      widget.postID
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
                    isLiked: null,
                    isBookmarked: null,
                    profilePageUserID: null,
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
                  if(controller.canPaginate.value){
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
                              appStateClass.postsNotifiers.value[widget.postSender]![widget.postID]!.notifier
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              PostClass postData = appStateClass.postsNotifiers.value[widget.postSender]![widget.postID]!.notifier.value;
                              return CustomUserDataWidget(
                                userData: userData,
                                userSocials: userSocial,
                                userDisplayType: UserDisplayType.likes,
                                profilePageUserID: null,
                                isLiked: postData.likedByCurrentID,
                                isBookmarked: null,
                                skeletonMode: false,
                                key: UniqueKey()
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