import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FollowRequestsFromWidget extends StatelessWidget {
  final BuildContext absorberContext;
  const FollowRequestsFromWidget({super.key, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _FollowRequestsFromWidgetStateful(absorberContext: absorberContext);
  }
}

class _FollowRequestsFromWidgetStateful extends StatefulWidget {
  final BuildContext absorberContext;
  const _FollowRequestsFromWidgetStateful({required this.absorberContext});

  @override
  State<_FollowRequestsFromWidgetStateful> createState() => _FollowRequestsFromWidgetStatefulState();
}

class _FollowRequestsFromWidgetStatefulState extends State<_FollowRequestsFromWidgetStateful> with AutomaticKeepAliveClientMixin{
  late FollowRequestFromController controller;

  @override
  void initState(){
    super.initState();
    controller = FollowRequestFromController(context);
    controller.initializeController();
  }

  @override
  void dispose(){
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
                    childCount: followRequestsPaginationLimit, 
                    (context, index) {
                      return CustomFollowRequestWidget(
                        userData: UserDataClass.getFakeData(), 
                        userSocials: UserSocialClass.getFakeData(), 
                        followRequestType: FollowRequestType.from,
                        skeletonMode: true,
                        key: UniqueKey()
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
                refresh: controller.refresh,
                child: CustomScrollView(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                    ),
                    SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: usersList.length, 
                      (context, index) {
                        if(appStateClass.usersDataNotifiers.value[usersList[index]] != null){
                          return ListenableBuilder(
                            listenable: Listenable.merge([
                              appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier,
                              appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier
                            ]),
                            builder: (context, child){
                              UserDataClass userData = appStateClass.usersDataNotifiers.value[usersList[index]]!.notifier.value;
                              UserSocialClass userSocial = appStateClass.usersSocialsNotifiers.value[usersList[index]]!.notifier.value;
                              return CustomFollowRequestWidget(
                                userData: userData, userSocials: userSocial,
                                key: UniqueKey(), followRequestType: FollowRequestType.from,
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
  
  @override
  bool get wantKeepAlive => true;
}