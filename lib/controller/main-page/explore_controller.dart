import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ExploreController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// Editing controller for search input
  TextEditingController searchedController = TextEditingController();

  /// A variable containing a list of hashtags data
  ValueNotifier<List<HashtagClass>> hashtags = ValueNotifier([]);

  /// A variable containing a list of users data
  ValueNotifier<List<String>> users = ValueNotifier([]);

  /// A variable containing a list of posts data
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);

  /// True if the search input is in correct format
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);

  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  /// The maximum amount of hashtags, posts and users that can be displayed
  final exploreDataLimit = 10;

  ExploreController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchExploreData(), actionDelayTime);
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
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
    searchedController.dispose();
    hashtags.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  /// Called during initialization or refresh
  Future<void> fetchExploreData() async{
    if(mounted){

      /// Reset the users, hashtags and posts list
      users.value = [];
      hashtags.value = [];
      posts.value = [];

      /// Call the API to fetch the top hashtags, the top users and the top posts lists
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchTopData, 
        {
          'currentID': appStateRepo.currentID,
          'paginationLimit': exploreDataLimit,
        }
      );

      if(mounted){
        loadingState.value = LoadingState.loaded;

        /// The API call is successful
        if(res != null){

          List postsData = res['postsData'];
          List usersProfileDatasList = res['usersProfileData'];
          List usersSocialsDatasList = res['usersSocialsData'];
          List hashtagsData = res['hashtagsData'];

          /// Update the post data of the top posts requested users to the application state repository and posts list
          for(int i = 0; i < postsData.length; i++){
            Map postData = postsData[i];
            List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
            List<MediaDatasClass> newMediasDatas = [];

            /// Load the attached media and put them into a model class
            newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);

            PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
            updatePostData(postDataClass);
            posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
          }

          /// Update the user data of the top users to the application state repository and users list
          for(int i = 0; i < usersProfileDatasList.length; i++){
            Map userProfileData = usersProfileDatasList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [userProfileData['user_id'], ...users.value];
          }

          /// Update the hashtag data of the top hashtags to the hashtags list
          for(int i = 0; i < hashtagsData.length; i++){
            Map hashtagData = hashtagsData[i];
            hashtags.value = [...hashtags.value, HashtagClass(hashtagData['hashtag'], hashtagData['hashtag_count'])];
          }
          
        }
      }
    }
  }
}