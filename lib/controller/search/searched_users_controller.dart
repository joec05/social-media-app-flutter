import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
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
    try {
      if(mounted){
        String stringified = '';
        Response res;
        if(!isPaginating){
          stringified = jsonEncode({
            'searchedText': searchedText,
            'currentID': appStateClass.currentID,
            'currentLength': currentUsersLength,
            'paginationLimit': usersPaginationLimit,
            'maxFetchLimit': usersServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedUsers', data: stringified);
        }else{
          List paginatedSearchedUsers = await DatabaseHelper().fetchPaginatedSearchedUsers(currentUsersLength, usersPaginationLimit);
          stringified = jsonEncode({
            'searchedText': searchedText,
            'searchedUsersEncoded': jsonEncode(paginatedSearchedUsers),
            'currentID': appStateClass.currentID,
            'currentLength': currentUsersLength,
            'paginationLimit': usersPaginationLimit,
            'maxFetchLimit': usersServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedUsersPagination', data: stringified);
        }
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            if(!isPaginating){
              List searchedUsers = res.data['searchedUsers'];
              await DatabaseHelper().replaceAllSearchedUsers(searchedUsers);
            }
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              users.value = [];
            }
            if(!isPaginating && mounted){
              totalUsersLength.value = min(res.data['totalUsersLength'], usersServerFetchLimit);
            }
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
                if(users.value.length < totalUsersLength.value){
                  users.value = [...users.value, userProfileData['user_id']];
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

  Future<void> loadMoreUsers() async{
    try {
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
    } on Exception catch (e) {
      
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchSearchedUsers(0, true, false);
  }
}