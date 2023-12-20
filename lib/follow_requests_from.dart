import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/user_data_class.dart';
import 'package:social_media_app/class/user_social_class.dart';
import 'package:social_media_app/custom/custom_follow_request_widget.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/streams/requests_from_data_stream_class.dart';
import 'package:social_media_app/appdata/global_library.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'custom/custom_pagination.dart';

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
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
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
        if(data.uniqueID == 'send_follow_request_${appStateClass.currentID}'){
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
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
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
      doSomethingWithException(e);
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
      doSomethingWithException(e);
    }
  }

  Future<void> refresh() async{
    loadingState.value = LoadingState.refreshing;
    fetchFollowRequestsFrom(0, true, false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: loadingState,
        builder: ((context, loadingStateValue, child) {
          if(shouldCallSkeleton(loadingStateValue)){
            return shimmerSkeletonWidget(
              CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                  ),
                  SliverList(delegate: SliverChildBuilderDelegate(
                    childCount: followRequestsPaginationLimit, 
                    (context, index) {
                      return CustomFollowRequestWidget(
                        userData: UserDataClass.getFakeData(), 
                        userSocials: UserSocialClass.getFakeData(), 
                        followRequestType: FollowRequestType.from,
                        skeletonMode: true,
                        key: UniqueKey()
                      );
                    }
                  ))
                ]
              )
            ); 
          }
          return ValueListenableBuilder(
            valueListenable: paginationStatus,
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
                                if(appStateClass.usersDataNotifiers.value[users[index]] != null){
                                  return ValueListenableBuilder(
                                    valueListenable: appStateClass.usersDataNotifiers.value[users[index]]!.notifier, 
                                    builder: ((context, userData, child) {
                                      return ValueListenableBuilder(
                                        valueListenable: appStateClass.usersSocialsNotifiers.value[users[index]]!.notifier, 
                                        builder: ((context, userSocial, child) {
                                          return CustomFollowRequestWidget(
                                            userData: userData, userSocials: userSocial,
                                            key: UniqueKey(), followRequestType: FollowRequestType.from,
                                            skeletonMode: false,
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
          );
        })
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