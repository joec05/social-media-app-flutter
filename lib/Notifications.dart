import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/NotificationClass.dart';
import 'package:social_media_app/custom/CustomNotificationWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/streams/NotificationDataStreamClass.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'custom/CustomPagination.dart';

var dio = Dio();

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
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<NotificationClass>> notifications = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingNotificationsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription notificationDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchNotificationsData(notifications.value.length, false, false), actionDelayTime);
    notificationDataStreamClassSubscription = NotificationDataStreamClass().notificationDataStream.listen((NotificationDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == 'delete_content_notifications'){
          NotificationClass deletedNotif = data.notificationClass;
          List<NotificationClass> notificationsList = [...notifications.value];
          for(int i = 0; i < notificationsList.length; i++){
            NotificationClass notif = notificationsList[i];
            if(notif.referencedPostType == deletedNotif.referencedPostType && notif.referencedPostID == deletedNotif.referencedPostID){
              notificationsList[i].postDeleted = true;
            }
          }
          notifications.value = [...notificationsList];
        }else if(data.uniqueID == 'blacklist_user_notifications'){
          NotificationClass blacklistedUserClass = data.notificationClass;
          List<NotificationClass> notificationsList = [...notifications.value];
          for(int i = notificationsList.length - 1; i >= 0 ; i--){
            NotificationClass notif = notificationsList[i];
            if(notif.sender == blacklistedUserClass.sender){
              notificationsList.removeAt(i);
            }
          }
          notifications.value = [...notificationsList];
        }
      }
    });
    _scrollController.addListener(() {
      if(mounted){
        if(_scrollController.position.pixels > animateToTopMinHeight){
          if(!displayFloatingBtn.value){
            displayFloatingBtn.value = true;
          }
        }else{
          if(displayFloatingBtn.value){
            displayFloatingBtn.value = false;
          }
        }
      }
    });
  }

  @override
  void dispose(){
    notificationDataStreamClassSubscription.cancel();
    super.dispose();
    isLoading.dispose();
    notifications.dispose();
    loadingNotificationsStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchNotificationsData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'currentID': appStateClass.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': notificationsServerFetchLimit
        }); 
        var res = await dio.get('$serverDomainAddress/users/fetchUserNotifications', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List userNotificationsData = res.data['userNotificationsData'];
            if(isRefreshing && mounted){
              notifications.value = [];
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
            for(int i = 0; i < userNotificationsData.length; i++){
              Map notificationData = userNotificationsData[i];
              if(mounted){
                notifications.value = [...notifications.value, NotificationClass(
                  notificationData['type'], notificationData['sender'], notificationData['referenced_post_id'], 
                  notificationData['referenced_post_type'], notificationData['notified_time'], notificationData['content'], 
                  (jsonDecode(notificationData['medias_datas'])), notificationData['sender_name'],
                  notificationData['sender_profile_picture_link'], notificationData['parent_post_type'], notificationData['post_deleted']
                )];
              }
            }
          }
          if(mounted){ 
            isLoading.value = false;
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> loadMoreNotifications() async{
    try {
      if(mounted){
        loadingNotificationsStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchNotificationsData(notifications.value.length, false, true);
          if(mounted){
            loadingNotificationsStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> refresh() async{
    fetchNotificationsData(0, true, false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: loadingNotificationsStatus,
            builder: (context, loadingStatusValue, child){
              return ValueListenableBuilder(
                valueListenable: canPaginate,
                builder: (context, canPaginateValue, child){
                  return ValueListenableBuilder(
                    valueListenable: notifications, 
                    builder: ((context, notifications, child) {
                      return LoadMoreBottom(
                        addBottomSpace: canPaginateValue,
                        loadMore: () async{
                          if(canPaginateValue){
                            await loadMoreNotifications();
                          }
                        },
                        status: loadingStatusValue,
                        refresh: refresh,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            SliverList(delegate: SliverChildBuilderDelegate(
                              childCount: notifications.length, 
                              (context, index) {
                                return CustomNotificationWidget(notificationClass: notifications[index], key: UniqueKey());
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
          ),
          ValueListenableBuilder(
            valueListenable: isLoading,
            builder: ((context, isLoadingValue, child) {
              if(isLoadingValue){
                return loadingPageWidget();
              }
              return Container();
            })
          )
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                _scrollController.animateTo(
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