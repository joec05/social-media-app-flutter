// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/DisplayCommentDataClass.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomCommentWidget.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'class/CommentClass.dart';
import 'custom/CustomPagination.dart';
import 'streams/CommentDataStreamClass.dart';

class ProfilePageRepliesWidget extends StatelessWidget {
  final String userID;
  final BuildContext absorberContext;
  const ProfilePageRepliesWidget({super.key, required this.userID, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageRepliesWidgetStateful(userID: userID, absorberContext: absorberContext);
  }
}

class _ProfilePageRepliesWidgetStateful extends StatefulWidget {
  final String userID;
  final BuildContext absorberContext;
  const _ProfilePageRepliesWidgetStateful({required this.userID, required this.absorberContext});

  @override
  State<_ProfilePageRepliesWidgetStateful> createState() => _ProfilePageRepliesWidgetStatefulState();
}

var dio = Dio();

class _ProfilePageRepliesWidgetStatefulState extends State<_ProfilePageRepliesWidgetStateful> with AutomaticKeepAliveClientMixin{
  late String userID;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingCommentsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    runDelay(() async => fetchProfileReplies(comments.value.length, false), actionDelayTime);
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(data.uniqueID == appStateClass.currentID && mounted){
        comments.value = [data.commentClass, ...comments.value];
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
    commentDataStreamClassSubscription.cancel();
    super.dispose();
    isLoading.dispose();
    comments.dispose();
    loadingCommentsStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchProfileReplies(int currentCommentsLength, bool isRefreshing) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'userID': userID,
          'currentID': appStateClass.currentID,
          'currentLength': currentCommentsLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': postsServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserComments', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List userCommentsData = res.data['userCommentsData'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              comments.value = [];
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass, context);
                updateUserSocials(userDataClass, userSocialClass, context);
              }
            }
            for(int i = 0; i < userCommentsData.length; i++){
              Map commentData = userCommentsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
              CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
              if(mounted){
                updateCommentData(commentDataClass, context);
                comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
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

  Future<void> loadMoreComments() async{
    try {
      if(mounted){
        loadingCommentsStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchProfileReplies(comments.value.length, false);
          if(mounted){
            loadingCommentsStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Builder(
              builder: (BuildContext context) {
                return ValueListenableBuilder(
                  valueListenable: loadingCommentsStatus,
                  builder: (context, loadingStatusValue, child){
                    if(appStateClass.usersDataNotifiers.value[userID] != null){
                      return ValueListenableBuilder(
                        valueListenable: appStateClass.usersDataNotifiers.value[userID]!.notifier, 
                        builder: ((context, profilePageUserData, child) {
                          if(profilePageUserData.blocksCurrentID){
                            return Container();
                          }
                          return ValueListenableBuilder(
                            valueListenable: appStateClass.usersSocialsNotifiers.value[userID]!.notifier, 
                            builder: ((context, profilePageUserSocials, child) {
                              if(profilePageUserData.private && !profilePageUserSocials.followedByCurrentID && userID != appStateClass.currentID){
                                return Container();
                              }
                              return ValueListenableBuilder(
                                valueListenable: canPaginate,
                                builder: (context, canPaginateValue, child){
                                  return ValueListenableBuilder(
                                    valueListenable: comments,
                                    builder: ((context, comments, child) {
                                      return LoadMoreBottom(
                                        addBottomSpace: canPaginateValue,
                                        loadMore: () async{
                                          if(canPaginateValue){
                                            await loadMoreComments();
                                          }
                                        },
                                        status: loadingStatusValue,
                                        refresh: null,
                                        child: CustomScrollView(
                                          controller: _scrollController,
                                          primary: false,
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          slivers: <Widget>[
                                            SliverOverlapInjector(
                                              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)
                                            ),
                                            SliverList(delegate: SliverChildBuilderDelegate(
                                              addAutomaticKeepAlives: true,
                                              childCount: comments.length, 
                                              (context, index) {
                                                if(appStateClass.commentsNotifiers.value[comments[index].sender] == null){
                                                  return Container();
                                                }
                                                if(appStateClass.commentsNotifiers.value[comments[index].sender]![comments[index].commentID] == null){
                                                  return Container();
                                                }
                                                return ValueListenableBuilder<CommentClass>(
                                                  valueListenable: appStateClass.commentsNotifiers.value[comments[index].sender]![comments[index].commentID]!.notifier,
                                                  builder: ((context, commentData, child) {
                                                    return ValueListenableBuilder(
                                                      valueListenable: appStateClass.usersDataNotifiers.value[comments[index].sender]!.notifier, 
                                                      builder: ((context, userData, child) {
                                                        if(!commentData.deleted){
                                                          if(userData.blocksCurrentID){
                                                            return Container();
                                                          }
                                                          return ValueListenableBuilder(
                                                            valueListenable: appStateClass.usersSocialsNotifiers.value[comments[index].sender]!.notifier, 
                                                            builder: ((context, userSocials, child) {
                                                              if(userData.private && !userSocials.followedByCurrentID && userData.userID != appStateClass.currentID){
                                                                return Container();
                                                              }
                                                              return CustomCommentWidget(
                                                                commentData: commentData, 
                                                                senderData: userData,
                                                                senderSocials: userSocials,
                                                                pageDisplayType: CommentDisplayType.profileComment,
                                                                key: UniqueKey()
                                                              );
                                                            })
                                                          );
                                                        }
                                                        return Container();
                                                      })
                                                    );
                                                  }),
                                                );
                                              }
                                            ))                                    
                                          ]
                                        )
                                      );
                                    })
                                  );
                                }
                              );
                            })
                          );
                        })
                      );
                    }
                    return Container();
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
  
  @override
  bool get wantKeepAlive => true;
}
