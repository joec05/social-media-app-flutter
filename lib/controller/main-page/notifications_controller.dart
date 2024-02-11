import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class NotificationsController {
  BuildContext context;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<NotificationClass>> notifications = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription notificationDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  NotificationsController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
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
    scrollController.addListener(() {
      if(mounted){
        if(scrollController.position.pixels > animateToTopMinHeight){
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

  void dispose(){
    notificationDataStreamClassSubscription.cancel();
    loadingState.dispose();
    notifications.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchNotificationsData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        String stringified = jsonEncode({
          'currentID': appStateClass.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': notificationsPaginationLimit,
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
            loadingState.value = LoadingState.loaded;
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }

  Future<void> loadMoreNotifications() async{
    try {
      if(mounted){
        loadingState.value = LoadingState.paginating;
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchNotificationsData(notifications.value.length, false, true);
          if(mounted){
            paginationStatus.value = PaginationStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchNotificationsData(0, true, false);
  }
}