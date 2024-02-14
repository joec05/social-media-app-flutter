import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FeedController {
  BuildContext context;
  ValueNotifier<List> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<int> totalPostsLength = ValueNotifier(postsServerFetchLimit);
  late StreamSubscription postDataStreamClassSubscription;
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  FeedController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchFeedPosts(posts.value.length, false, false), actionDelayTime);
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

  Future<void> fetchFeedPosts(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      try {
        Map data;
        RequestGet call;
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
          dynamic res = await fetchDataRepo.fetchData(
            context, 
            call, 
            data
          );
          if(mounted){
            loadingState.value = LoadingState.loaded;
            if(res != null){
              List modifiedFeedPostsData = res['modifiedFeedPosts'];
              List userProfileDataList = res['usersProfileData'];
              List usersSocialsDatasList = res['usersSocialsData'];
              for(int i = 0; i < userProfileDataList.length; i++){
                Map userProfileData = userProfileDataList[i];
                UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
              if(isRefreshing){
                posts.value = [];
              }
              if(!isPaginating){
                totalPostsLength.value = res['totalPostsLength'];
              }
              for(int i = 0; i < modifiedFeedPostsData.length; i++){
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

  Future<void> loadMorePosts() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchFeedPosts(posts.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    await fetchFeedPosts(0, true, false);
  }
}