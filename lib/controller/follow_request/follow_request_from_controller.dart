import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FollowRequestFromController {
  
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

  /// Stream used to listen to follow requests from the user
  late StreamSubscription requestsFromDataStreamClassSubscription;

  FollowRequestFromController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchFollowRequestsFrom(users.value.length, false, false), actionDelayTime);

    /// Initialize the streams
    requestsFromDataStreamClassSubscription = RequestsFromDataStreamClass().requestsFromDataStream.listen((RequestsFromDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == 'send_follow_request_${appStateRepo.currentID}'){
          if(!users.value.contains(data.userID)){
            users.value = [data.userID, ...users.value];
          }
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
    requestsFromDataStreamClassSubscription.cancel();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchFollowRequestsFrom(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted) {
      try {

        /// Call the API to fetch the follow requests from the user
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchFollowRequestsFromUser, 
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

            /// Update the user data of the requested users to the application state repository
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
      } catch (_) {
        if(mounted){
          loadingState.value = LoadingState.loaded;
          handler.displaySnackbar(
            context, 
            SnackbarType.error,
            tErr.unknown
          );
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
        await fetchFollowRequestsFrom(users.value.length, false, true);
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
    fetchFollowRequestsFrom(0, true, false);
  }
}