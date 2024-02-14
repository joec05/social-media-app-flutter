import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FollowRequestToController {
  BuildContext context;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription requestsToDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  FollowRequestToController(
    this.context
  );

  bool get mounted => context.mounted;
  
  void initializeController(){
    runDelay(() async => fetchFollowRequestsTo(users.value.length, false, false), actionDelayTime);
    requestsToDataStreamClassSubscription = RequestsToDataStreamClass().requestsToDataStream.listen((RequestsToDataStreamControllerClass data) {
      if(data.uniqueID == 'unlock_account_${appStateRepo.currentID}' && mounted){
        List<String> usersIdList = [...users.value];
        users.value = [];
        for(int i = 0; i < usersIdList.length; i++){
          String userID = usersIdList[i];
          acceptFollowRequest(context, userID);
        }
        UserSocialClass currentUserSocialClass = appStateRepo.usersSocialsNotifiers.value[appStateRepo.currentID]!.notifier.value;
        appStateRepo.usersSocialsNotifiers.value[appStateRepo.currentID]!.notifier.value = UserSocialClass(
          currentUserSocialClass.followersCount + usersIdList.length, currentUserSocialClass.followingCount, 
          false, false
        );
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
    requestsToDataStreamClassSubscription.cancel();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
  }

  Future<void> fetchFollowRequestsTo(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchFollowRequestsToUser, 
        {
          'currentID': appStateRepo.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': followRequestsPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        }
      );
      if(mounted){
        loadingState.value = LoadingState.loaded;
        if(res != null){
          List usersProfileDataList = res['usersProfileData'];
          List usersSocialsDataList = res['usersSocialsData'];
          if(isRefreshing){
            users.value = [];
          }
          for(int i = 0; i < usersProfileDataList.length; i++){
            Map userProfileData = usersProfileDataList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDataList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [...users.value, userProfileData['user_id']];
          }
          canPaginate.value = res['canPaginate'];
        }
      }
    }
  }

  Future<void> loadMoreUsers() async{
    if(mounted){
      loadingState.value = LoadingState.paginating;
      paginationStatus.value = PaginationStatus.loading;
      Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
        timer.cancel();
        await fetchFollowRequestsTo(users.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchFollowRequestsTo(0, true, false);
  }
}