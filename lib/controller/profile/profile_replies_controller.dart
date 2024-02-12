import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfileRepliesController {
  BuildContext context;
  String userID;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  ProfileRepliesController(
    this.context,
    this.userID
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchProfileReplies(comments.value.length, false), actionDelayTime);
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(data.uniqueID == appStateClass.currentID && mounted){
        comments.value = [data.commentClass, ...comments.value];
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
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchProfileReplies(int currentCommentsLength, bool isRefreshing) async{
    if(mounted){
      try {
        dynamic res = await fetchDataRepo.fetchData(
          context, 
          RequestGet.fetchUserComments, 
          {
            'userID': userID,
            'currentID': appStateClass.currentID,
            'currentLength': currentCommentsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          }
        );
        if(mounted) {
          loadingState.value = LoadingState.loaded;
          if(res != null) {
            List userCommentsData = res.data['userCommentsData'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              comments.value = [];
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
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
            for(int i = 0; i < userCommentsData.length; i++){
              Map commentData = userCommentsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
              CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
              if(mounted){
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
        await fetchProfileReplies(comments.value.length, false);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}