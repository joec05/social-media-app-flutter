import 'dart:async';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class GroupMembersController {
  BuildContext context;
  List<String> usersID;
  final ScrollController scrollController = ScrollController();
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<int> totalUsersLength = ValueNotifier(0);

  GroupMembersController(
    this.context,
    this.usersID
  );

  bool get mounted => context.mounted;

  void initializeController(){
    if(mounted){
      totalUsersLength.value = usersID.length;
    }
    runDelay(() async => fetchGroupMembersData(users.value.length, false), actionDelayTime);
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
    scrollController.dispose();
    displayFloatingBtn.dispose();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    totalUsersLength.dispose();
  }

  Future<void> fetchGroupMembersData(int currentUsersLength, bool isRefreshing) async{
    if(mounted){
      try {
        dynamic res = await apiCallRepo.runAPICall(
          context, 
          APIGet.fetchGroupMembersData, 
          {
            'usersID': usersID,
            'currentID': appStateClass.currentID,
            'currentLength': currentUsersLength,
            'paginationLimit': usersPaginationLimit,
            'maxFetchLimit': usersServerFetchLimit
          }
        );
        if(mounted){
          loadingState.value = LoadingState.loaded;
        }
        if(res != null && mounted){
          List followersProfileDatasList = res.data['usersProfileData'];
          List followersSocialsDatasList = res.data['usersSocialsData'];
          if(isRefreshing){
            users.value = [];
          }
          for(int i = 0; i < followersProfileDatasList.length; i++){
            Map userProfileData = followersProfileDatasList[i];
            UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
            UserSocialClass userSocialClass = UserSocialClass.fromMap(followersSocialsDatasList[i]);
            updateUserData(userDataClass);
            updateUserSocials(userDataClass, userSocialClass);
            users.value = [userProfileData['user_id'], ...users.value];
          }
        }
      } catch (_) {
        if(mounted){
          loadingState.value = LoadingState.loaded;
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.api
          );
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
        await fetchGroupMembersData(users.value.length, false);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }
}