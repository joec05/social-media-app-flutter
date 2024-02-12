import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfilePostsController {
  BuildContext context;
  String userID;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription postDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  ProfilePostsController(
    this.context,
    this.userID
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchProfilePosts(posts.value.length, false), actionDelayTime);
    postDataStreamClassSubscription = PostDataStreamClass().postDataStream.listen((PostDataStreamControllerClass data) {
      if(data.uniqueID == appStateClass.currentID && mounted){
        posts.value = [data.postClass, ...posts.value];
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

  void dispose() async{
    postDataStreamClassSubscription.cancel();
    loadingState.dispose();
    posts.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchProfilePosts(int currentPostsLength, bool isRefreshing) async{
    if(mounted){  
      try {
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchUserPosts, 
          {
            'userID': userID,
            'currentID': appStateClass.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          }
        );
        if(mounted){
          loadingState.value = LoadingState.loaded;
          if(res != null) {
            List userPostsData = res.data['userPostsData'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing){
              posts.value = [];
            }
            canPaginate.value = res.data['canPaginate'];
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              updateUserData(userDataClass);
              updateUserSocials(userDataClass, userSocialClass);
            }
            for(int i = 0; i < userPostsData.length; i++){
              Map postData = userPostsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
              PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
              updatePostData(postDataClass);
              posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
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

  Future<void> loadMorePosts() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchProfilePosts(posts.value.length, false);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}