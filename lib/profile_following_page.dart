import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/user_data_class.dart';
import 'package:social_media_app/class/user_social_class.dart';
import 'package:social_media_app/mixin/lifecycle_listener_mixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/appdata/global_library.dart';
import 'custom/custom_pagination.dart';
import 'custom/custom_user_data_widget.dart';
import 'streams/user_data_stream_class.dart';

class ProfilePageFollowingWidget extends StatelessWidget {
  final String userID;
  const ProfilePageFollowingWidget({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageFollowingWidgetStateful(userID: userID);
  }
}

class _ProfilePageFollowingWidgetStateful extends StatefulWidget {
  final String userID;
  const _ProfilePageFollowingWidgetStateful({required this.userID});

  @override
  State<_ProfilePageFollowingWidgetStateful> createState() => _ProfilePageFollowingWidgetStatefulState();
}

var dio = Dio();

class _ProfilePageFollowingWidgetStatefulState extends State<_ProfilePageFollowingWidgetStateful> with LifecycleListenerMixin{
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(true);
  late String userID;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription userDataStreamClassSubscription;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    runDelay(() async => fetchProfileFollowing(users.value.length, false), actionDelayTime);
    userDataStreamClassSubscription = UserDataStreamClass().userDataStream.listen((UserDataStreamControllerClass data) {
      if(data.uniqueID == userID && data.actionType.name == UserDataStreamsUpdateType.addFollowing.name){
        if(mounted){
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

  @override void dispose(){
    userDataStreamClassSubscription.cancel();
    super.dispose();
    _scrollController.dispose();
    displayFloatingBtn.dispose();
    loadingState.dispose();
    users.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
  }

  Future<void> fetchProfileFollowing(int currentUsersLength, bool isRefreshing) async{
    try {
      if(mounted){
        String stringified = jsonEncode({
          'userID': userID,
          'currentID': appStateClass.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserProfileFollowing', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List userProfileDataList = res.data['usersProfileData'];
            List followingSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              users.value = [];
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(followingSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
                users.value = [userProfileData['user_id'], ...users.value];
              }
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
          await fetchProfileFollowing(users.value.length, false);
          if(mounted){
            paginationStatus.value = PaginationStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('Following'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: ValueListenableBuilder(
        valueListenable: loadingState,
        builder: ((context, loadingStateValue, child) {
          if(shouldCallSkeleton(loadingStateValue)){
            return shimmerSkeletonWidget(
              ListView.builder(
                itemCount: usersPaginationLimit,
                itemBuilder: (context, index) {
                  return CustomUserDataWidget(
                    userData: UserDataClass.getFakeData(), 
                    userSocials: UserSocialClass.getFakeData(), 
                    userDisplayType: UserDisplayType.following,
                    profilePageUserID: userID,
                    isLiked: null,
                    isBookmarked: null,
                    skeletonMode: true,
                    key: UniqueKey()
                  );
                }
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
                        refresh: null,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
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
                                          return CustomUserDataWidget(
                                            userData: userData,
                                            userSocials: userSocial,
                                            userDisplayType: UserDisplayType.following,
                                            profilePageUserID: userID,
                                            isLiked: null,
                                            isBookmarked: null,
                                            key: UniqueKey(),
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
        }),
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
}