import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfileFollowersController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The user id of the user whose bookmarks will be fetched. In this case, it is always the current user's id
  String userID;

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// Variable storing a list of the users' data
  ValueNotifier<List<String>> users = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);

  /// True if pagination is still possible
  ValueNotifier<bool> canPaginate = ValueNotifier(false);

  /// Stream used to listen to user actions on followers
  late StreamSubscription userDataStreamClassSubscription;

  ProfileFollowersController(
    this.context,
    this.userID
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchProfileFollowers(users.value.length, false), actionDelayTime);

    /// Initialize the streams
    userDataStreamClassSubscription = UserDataStreamClass().userDataStream.listen((UserDataStreamControllerClass data) {
      if(data.uniqueID == userID && data.actionType.name == UserDataStreamsUpdateType.addFollowers.name){
        if(mounted){
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
    userDataStreamClassSubscription.cancel();
    scrollController.dispose();
    displayFloatingBtn.dispose();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchProfileFollowers(int currentUsersLength, bool isRefreshing) async{
    if(mounted){

      /// Call the API to fetch the selected user's followers
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchUserProfileFollowers, 
        {
          'userID': userID,
          'currentID': appStateRepo.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        }
      );

      if(mounted){
        loadingState.value = LoadingState.loaded;

        /// API runs successfully
        if(res != null){

          List followersProfileDatasList = res['usersProfileData'];
          List followersSocialsDatasList = res['usersSocialsData'];

          if(isRefreshing){
            
            /// Empty the posts list if the user refreshes the page
            users.value = [];

          }

          /// The API will also determine whether further pagination is still possible or not
          canPaginate.value = res['canPaginate'];

          /// Update the user data of the followers to the application state repository
          for(int i = 0; i < followersProfileDatasList.length; i++){
            Map userProfileData = followersProfileDatasList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(followersSocialsDatasList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [userProfileData['user_id'], ...users.value];
          }

        }
      }
    }
  }

  /// Called when the user scrolled to the bottom and the page is still able to paginate
  Future<void> loadMoreUsers() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchProfileFollowers(users.value.length, false);
        if(mounted){

          /// Set the paginationStatus to loaded
          paginationStatus.value = PaginationStatus.loaded;
          
        }
      });
    }
  }
}