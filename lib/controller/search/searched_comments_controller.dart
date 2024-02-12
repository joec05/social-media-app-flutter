import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchedCommentsController {
  BuildContext context;
  String searchedText;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<int> totalCommentsLength = ValueNotifier(postsServerFetchLimit);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  SearchedCommentsController(
    this.context,
    this.searchedText
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchSearchedComments(comments.value.length, false, false), actionDelayTime);
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
    comments.dispose();
    paginationStatus.dispose();
    totalCommentsLength.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchSearchedComments(int currentCommentsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted) {
      try {
        Map data;
        RequestGet call;
        if(!isPaginating){
          data = {
            'searchedText': searchedText,
            'currentID': appStateClass.currentID,
            'currentLength': currentCommentsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          };
          call = RequestGet.fetchSearchedComments;
        }else{
          List paginatedSearchedComments = await DatabaseHelper().fetchPaginatedSearchedComments(currentCommentsLength, postsPaginationLimit);
          data = {
            'searchedText': searchedText,
            'searchedCommentsEncoded': jsonEncode(paginatedSearchedComments),
            'currentID': appStateClass.currentID,
            'currentLength': currentCommentsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          };
          call = RequestGet.fetchSearchedCommentsPagination;
        }
        if(mounted) {
          dynamic res = await fetchDataRepo.fetchData(
            context, 
            call, 
            data
          );
          if(mounted){
            loadingState.value = LoadingState.loaded;
            if(res != null){
              if(!isPaginating){
                List searchedComments = res.data['searchedComments'];
                await DatabaseHelper().replaceAllSearchedComments(searchedComments);
              }
              List modifiedSearchedCommentsData = res.data['modifiedSearchedComments'];
              List userProfileDataList = res.data['usersProfileData'];
              List usersSocialsDatasList = res.data['usersSocialsData'];
              if(isRefreshing){
                comments.value = [];
              }
              if(!isPaginating){
                totalCommentsLength.value = min(res.data['totalCommentsLength'], postsServerFetchLimit);
              }
              for(int i = 0; i < userProfileDataList.length; i++){
                Map userProfileData = userProfileDataList[i];
                UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
                UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
              for(int i = 0; i < modifiedSearchedCommentsData.length; i++){
                Map commentData = modifiedSearchedCommentsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(context, mediasDatasFromServer);
                CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                updateCommentData(commentDataClass);
                if(comments.value.length < totalCommentsLength.value){
                  comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
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

  Future<void> loadMoreComments() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchSearchedComments(comments.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    await fetchSearchedComments(0, true, false);
  }
}