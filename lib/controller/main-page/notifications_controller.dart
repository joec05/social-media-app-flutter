import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class NotificationsController {

  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// Variable storing a list of the notifications' data
  ValueNotifier<List<NotificationClass>> notifications = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  
  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// Total amount of posts that can be displayed. A maximum value has been set by default. As the user
  /// paginates the value may change.
  ValueNotifier<int> totalPostsLength = ValueNotifier(postsServerFetchLimit);

  /// True if pagination is still possible
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  
  /// Stream used to listen to user actions on notifications
  late StreamSubscription notificationDataStreamClassSubscription;

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  NotificationsController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchNotificationsData(notifications.value.length, false, false), actionDelayTime);

    /// Initialize the streams
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

  /// Dispose everything. Called at every page's dispose function
  void dispose(){
    notificationDataStreamClassSubscription.cancel();
    loadingState.dispose();
    notifications.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchNotificationsData(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){

      /// Call API to fetch notifications data
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchUserNotifications, 
        {
          'currentID': appStateRepo.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': notificationsPaginationLimit,
          'maxFetchLimit': notificationsServerFetchLimit
        }
      );

      if(mounted){
        loadingState.value = LoadingState.loaded;

        /// The API call is successful
        if(res != null){
          List userNotificationsData = res['userNotificationsData'];

          if(isRefreshing){
            
            /// Empty the notifications list if the user refreshes the page
            notifications.value = [];

          }

          /// The API will also determine whether further pagination is still possible or not
          canPaginate.value = res['canPaginate'];

          /// Handle the notifications data 
          for(int i = 0; i < userNotificationsData.length; i++){

            /// Convert the raw map data to class model and update to notifications list
            Map notificationData = userNotificationsData[i];
            notifications.value = [...notifications.value, NotificationClass(
              notificationData['type'], notificationData['sender'], notificationData['referenced_post_id'], 
              notificationData['referenced_post_type'], notificationData['notified_time'], notificationData['content'], 
              (jsonDecode(notificationData['medias_datas'])), notificationData['sender_name'],
              notificationData['sender_profile_picture_link'], notificationData['parent_post_type'], notificationData['post_deleted']
            )];

          }

        }
      }
    }
  }

  /// Called when the user scrolled to the bottom and the page is still able to paginate
  Future<void> loadMoreNotifications() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchNotificationsData(notifications.value.length, false, true);
        if(mounted){

          /// Set the paginationStatus to loaded
          paginationStatus.value = PaginationStatus.loaded;

        }
      });
    }
  }

  /// Called when the user refreshes the page
  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchNotificationsData(0, true, false);
  }
}