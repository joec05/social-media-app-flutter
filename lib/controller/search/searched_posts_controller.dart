import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchedPostsController {
  BuildContext context;
  String searchedText;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<int> totalPostsLength = ValueNotifier(postsServerFetchLimit);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  SearchedPostsController(
    this.context,
    this.searchedText
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchSearchedPosts(posts.value.length, false, false), actionDelayTime);
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
    loadingState.dispose();
    posts.dispose();
    paginationStatus.dispose();
    totalPostsLength.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchSearchedPosts(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted) {
      try {
        Map data;
        RequestGet call;
        if(!isPaginating){
          data = {
            'searchedText': searchedText,
            'currentID': appStateRepo.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          };
          call = RequestGet.fetchSearchedPosts;
        }else{
          List paginatedSearchedPosts = await DatabaseHelper().fetchPaginatedSearchedPosts(currentPostsLength, postsPaginationLimit);
          data = {
            'searchedText': searchedText,
            'searchedPostsEncoded': jsonEncode(paginatedSearchedPosts),
            'currentID': appStateRepo.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          };
          call = RequestGet.fetchSearchedPostsPagination;
        }
        if(mounted) {
          dynamic res = await fetchDataRepo.fetchData(
            context, 
            call, 
            data
          );
          if(mounted) {
            loadingState.value = LoadingState.loaded;
            if(res != null) {
              if(!isPaginating){
                List searchedPosts = res['searchedPosts'];
                await DatabaseHelper().replaceAllSearchedPosts(searchedPosts);
              }
              List modifiedSearchedPostsData = res['modifiedSearchedPosts'];
              List userProfileDataList = res['usersProfileData'];
              List usersSocialsDatasList = res['usersSocialsData'];
              if(isRefreshing){
                posts.value = [];
              }
              if(!isPaginating){
                totalPostsLength.value = min(res['totalPostsLength'], postsServerFetchLimit);
              }
              for(int i = 0; i < userProfileDataList.length; i++){
                Map userProfileData = userProfileDataList[i];
                UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
              for(int i = 0; i < modifiedSearchedPostsData.length; i++){
                Map postData = modifiedSearchedPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                if(mounted){
                  newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
                  PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                  updatePostData(postDataClass);
                  if(posts.value.length < totalPostsLength.value){
                    posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
                  }
                }
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

  Future<void> loadMorePosts() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchSearchedPosts(posts.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchSearchedPosts(0, true, false);
  }
}