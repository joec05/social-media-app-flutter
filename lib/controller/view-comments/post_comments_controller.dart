import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class PostCommentsController {
  BuildContext context;
  PostClass selectedPostData;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<DisplayPostDataClass?> selectedPost = ValueNotifier(null);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(true);
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  PostCommentsController(
    this.context,
    this.selectedPostData
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchPostData(comments.value.length, false, false), actionDelayTime);
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == selectedPostData.postID){
          comments.value = [data.commentClass, ...comments.value];
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
    commentDataStreamClassSubscription.cancel();
    loadingState.dispose();
    comments.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    selectedPost.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchPostData(int currentCommentsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      try {
        RequestGet call;
        if(!isPaginating){
          call = RequestGet.fetchSelectedPostComments;
        }else{
          call = RequestGet.fetchSelectedPostCommentsPagination;
        }
        dynamic res = fetchDataRepo.fetchData(
          context, 
          call, 
          {
            'sender': selectedPostData.sender,
            'postID': selectedPostData.postID,
            'currentID': appStateClass.currentID,
            'currentLength': currentCommentsLength,
            'paginationLimit': usersPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          }
        );
        if(mounted){
          loadingState.value = LoadingState.loaded;
          if(res != null){
            List allPostsData = [...res.data['commentsData']];
            if(!isPaginating){
              allPostsData.insert(0, res.data['selectedPostData']);
            }
            canPaginate.value = res.data['canPaginate'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              updateUserData(userDataClass);
              updateUserSocials(userDataClass, userSocialClass);
            }
            for(int i = 0; i < allPostsData.length; i++){
              if(allPostsData[i]['type'] == 'post'){
                Map postData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                updatePostData(postDataClass);
                selectedPost.value = DisplayPostDataClass(postData['sender'], postData['post_id']);
              }else{
                Map commentData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                updateCommentData(commentDataClass);
                comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
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

  Future<void> loadMoreComments() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchPostData(comments.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}