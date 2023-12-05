// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomUserDataWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'custom/CustomPagination.dart';
import 'streams/UserDataStreamClass.dart';

class CommentBookmarksListWidget extends StatelessWidget {
  final String commentID;
  final String commentSender;
  const CommentBookmarksListWidget({super.key, required this.commentID, required this.commentSender});

  @override
  Widget build(BuildContext context) {
    return _CommentBookmarksListWidgetStateful(commentID: commentID, commentSender: commentSender);
  }
}

class _CommentBookmarksListWidgetStateful extends StatefulWidget {
  final String commentID;
  final String commentSender;
  const _CommentBookmarksListWidgetStateful({required this.commentID, required this.commentSender});

  @override
  State<_CommentBookmarksListWidgetStateful> createState() => _CommentBookmarksListWidgetStatefulState();
}

var dio = Dio();

class _CommentBookmarksListWidgetStatefulState extends State<_CommentBookmarksListWidgetStateful> with LifecycleListenerMixin{
  late String commentID;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<String>> users = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingUsersStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription userDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    commentID = widget.commentID;
    runDelay(() async => fetchCommentsBookmarks(users.value.length, false), actionDelayTime);
    userDataStreamClassSubscription = UserDataStreamClass().userDataStream.listen((UserDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == commentID && data.actionType.name == UserDataStreamsUpdateType.addCommentBookmarks.name){
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
    isLoading.dispose();
    users.dispose();
    loadingUsersStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchCommentsBookmarks(int currentUsersLength, bool isRefreshing) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'commentID': commentID,
          'currentID': appStateClass.currentID,
          'currentLength': currentUsersLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': usersServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchCommentBookmarks', data: stringified);
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
          await fetchCommentsBookmarks(users.value.length, false);
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
        leading: defaultLeadingWidget(context),
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
                                                return ValueListenableBuilder(
                                                  valueListenable: appStateClass.commentsNotifiers.value[widget.commentSender]![widget.commentID]!.notifier, 
                                                  builder: ((context, commentData, child) {
                                                    return CustomUserDataWidget(
                                                      userData: userData,
                                                      userSocials: userSocial,
                                                      userDisplayType: UserDisplayType.bookmarks,
                                                      isLiked: null,
                                                      isBookmarked: commentData.bookmarkedByCurrentID,
                                                      profilePageUserID: null,
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