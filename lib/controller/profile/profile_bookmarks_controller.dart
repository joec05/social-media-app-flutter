import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfileBookmarksController {
  BuildContext context;
  String userID;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription bookmarkDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  ProfileBookmarksController(
    this.context,
    this.userID
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchProfileBookmarks(posts.value.length, false), actionDelayTime);
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

  void dispose(){
    bookmarkDataStreamClassSubscription.cancel();
    loadingState.dispose();
    posts.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchProfileBookmarks(int currentBookmarksLength, bool isRefreshing) async{
    if(mounted){ 
      try {
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
          if(res != null){
            List userBookmarksData = res['userBookmarksData'];
            List userProfileDataList = res['usersProfileData'];
            List usersSocialsDatasList = res['usersSocialsData'];
            if(isRefreshing){
              posts.value = [];
            }
            canPaginate.value = res['canPaginate'];
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              updateUserData(userDataClass);
              updateUserSocials(userDataClass, userSocialClass);
            }
            for(int i = 0; i < userBookmarksData.length; i++){
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

  Future<void> loadMoreBookmarks() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchProfileBookmarks(posts.value.length, false);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}