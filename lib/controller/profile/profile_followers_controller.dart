import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class ProfileFollowersController {
  BuildContext context;
  String userID;
  final ScrollController scrollController = ScrollController();
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(true);
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription userDataStreamClassSubscription;

  ProfileFollowersController(
    this.context,
    this.userID
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchProfileFollowers(users.value.length, false), actionDelayTime);
    userDataStreamClassSubscription = UserDataStreamClass().userDataStream.listen((UserDataStreamControllerClass data) {
      if(data.uniqueID == userID && data.actionType.name == UserDataStreamsUpdateType.addFollowers.name){
        if(mounted){
          if(!users.value.contains(data.userID)){
            users.value = [data.userID, ...users.value];
          }
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
    userDataStreamClassSubscription.cancel();
    scrollController.dispose();
    displayFloatingBtn.dispose();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
  }

  Future<void> fetchProfileFollowers(int currentUsersLength, bool isRefreshing) async{
    if(mounted){
      dynamic res = await fetchDataRepo.fetchData(
        context, 
        RequestGet.fetchUserProfileFollowers, 
        {
          'userID': userID,
          'currentID': appStateRepo.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        }
      );
      if(mounted){
        loadingState.value = LoadingState.loaded;
        if(res != null){
          List followersProfileDatasList = res['usersProfileData'];
          List followersSocialsDatasList = res['usersSocialsData'];
          if(isRefreshing){
            users.value = [];
          }
          canPaginate.value = res['canPaginate'];
          for(int i = 0; i < followersProfileDatasList.length; i++){
            Map userProfileData = followersProfileDatasList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(followersSocialsDatasList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [userProfileData['user_id'], ...users.value];
          }
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
        await fetchProfileFollowers(users.value.length, false);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}