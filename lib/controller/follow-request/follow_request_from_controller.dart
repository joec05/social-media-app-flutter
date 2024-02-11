import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class FollowRequestFromController {
  BuildContext context;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  StreamSubscription? requestsFromDataStreamClassSubscription;
  StreamSubscription? requestsToDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();

  FollowRequestFromController(
    this.context
  );

  bool get mounted => context.mounted;

  void initializeController(){
    runDelay(() async => fetchFollowRequestsFrom(users.value.length, false, false), actionDelayTime);
    requestsFromDataStreamClassSubscription = RequestsFromDataStreamClass().requestsFromDataStream.listen((RequestsFromDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == 'send_follow_request_${appStateClass.currentID}'){
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
    if(requestsFromDataStreamClassSubscription != null){
      requestsFromDataStreamClassSubscription!.cancel();
    }
    if(requestsToDataStreamClassSubscription != null){
      requestsToDataStreamClassSubscription!.cancel();
    }
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    scrollController.dispose();
  }

  Future<void> fetchFollowRequestsFrom(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        String stringified = jsonEncode({
          'currentID': appStateClass.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': followRequestsPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        }); 
        var res = await dio.get('$serverDomainAddress/users/fetchFollowRequestsFromUser', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List usersProfileDataList = res.data['usersProfileData'];
            List usersSocialsDataList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              users.value = [];
            }
            for(int i = 0; i < usersProfileDataList.length; i++){
              Map userProfileData = usersProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDataList[i]);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
                users.value = [...users.value, userProfileData['user_id']];
              }
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
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
          await fetchFollowRequestsFrom(users.value.length, false, true);
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
    fetchFollowRequestsFrom(0, true, false);
  }
}