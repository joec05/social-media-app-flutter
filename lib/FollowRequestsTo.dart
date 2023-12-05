// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomFollowRequestWidget.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'custom/CustomPagination.dart';
import 'streams/RequestsToDataStreamClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';

var dio = Dio();

class FollowRequestsToWidget extends StatelessWidget {
  final BuildContext absorberContext;
  const FollowRequestsToWidget({super.key, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _FollowRequestsToWidgetStateful(absorberContext: absorberContext);
  }
}

class _FollowRequestsToWidgetStateful extends StatefulWidget {
  final BuildContext absorberContext;
  const _FollowRequestsToWidgetStateful({required this.absorberContext});

  @override
  State<_FollowRequestsToWidgetStateful> createState() => _FollowRequestsToWidgetStatefulState();
}



class _FollowRequestsToWidgetStatefulState extends State<_FollowRequestsToWidgetStateful> with AutomaticKeepAliveClientMixin{
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingUsersStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription requestsToDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchFollowRequestsTo(users.value.length, false, false), actionDelayTime);
    requestsToDataStreamClassSubscription = RequestsToDataStreamClass().requestsToDataStream.listen((RequestsToDataStreamControllerClass data) {
      if(data.uniqueID == 'unlock_account_${appStateClass.currentID}' && mounted){
        List<String> usersIdList = [...users.value];
        users.value = [];
        for(int i = 0; i < usersIdList.length; i++){
          String userID = usersIdList[i];
          acceptFollowRequest(userID);
        }
        UserSocialClass currentUserSocialClass = appStateClass.usersSocialsNotifiers.value[appStateClass.currentID]!.notifier.value;
        appStateClass.usersSocialsNotifiers.value[appStateClass.currentID]!.notifier.value = UserSocialClass(
          currentUserSocialClass.followersCount + usersIdList.length, currentUserSocialClass.followingCount, 
          false, false
        );
      }
    });
    _scrollController.addListener(() {
      if(mounted){
        if(_scrollController.position.pixels > animateToTopMinHeight){
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

  @override void dispose(){
    requestsToDataStreamClassSubscription.cancel();
    super.dispose();
    isLoading.dispose();
    users.dispose();
    loadingUsersStatus.dispose();
    canPaginate.dispose();
  }

  Future<void> fetchFollowRequestsTo(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'currentID': appStateClass.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        }); 
        var res = await dio.get('$serverDomainAddress/users/fetchFollowRequestsToUser', data: stringified);
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
                updateUserData(userDataClass, context);
                updateUserSocials(userDataClass, userSocialClass, context);
                users.value = [...users.value, userProfileData['user_id']];
              }
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
          }
          if(mounted){
            isLoading.value = false;
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> loadMoreUsers() async{
    try {
      if(mounted){
        loadingUsersStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchFollowRequestsTo(users.value.length, false, true);
          if(mounted){
            loadingUsersStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> refresh() async{
    fetchFollowRequestsTo(0, true, false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          ValueListenableBuilder(
            valueListenable: loadingUsersStatus,
            builder: (context, loadingStatusValue, child){
              return ValueListenableBuilder(
                valueListenable: canPaginate,
                builder: (context, canPaginateValue, child){
                  return ValueListenableBuilder(
                    valueListenable: users, 
                    builder: ((context, users, child) {
                      return LoadMoreBottom(
                        addBottomSpace: canPaginateValue,
                        loadMore: () async{
                          if(canPaginateValue){
                            await loadMoreUsers();
                          }else{
                          }
                        },
                        status: loadingStatusValue,
                        refresh: refresh,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            SliverOverlapInjector(
                              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                            ),
                            SliverList(delegate: SliverChildBuilderDelegate(
                              childCount: users.length, 
                              (context, index) {
                                if(appStateClass.usersDataNotifiers.value[users[index]] != null){
                                  return ValueListenableBuilder(
                                    valueListenable: appStateClass.usersDataNotifiers.value[users[index]]!.notifier, 
                                    builder: ((context, userData, child) {
                                      return ValueListenableBuilder(
                                        valueListenable: appStateClass.usersSocialsNotifiers.value[users[index]]!.notifier, 
                                        builder: ((context, userSocial, child) {
                                          return CustomFollowRequestWidget(
                                            userData: userData, userSocials: userSocial,
                                            key: UniqueKey(), followRequestType: FollowRequestType.To,
                                          );
                                        })
                                      );
                                    })
                                  );
                                }
                                return Container();
                              }
                            ))
                          ]
                        )
                      );
                    })
                  );
                }
              );
            }
          ),
          ValueListenableBuilder(
            valueListenable: isLoading,
            builder: ((context, isLoadingValue, child) {
              if(isLoadingValue){
                return loadingPageWidget();
              }
              return Container();
            })
          )
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 10),
                  curve:Curves.fastOutSlowIn
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          );
        }
      )
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}