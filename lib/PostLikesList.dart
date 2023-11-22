// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserDataNotifier.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/class/UserSocialNotifier.dart';
import 'package:social_media_app/custom/CustomUserDataWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/redux/reduxLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'custom/CustomPagination.dart';
import 'streams/UserDataStreamClass.dart';

class PostLikesListWidget extends StatelessWidget {
  final String postID;
  final String postSender;
  const PostLikesListWidget({super.key, required this.postID, required this.postSender});

  @override
  Widget build(BuildContext context) {
    return _PostLikesListWidgetStateful(postID: postID, postSender: postSender);
  }
}

class _PostLikesListWidgetStateful extends StatefulWidget {
  final String postID;
  final String postSender;
  const _PostLikesListWidgetStateful({required this.postID, required this.postSender});

  @override
  State<_PostLikesListWidgetStateful> createState() => _PostLikesListWidgetStatefulState();
}

var dio = Dio();

class _PostLikesListWidgetStatefulState extends State<_PostLikesListWidgetStateful> with LifecycleListenerMixin{
  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(true);
  late String postID;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingUsersStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription userDataStreamClassSubscription;

  @override
  void initState(){
    super.initState();
    postID = widget.postID;
    fetchPostLikes(users.value.length, false);
    userDataStreamClassSubscription = UserDataStreamClass().userDataStream.listen((UserDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == postID && data.actionType.name == UserDataStreamsUpdateType.addPostLikes.name){
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
    isLoading.dispose();
    users.dispose();
    loadingUsersStatus.dispose();
    canPaginate.dispose();
  }

  Future<void> fetchPostLikes(int currentUsersLength, bool isRefreshing) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'postID': postID,
          'currentID': fetchReduxDatabase().currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchPostLikes', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List followersProfileDatasList = res.data['usersProfileData'];
            List followersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              users.value = [];
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
            for(int i = 0; i < followersProfileDatasList.length; i++){
              Map userProfileData = followersProfileDatasList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(followersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass, context);
                updateUserSocials(userDataClass, userSocialClass, context);
                users.value = [userProfileData['user_id'], ...users.value];
              }
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
          await fetchPostLikes(users.value.length, false);
          if(mounted){
            loadingUsersStatus.value = LoadingStatus.loaded;
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
        title: const Text('Users'), 
        titleSpacing: defaultAppBarTitleSpacing,
        flexibleSpace: Container(
          decoration: defaultAppBarDecoration
        )
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Builder(
              builder: (BuildContext context) {
                return StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
                  converter: (store) => store.state.usersDatasNotifiers,
                  builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
                    return StoreConnector<AppState, ValueNotifier<Map<String, UserSocialNotifier>>>(
                      converter: (store) => store.state.usersSocialsNotifiers,
                      builder: (context, ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers){
                        return ValueListenableBuilder(
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
                                        if(canPaginate.value){
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
                                              if(fetchReduxDatabase().usersDatasNotifiers.value[users[index]] != null){
                                                return ValueListenableBuilder(
                                                  valueListenable: fetchReduxDatabase().usersDatasNotifiers.value[users[index]]!.notifier, 
                                                  builder: ((context, userData, child) {
                                                    return ValueListenableBuilder(
                                                      valueListenable: fetchReduxDatabase().usersSocialsNotifiers.value[users[index]]!.notifier, 
                                                      builder: ((context, userSocial, child) {
                                                        return ValueListenableBuilder(
                                                          valueListenable: fetchReduxDatabase().postsNotifiers.value[widget.postSender]![widget.postID]!.notifier, 
                                                          builder: ((context, postData, child) {
                                                            return CustomUserDataWidget(
                                                              userData: userData,
                                                              userSocials: userSocial,
                                                              userDisplayType: UserDisplayType.likes,
                                                              profilePageUserID: null,
                                                              isLiked: postData.likedByCurrentID,
                                                              isBookmarked: null,
                                                              key: UniqueKey()
                                                            );
                                                          })
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
                      }
                    );
                  }
                );
              }
            )
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
        ]
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