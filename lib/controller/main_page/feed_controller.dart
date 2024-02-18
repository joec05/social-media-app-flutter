import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FeedController {
  
  /// A context will need to be passed to the controller to handle navigation and snackbars handler
  BuildContext context;

  /// Variable storing a list of the posts' data
  ValueNotifier<List> posts = ValueNotifier([]);

  /// Variable storing the pagination status
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  
  /// Variable storing the loading status
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);

  /// Total amount of posts that can be displayed. A maximum value has been set by default. As the user
  /// paginates the value may change.
  ValueNotifier<int> totalPostsLength = ValueNotifier(postsServerFetchLimit);
  
  /// Stream used to listen to user actions on posts data
  late StreamSubscription postDataStreamClassSubscription;

  /// Stream used to listen to user actions on comments data
  late StreamSubscription commentDataStreamClassSubscription;

  /// True if the floating button should appear
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);

  /// Scroll controller in which the value of displayFloatingBtn depends on
  final ScrollController scrollController = ScrollController();

  FeedController(
    this.context
  );

  bool get mounted => context.mounted;

  /// This is where the controller is initialized. Called at every page's initState function
  void initializeController(){
    runDelay(() async => fetchFeedPosts(posts.value.length, false, false), actionDelayTime);

    /// Initialize the streams
    postDataStreamClassSubscription = PostDataStreamClass().postDataStream.listen((PostDataStreamControllerClass data) {
      if(data.uniqueID == appStateRepo.currentID && mounted){
        posts.value = [data.postClass, ...posts.value];
      }
    });
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(data.uniqueID == appStateRepo.currentID && mounted){
        posts.value = [data.commentClass, ...posts.value]; 
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
    postDataStreamClassSubscription.cancel();
    commentDataStreamClassSubscription.cancel();
    posts.dispose();
    paginationStatus.dispose();
    loadingState.dispose();
    totalPostsLength.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  /// Called when controller is initialized or when the page is paginating or refreshing
  Future<void> fetchFeedPosts(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      try {
        Map data;
        RequestGet call;
        
        /// Determine the endpoint as well as the data passed to the API depending on whether the user is paginating or not
        if(!isPaginating){
          data = {
            'userID': appStateRepo.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          };
          call = RequestGet.fetchFeed;
        }else{
          List paginatedFeed = await DatabaseHelper().fetchPaginatedFeedPosts(currentPostsLength, postsPaginationLimit);
          data = {
            'userID': appStateRepo.currentID,
            'feedPostsEncoded': jsonEncode(paginatedFeed),
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          };
          call = RequestGet.fetchFeedPagination;
        }

        if(mounted){

          /// Call the API to fetch the feed posts and comments
          dynamic res = await fetchDataRepo.fetchData(
            context, 
            call, 
            data
          );
          if(mounted){
            loadingState.value = LoadingState.loaded;
            
            /// The API call is successful
            if(res != null){

              List modifiedFeedPostsData = res['modifiedFeedPosts'];
              List userProfileDataList = res['usersProfileData'];
              List usersSocialsDatasList = res['usersSocialsData'];

              /// Update the user data of the posts and comments' senders to the application state repository
              for(int i = 0; i < userProfileDataList.length; i++){
                Map userProfileData = userProfileDataList[i];
                UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }

              if(isRefreshing){
                
                /// Empty the posts list if the user refreshes the page
                posts.value = [];

              }

              if(!isPaginating){

                /// Update the total posts length which will be used to find out whether to paginate
                /// UI/UX wise
                totalPostsLength.value = res['totalPostsLength'];

              }
              
              /// Handle the feed posts and comments
              for(int i = 0; i < modifiedFeedPostsData.length; i++){
                
                /// Convert the raw map data to class model and update to posts list and app state repository
                /// depending on the type
                if(modifiedFeedPostsData[i]['type'] == 'post'){
                  Map postData = modifiedFeedPostsData[i];
                  List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                  List<MediaDatasClass> newMediasDatas = [];
                  newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
                  PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                  updatePostData(postDataClass);
                  posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
                }else{
                  Map commentData = modifiedFeedPostsData[i];
                  List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                  List<MediaDatasClass> newMediasDatas = [];
                  newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
                  CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                  updateCommentData(commentDataClass);
                  posts.value = [...posts.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
                }

              }

              if(!isPaginating){
                
                /// Save the feed data to the local SQLite database if the page initially loaded, or if the user refreshes the page
                List feedPosts = res['feedPosts'];
                await DatabaseHelper().replaceFeedPosts(feedPosts);

              }
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
  Future<void> loadMorePosts() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchFeedPosts(posts.value.length, false, true);
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
    await fetchFeedPosts(0, true, false);
  }
}