import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

/// Controller which is used when the user views the list of group chat members
class GroupMembersController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// A list of user ID of the group chat members passed to the controller
  /// It is read-only and set to be used only when the controller is initialized
  final List<String> usersID;

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// Variable storing the list of user ID of the group chat members
  /// Unlike the usersID variable, this variable may change even after initialization
  ValueNotifier<List<String>> users = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);

  GroupMembersController(
    this.context,
    this.usersID
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    if(mounted){
      users.value = usersID;
    }
    runDelay(() async => fetchGroupMembersData(0, false), actionDelayTime);
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
    scrollController.dispose();
    displayFloatingBtn.dispose();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
  }

  /// Called during initialization
  Future<void> fetchGroupMembersData(int currentUsersLength, bool isRefreshing) async{
    if(mounted){
      try {

        /// Call the API to fetch the user data of the group chat members based on the given list of IDs
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchGroupMembersData, 
          {
            'usersID': users.value,
            'currentID': appStateRepo.currentID,
            'currentLength': currentUsersLength,
            'paginationLimit': usersPaginationLimit,
            'maxFetchLimit': usersServerFetchLimit
          }
        );

        if(mounted){
          loadingState.value = LoadingState.loaded;

          /// The API successfully fetched the needed data
          if(res != null){

            List followersProfileDatasList = res['usersProfileData'];
            List followersSocialsDatasList = res['usersSocialsData'];

            if(isRefreshing){
              
              /// Reset the users id list if the user refreshed
              users.value = [];

            }

            /// Update the user data of the group members to the application state repository
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
      } catch (_) {
        if(mounted){
          loadingState.value = LoadingState.loaded;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.api
          );
        }
      }
    }
  }

  Future<void> loadMoreUsers() async{
    if(mounted){

      /// Set the loadingState to paginating and paginationStatus to loading and run a timer 
      /// delay before calling the function
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchGroupMembersData(users.value.length, false);
        if(mounted){

          /// Set the paginationStatus to loaded
          paginationStatus.value = PaginationStatus.loaded;
          
        }
      });
    }
  }
}