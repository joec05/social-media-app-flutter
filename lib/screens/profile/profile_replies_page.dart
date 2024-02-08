import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/attachment/media_data_class.dart';
import 'package:social_media_app/class/comment/comment_class.dart';
import 'package:social_media_app/class/display/display_comment_data_class.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/class/user/user_social_class.dart';
import 'package:social_media_app/constants/app_state_actions.dart';
import 'package:social_media_app/constants/global_enums.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/basic-widget/custom_pagination.dart';
import 'package:social_media_app/custom/uploaded-content/custom_comment_widget.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/streams/comment_data_stream_class.dart';
import 'package:social_media_app/styles/app_styles.dart';

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
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
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
    loadingState.dispose();
    comments.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchProfileReplies(int currentCommentsLength, bool isRefreshing) async{
    try {
      if(mounted){
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
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
            }
            for(int i = 0; i < userCommentsData.length; i++){
              Map commentData = userCommentsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
              CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
              if(mounted){
                updateCommentData(commentDataClass);
                comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
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

  Future<void> loadMoreComments() async{
    try {
      if(mounted){
        loadingState.value = LoadingState.paginating;
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchProfileReplies(comments.value.length, false);
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
                    childCount: postsPaginationLimit, 
                    (context, index) {
                      return CustomCommentWidget(
                        commentData: CommentClass.getFakeData(), 
                        senderData: UserDataClass.getFakeData(),
                        senderSocials: UserSocialClass.getFakeData(),
                        pageDisplayType: CommentDisplayType.profileComment,
                        key: UniqueKey(),
                        skeletonMode: true,
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
                                                          key: UniqueKey(),
                                                          skeletonMode: false,
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
