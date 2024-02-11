import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class CommentCommentsController {
  BuildContext context;
  CommentClass selectedCommentData;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  ValueNotifier<DisplayCommentDataClass?> selectedComment = ValueNotifier(null);
  ValueNotifier<dynamic> parentPost = ValueNotifier(null);
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  CommentCommentsController(
    this.context,
    this.selectedCommentData
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchCommentData(comments.value.length, false, false), actionDelayTime);
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == selectedCommentData.commentID){
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
    selectedComment.dispose();
    parentPost.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchCommentData(int currentCommentsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        String stringified = jsonEncode({
          'sender': selectedCommentData.sender,
          'commentID': selectedCommentData.commentID,
          'currentID': appStateClass.currentID,
          'currentLength': currentCommentsLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': postsServerFetchLimit
        });
        Response res ;
        if(!isPaginating){
          res = await dio.get('$serverDomainAddress/users/fetchSelectedCommentComments', data: stringified);
        }else{
          res = await dio.get('$serverDomainAddress/users/fetchSelectedCommentCommentsPagination', data: stringified);
        }
        
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List allPostsData = [...res.data['commentsData']];
            if(!isPaginating){
              res.data['parentPostData']['type'] = 'parent_${res.data['parentPostData']['type']}';
              res.data['selectedCommentData']['type'] = 'selected_${res.data['selectedCommentData']['type']}';
              allPostsData.insertAll(0, [res.data['parentPostData'], res.data['selectedCommentData']]);
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
            }
        
            for(int i = 0; i < allPostsData.length; i++){
              if(allPostsData[i]['type'] == 'parent_post'){
                Map postData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                if(mounted){
                  updatePostData(postDataClass);
                  parentPost.value = DisplayPostDataClass(postData['sender'], postData['post_id']);
                }
              }else{
                Map commentData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                if(mounted){
                  updateCommentData(commentDataClass);
                  if(commentData['type'] == 'parent_comment'){
                    parentPost.value = DisplayCommentDataClass(commentData['sender'], commentData['comment_id']);
                  }else if(commentData['type'] == 'selected_comment'){
                    selectedComment.value = DisplayCommentDataClass(commentData['sender'], commentData['comment_id']);
                  }else{
                    comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
                  }
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

  Future<void> loadMoreComments() async{
    try {
      if(mounted){
        loadingState.value = LoadingState.paginating;
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchCommentData(comments.value.length, false, true);
          if(mounted){
            paginationStatus.value = PaginationStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      
    }
  }
}