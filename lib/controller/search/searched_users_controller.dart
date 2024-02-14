import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class SearchedUsersController {
  BuildContext context;
  String searchedText;
  final ScrollController scrollController = ScrollController();
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<int> totalUsersLength = ValueNotifier(usersServerFetchLimit);

  SearchedUsersController(
    this.context,
    this.searchedText
  );

  bool get mounted => context.mounted;
  
  void initializeController(){
    runDelay(() async => fetchSearchedUsers(users.value.length, false, false), actionDelayTime);
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
    scrollController.dispose();
    displayFloatingBtn.dispose();
    users.dispose();
    paginationStatus.dispose();
    totalUsersLength.dispose();
  }

  Future<void> fetchSearchedUsers(int currentUsersLength, bool isRefreshing, bool isPaginating) async{
    if(mounted){
      Map data;
      RequestGet call;
      if(!isPaginating){
        data = {
          'searchedText': searchedText,
          'currentID': appStateRepo.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        };
        call = RequestGet.fetchSearchedUsers;
      }else{
        List paginatedSearchedUsers = await DatabaseHelper().fetchPaginatedSearchedUsers(currentUsersLength, usersPaginationLimit);
        data = {
          'searchedText': searchedText,
          'searchedUsersEncoded': jsonEncode(paginatedSearchedUsers),
          'currentID': appStateRepo.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        };
        call = RequestGet.fetchSearchedUsersPagination;
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
            if(!isPaginating){
              List searchedUsers = res['searchedUsers'];
              await DatabaseHelper().replaceAllSearchedUsers(searchedUsers);
            }
            List userProfileDataList = res['usersProfileData'];
            List usersSocialsDatasList = res['usersSocialsData'];
            if(isRefreshing){
              users.value = [];
            }
            if(!isPaginating){
              totalUsersLength.value = min(res['totalUsersLength'], usersServerFetchLimit);
            }
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              updateUserData(userDataClass);
              updateUserSocials(userDataClass, userSocialClass);
              if(users.value.length < totalUsersLength.value){
                users.value = [...users.value, userProfileData['user_id']];
              }
            }
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
        await fetchSearchedUsers(users.value.length, false, true);
        if(mounted){
          paginationStatus.value = PaginationStatus.loaded;
        }
      });
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchSearchedUsers(0, true, false);
  }
}