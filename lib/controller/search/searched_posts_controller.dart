import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
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
    try {
      if(mounted){
        String stringified = '';
        Response res;
        if(!isPaginating){
          stringified = jsonEncode({
            'searchedText': searchedText,
            'currentID': appStateClass.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedPosts', data: stringified);
        }else{
          List paginatedSearchedPosts = await DatabaseHelper().fetchPaginatedSearchedPosts(currentPostsLength, postsPaginationLimit);
          stringified = jsonEncode({
            'searchedText': searchedText,
            'searchedPostsEncoded': jsonEncode(paginatedSearchedPosts),
            'currentID': appStateClass.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedPostsPagination', data: stringified);
        }
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data' && mounted){
            if(!isPaginating){
              List searchedPosts = res.data['searchedPosts'];
              await DatabaseHelper().replaceAllSearchedPosts(searchedPosts);
            }
            List modifiedSearchedPostsData = res.data['modifiedSearchedPosts'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              posts.value = [];
            }
            if(!isPaginating && mounted){
              totalPostsLength.value = min(res.data['totalPostsLength'], postsServerFetchLimit);
            }
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
            }
            for(int i = 0; i < modifiedSearchedPostsData.length; i++){
              Map postData = modifiedSearchedPostsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
              PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
              if(mounted){
                updatePostData(postDataClass);
                if(posts.value.length < totalPostsLength.value){
                  posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
                }
              }
            }
          }
          if(mounted){
            loadingState.value = LoadingState.loaded;
          }
        }
      }
    } on Exception catch (e) {
      
    }
  }

  Future<void> loadMorePosts() async{
    try {
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
    } on Exception catch (e) {
      
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchSearchedPosts(0, true, false);
  }
}