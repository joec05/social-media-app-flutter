// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomFollowRequestWidget.dart';
import 'package:social_media_app/streams/RequestsFromDataStreamClass.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'custom/CustomPagination.dart';

var dio = Dio();

class FollowRequestsFromWidget extends StatelessWidget {
  final BuildContext absorberContext;
  const FollowRequestsFromWidget({super.key, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _FollowRequestsFromWidgetStateful(absorberContext: absorberContext);
  }
}

class _FollowRequestsFromWidgetStateful extends StatefulWidget {
  final BuildContext absorberContext;
  const _FollowRequestsFromWidgetStateful({required this.absorberContext});

  @override
  State<_FollowRequestsFromWidgetStateful> createState() => _FollowRequestsFromWidgetStatefulState();
}



class _FollowRequestsFromWidgetStatefulState extends State<_FollowRequestsFromWidgetStateful> with AutomaticKeepAliveClientMixin{
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingUsersStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription requestsFromDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchFollowRequestsFrom(users.value.length, false, false), actionDelayTime);
    requestsFromDataStreamClassSubscription = RequestsFromDataStreamClass().requestsFromDataStream.listen((RequestsFromDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == 'send_follow_request_${fetchReduxDatabase().currentID}'){
          if(!users.value.contains(data.userID)){
            users.value = [data.userID, ...users.value];
          }
        }
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

  @override
  void dispose(){
    requestsFromDataStreamClassSubscription.cancel();
    super.dispose();
    isLoading.dispose();
    users.dispose();
    loadingUsersStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchFollowRequestsFrom(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'currentID': fetchReduxDatabase().currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': postsPaginationLimit,
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
          await fetchFollowRequestsFrom(users.value.length, false, true);
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
    fetchFollowRequestsFrom(0, true, false);
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
                                if(fetchReduxDatabase().usersDatasNotifiers.value[users[index]] != null){
                                  return ValueListenableBuilder(
                                    valueListenable: fetchReduxDatabase().usersDatasNotifiers.value[users[index]]!.notifier, 
                                    builder: ((context, userData, child) {
                                      return ValueListenableBuilder(
                                        valueListenable: fetchReduxDatabase().usersSocialsNotifiers.value[users[index]]!.notifier, 
                                        builder: ((context, userSocial, child) {
                                          return CustomFollowRequestWidget(
                                            userData: userData, userSocials: userSocial,
                                            key: UniqueKey(), followRequestType: FollowRequestType.From,
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