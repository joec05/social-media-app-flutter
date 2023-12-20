import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/media_data_class.dart';
import 'package:social_media_app/class/user_data_class.dart';
import 'package:social_media_app/class/user_social_class.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/streams/bookmark_data_stream_class.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/appdata/global_library.dart';
import 'class/comment_class.dart';
import 'class/display_comment_data_class.dart';
import 'class/display_post_data_class.dart';
import 'class/post_class.dart';
import 'custom/custom_comment_widget.dart';
import 'custom/custom_pagination.dart';
import 'custom/custom_post_widget.dart';

var dio = Dio();

class ProfilePageBookmarksWidget extends StatelessWidget {
  final String userID;
  const ProfilePageBookmarksWidget({super.key, required this.userID});

  @override
  Widget build(BuildContext context) {
    return _ProfilePageBookmarksWidgetStateful(userID: userID);
  }
}

class _ProfilePageBookmarksWidgetStateful extends StatefulWidget {
  final String userID;
  const _ProfilePageBookmarksWidgetStateful({required this.userID});

  @override
  State<_ProfilePageBookmarksWidgetStateful> createState() => _ProfilePageBookmarksWidgetStatefulState();
}

class _ProfilePageBookmarksWidgetStatefulState extends State<_ProfilePageBookmarksWidgetStateful>{
  late String userID;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription bookmarkDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    runDelay(() async => fetchProfileBookmarks(posts.value.length, false), actionDelayTime);
    bookmarkDataStreamClassSubscription = BookmarkDataStreamClass().bookmarkDataStream.listen((BookmarkDataStreamControllerClass data) {
      if(data.uniqueID == 'add_bookmarks_${appStateClass.currentID}'){
        var postClass = data.postClass;
        String bookmarkedID = postClass is DisplayPostDataClass ? postClass.postID : postClass.commentID;
        bool isExistsInList = posts.value.where((e) => e is DisplayPostDataClass ? e.postID == bookmarkedID : e.commentID == bookmarkedID).toList().isNotEmpty;
        if(!isExistsInList && mounted){
          posts.value = [postClass, ...posts.value];
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
    bookmarkDataStreamClassSubscription.cancel();
    super.dispose();
    loadingState.dispose();
    posts.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchProfileBookmarks(int currentBookmarksLength, bool isRefreshing) async{
    try {
      if(mounted){
        String stringified = jsonEncode({
          'userID': userID,
          'currentID': appStateClass.currentID,
          'currentLength': currentBookmarksLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': postsServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserBookmarks', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List userBookmarksData = res.data['userBookmarksData'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              posts.value = [];
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
            for(int i = 0; i < userBookmarksData.length; i++){
              if(userBookmarksData[i]['type'] == 'post'){
                Map postData = userBookmarksData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                if(mounted){
                  updatePostData(postDataClass);
                  posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
                }
              }else{
                Map commentData = userBookmarksData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                if(mounted){
                  updateCommentData(commentDataClass);
                  posts.value = [...posts.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
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
      doSomethingWithException(e);
    }
  }

  Future<void> loadMoreBookmarks() async{
    try {
      if(mounted){
        loadingState.value = LoadingState.paginating;
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchProfileBookmarks(posts.value.length, false);
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
        title: const Text('Bookmarks'), 
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
                itemCount: postsPaginationLimit,
                itemBuilder: (context, index){
                  return CustomPostWidget(
                    postData: PostClass.getFakeData(),
                    senderData: UserDataClass.getFakeData(), 
                    senderSocials: UserSocialClass.getFakeData(), 
                    pageDisplayType: PostDisplayType.bookmark,
                    skeletonMode: true,
                  );
                }
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
                              valueListenable: posts,
                              builder: ((context, posts, child) {
                                return LoadMoreBottom(
                                  addBottomSpace: canPaginateValue,
                                  loadMore: () async{
                                    if(canPaginateValue){
                                      await loadMoreBookmarks();
                                    }
                                  },
                                  status: loadingStatusValue,
                                  refresh: null,
                                  child: CustomScrollView(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    slivers: <Widget>[
                                      SliverList(delegate: SliverChildBuilderDelegate(
                                        childCount: posts.length, 
                                        (context, index) {
                                          if(posts[index] is DisplayPostDataClass){
                                            if(appStateClass.postsNotifiers.value[posts[index].sender] == null){
                                              return Container();
                                            }
                                            if(appStateClass.postsNotifiers.value[posts[index].sender]![posts[index].postID] == null){
                                              return Container();
                                            }
                                            return ValueListenableBuilder<PostClass>(
                                              valueListenable: appStateClass.postsNotifiers.value[posts[index].sender]![posts[index].postID]!.notifier,
                                              builder: ((context, postData, child) {
                                                return ValueListenableBuilder(
                                                  valueListenable: appStateClass.usersDataNotifiers.value[posts[index].sender]!.notifier, 
                                                  builder: ((context, userData, child) {
                                                    if(!postData.deleted){
                                                      return ValueListenableBuilder(
                                                        valueListenable: appStateClass.usersSocialsNotifiers.value[posts[index].sender]!.notifier, 
                                                        builder: ((context, userSocials, child) {
                                                          return CustomPostWidget(
                                                            postData: postData, 
                                                            senderData: userData,
                                                            senderSocials: userSocials,
                                                            pageDisplayType: PostDisplayType.bookmark,
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
                                          }else{
                                            if(appStateClass.commentsNotifiers.value[posts[index].sender] == null){
                                              return Container();
                                            }
                                            if(appStateClass.commentsNotifiers.value[posts[index].sender]![posts[index].commentID] == null){
                                              return Container();
                                            }
                                            return ValueListenableBuilder<CommentClass>(
                                              valueListenable: appStateClass.commentsNotifiers.value[posts[index].sender]![posts[index].commentID]!.notifier,
                                              builder: ((context, commentData, child) {
                                                return ValueListenableBuilder(
                                                  valueListenable: appStateClass.usersDataNotifiers.value[posts[index].sender]!.notifier, 
                                                  builder: ((context, userData, child) {
                                                    if(!commentData.deleted){
                                                      return ValueListenableBuilder(
                                                        valueListenable: appStateClass.usersSocialsNotifiers.value[posts[index].sender]!.notifier, 
                                                        builder: ((context, userSocials, child) {
                                                          return CustomCommentWidget(
                                                            commentData: commentData, 
                                                            senderData: userData,
                                                            senderSocials: userSocials,
                                                            pageDisplayType: CommentDisplayType.bookmark,
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
}
