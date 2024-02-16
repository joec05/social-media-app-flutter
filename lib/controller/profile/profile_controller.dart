import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfileController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The user id of the user whose bookmarks will be fetched. In this case, it is always the current user's id
  String userID;

  /// Controller for handling tabs
  TabController tabController;

  /// True if an API/Firebase/AppWrite function is running
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Unique key for profile posts tab widget
  ValueNotifier<UniqueKey?> profilePostsWidgetUniqueKey = ValueNotifier(null);

  /// Unique key for profile replies tab widget
  ValueNotifier<UniqueKey?> profileRepliesWidgetUniqueKey = ValueNotifier(null);

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  ProfileController(
    this.context,
    this.userID,
    this.tabController
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchProfileData(), 0);
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
    tabController.dispose();
    isLoading.dispose();
    profilePostsWidgetUniqueKey.dispose();
    profileRepliesWidgetUniqueKey.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchProfileData() async{
    if(mounted){
      isLoading.value = true;
      profilePostsWidgetUniqueKey.value = UniqueKey();
      profileRepliesWidgetUniqueKey.value = UniqueKey();

      /// Call API to fetch selected user's profile data
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchUserProfileSocials, 
        {
          'userID': userID,
          'currentID': appStateRepo.currentID,
        }
      ); 
      
      if(mounted){
        isLoading.value = false;

        /// API runs successfully
        if(res != null){
          Map userProfileData = res['userProfileData'];
          if(userProfileData['code'] != 0){

            /// Update the user profile data to the app state repository
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            Map userSocialsData = res['userSocialsData'];
            UserSocialClass userSocialClass = UserSocialClass.fromMap(userSocialsData);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
          }
        }
      }
    }
  }
}