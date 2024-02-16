import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfileBookmarksController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// The user id of the user whose bookmarks will be fetched. In this case, it is always the current user's id
  String userID;

  /// Variable storing a list of the posts' data
  ValueNotifier<List> posts = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  
  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// True if pagination is still possible
  ValueNotifier<bool> canPaginate = ValueNotifier(false);

  /// Stream used to listen to user actions on bookmarks
  late StreamSubscription bookmarkDataStreamClassSubscription;
  
  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  ProfileBookmarksController(
    this.context,
    this.userID
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchProfileBookmarks(posts.value.length, false), actionDelayTime);

    /// Initialize the streams
    bookmarkDataStreamClassSubscription = BookmarkDataStreamClass().bookmarkDataStream.listen((BookmarkDataStreamControllerClass data) {
      if(data.uniqueID == 'add_bookmarks_${appStateRepo.currentID}'){
        var postClass = data.postClass;
        String bookmarkedID = postClass is DisplayPostDataClass ? postClass.postID : postClass.commentID;
        bool isExistsInList = posts.value.where((e) => e is DisplayPostDataClass ? e.postID == bookmarkedID : e.commentID == bookmarkedID).toList().isNotEmpty;
        if(!isExistsInList && mounted){
          posts.value = [postClass, ...posts.value];
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
    bookmarkDataStreamClassSubscription.cancel();
    loadingState.dispose();
    posts.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchProfileBookmarks(int currentBookmarksLength, bool isRefreshing) async{
    if(mounted){ 
      try {

        /// Call the API to fetch bookmarks data
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchUserBookmarks, 
          {
            'userID': userID,
            'currentID': appStateRepo.currentID,
            'currentLength': currentBookmarksLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          }
        );

        if(mounted){
          loadingState.value = LoadingState.loaded;

          /// The API call is successful
          if(res != null){

            List userBookmarksData = res['userBookmarksData'];
            List userProfileDataList = res['usersProfileData'];
            List usersSocialsDatasList = res['usersSocialsData'];

            if(isRefreshing){
              /// Empty the posts list if the user refreshes the page
              posts.value = [];
            }

            /// The API will also determine whether further pagination is still possible or not
            canPaginate.value = res['canPaginate'];

            /// Update the user data of the posts and comments' senders to the application state repository
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              updateUserData(userDataClass);
              updateUserSocials(userDataClass, userSocialClass);
            }

            /// Handle the bookmarks data
            for(int i = 0; i < userBookmarksData.length; i++){

              /// Depending on their type, convert the raw map data to the model class, and update it to the
              /// posts list and the app state repository
              if(userBookmarksData[i]['type'] == 'post'){
                Map postData = userBookmarksData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                updatePostData(postDataClass);
                posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
              }else{
                Map commentData = userBookmarksData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
                CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                updateCommentData(commentDataClass);
                posts.value = [...posts.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
              }

            }
          }
        }
      } catch (_) {
        if(mounted) {
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
  Future<void> loadMoreBookmarks() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchProfileBookmarks(posts.value.length, false);
        if(mounted){
          
          /// Set the paginationStatus to loaded
          paginationStatus.value = PaginationStatus.loaded;

        }
      });
    }
  }
}