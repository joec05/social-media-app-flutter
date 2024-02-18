import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class NotificationsWidget extends StatelessWidget {
  const NotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NotificationsWidgetStateful();
  }
}

class _NotificationsWidgetStateful extends StatefulWidget {
  const _NotificationsWidgetStateful();

  @override
  State<_NotificationsWidgetStateful> createState() => _NotificationsWidgetStatefulState();
}

class _NotificationsWidgetStatefulState extends State<_NotificationsWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin{
  late NotificationsController controller;

  @override
  void initState(){
    super.initState();
    controller = NotificationsController(context);
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
              ListView.builder(
                itemCount: notificationsPaginationLimit,
                itemBuilder: (context, index) {
                  return CustomNotificationWidget(
                    notificationClass: NotificationClass.getFakeData(), 
                    skeletonMode: true
                  );
                }
              )
            );
          }
          return ValueListenableBuilder(
            valueListenable: controller.paginationStatus,
            builder: (context, loadingStatusValue, child){
              return ValueListenableBuilder(
                valueListenable: controller.canPaginate,
                builder: (context, canPaginateValue, child){
                  return ValueListenableBuilder(
                    valueListenable: controller.notifications, 
                    builder: ((context, notifications, child) {
                      return LoadMoreBottom(
                        addBottomSpace: canPaginateValue,
                        loadMore: () async{
                          if(canPaginateValue){
                            await controller.loadMoreNotifications();
                          }
                        },
                        status: loadingStatusValue,
                        refresh: controller.refresh,
                        child: CustomScrollView(
                          controller: controller.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            SliverList(delegate: SliverChildBuilderDelegate(
                              childCount: notifications.length, 
                              (context, index) {
                                return CustomNotificationWidget(
                                  notificationClass: notifications[index], 
                                  skeletonMode: false,
                                  key: UniqueKey()
                                );
                              }
                            ))
                          ]
                        )
                      );
                    })
                  );
                }
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