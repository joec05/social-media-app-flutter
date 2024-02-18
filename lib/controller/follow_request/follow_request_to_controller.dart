import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FollowRequestToController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// Variable storing a list of the users' data
  ValueNotifier<List<String>> users = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);

  // True if pagination is still possible
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  
  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  late StreamSubscription requestsToDataStreamClassSubscription;

  FollowRequestToController(
    this.context
  );

  bool get mounted => context.mounted;
  
  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchFollowRequestsTo(users.value.length, false, false), actionDelayTime);

    /// Initialize the streams
    requestsToDataStreamClassSubscription = RequestsToDataStreamClass().requestsToDataStream.listen((RequestsToDataStreamControllerClass data) {
      if(data.uniqueID == 'unlock_account_${appStateRepo.currentID}' && mounted){
        List<String> usersIdList = [...users.value];
        users.value = [];
        for(int i = 0; i < usersIdList.length; i++){
          String userID = usersIdList[i];
          acceptFollowRequest(context, userID);
        }
        UserSocialClass currentUserSocialClass = appStateRepo.usersSocialsNotifiers.value[appStateRepo.currentID]!.notifier.value;
        appStateRepo.usersSocialsNotifiers.value[appStateRepo.currentID]!.notifier.value = UserSocialClass(
          currentUserSocialClass.followersCount + usersIdList.length, currentUserSocialClass.followingCount, 
          false, false
        );
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
    requestsToDataStreamClassSubscription.cancel();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchFollowRequestsTo(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      
      /// Call the API to fetch the follow requests to the user
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchFollowRequestsToUser, 
        {
          'currentID': appStateRepo.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': followRequestsPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        }
      );

      if(mounted){
        loadingState.value = LoadingState.loaded;
        
        /// The API call is successful
        if(res != null){
          List usersProfileDataList = res['usersProfileData'];
          List usersSocialsDataList = res['usersSocialsData'];

          if(isRefreshing){

            /// Empty the users list if the user refreshes the page
            users.value = [];

          }

          /// The API will also determine whether further pagination is still possible or not
          canPaginate.value = res['canPaginate'];

          /// Update the user data of the requesting users to the application state repository
          for(int i = 0; i < usersProfileDataList.length; i++){
            Map userProfileData = usersProfileDataList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDataList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [...users.value, userProfileData['user_id']];
          }

        }
      }
    }
  }

  /// Called when the user scrolled to the bottom and the page is still able to paginate
  Future<void> loadMoreUsers() async{
    if(mounted){

      /// Set the loadingState to paginating and paginationStatus to loading and run a timer 
      /// delay before calling the function
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchFollowRequestsTo(users.value.length, false, true);
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
    fetchFollowRequestsTo(0, true, false);
  }
}