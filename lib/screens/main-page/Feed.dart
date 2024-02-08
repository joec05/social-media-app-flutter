import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as d;
import 'package:flutter/material.dart';
import 'package:social_media_app/caching/sqlite_configuration.dart';
import 'package:social_media_app/class/attachment/media_data_class.dart';
import 'package:social_media_app/class/comment/comment_class.dart';
import 'package:social_media_app/class/display/display_comment_data_class.dart';
import 'package:social_media_app/class/display/display_post_data_class.dart';
import 'package:social_media_app/class/post/post_class.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/class/user/user_social_class.dart';
import 'package:social_media_app/constants/app_state_actions.dart';
import 'package:social_media_app/constants/global_enums.dart';
import 'package:social_media_app/constants/global_functions.dart';
import 'package:social_media_app/constants/global_variables.dart';
import 'package:social_media_app/custom/basic-widget/custom_pagination.dart';
import 'package:social_media_app/custom/uploaded-content/custom_comment_widget.dart';
import 'package:social_media_app/custom/uploaded-content/custom_post_widget.dart';
import 'package:social_media_app/mixin/lifecycle_listener.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/streams/comment_data_stream_class.dart';
import 'package:social_media_app/streams/post_data_stream_class.dart';
import 'package:social_media_app/styles/app_styles.dart';

var dio = d.Dio();

class FeedWidget extends StatelessWidget {
  const FeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FeedWidgetStateful();
  }
}

class _FeedWidgetStateful extends StatefulWidget {
  const _FeedWidgetStateful();

  @override
  State<_FeedWidgetStateful> createState() => __FeedWidgetStatefulState();
}

class __FeedWidgetStatefulState extends State<_FeedWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin{
  ValueNotifier<List> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<int> totalPostsLength = ValueNotifier(postsServerFetchLimit);
  late StreamSubscription postDataStreamClassSubscription;
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchFeedPosts(posts.value.length, false, false), actionDelayTime);
    postDataStreamClassSubscription = PostDataStreamClass().postDataStream.listen((PostDataStreamControllerClass data) {
      if(data.uniqueID == appStateClass.currentID && mounted){
        posts.value = [data.postClass, ...posts.value];
      }
    });
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(data.uniqueID == appStateClass.currentID && mounted){
        posts.value = [data.commentClass, ...posts.value]; 
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
    postDataStreamClassSubscription.cancel();
    commentDataStreamClassSubscription.cancel();
    super.dispose();
    posts.dispose();
    paginationStatus.dispose();
    loadingState.dispose();
    totalPostsLength.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchFeedPosts(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        String stringified = '';
        d.Response res;
        if(!isPaginating){
          stringified = jsonEncode({
            'userID': appStateClass.currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchFeed', data: stringified);
        }else{
          List paginatedFeed = await DatabaseHelper().fetchPaginatedFeedPosts(currentPostsLength, postsPaginationLimit);
          stringified = jsonEncode({
            'userID': appStateClass.currentID,
            'feedPostsEncoded': jsonEncode(paginatedFeed),
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchFeedPagination', data: stringified);
        }
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            
            List modifiedFeedPostsData = res.data['modifiedFeedPosts'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass);
                updateUserSocials(userDataClass, userSocialClass);
              }
            }
            if(isRefreshing && mounted){
              posts.value = [];
            }
            if(!isPaginating && mounted){
              totalPostsLength.value = res.data['totalPostsLength'];
            }
            for(int i = 0; i < modifiedFeedPostsData.length; i++){
              if(modifiedFeedPostsData[i]['type'] == 'post'){
                Map postData = modifiedFeedPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                if(mounted){
                  updatePostData(postDataClass);
                  posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
                }
              }else{
                Map commentData = modifiedFeedPostsData[i];
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
            if(!isPaginating){
              List feedPosts = res.data['feedPosts'];
              await DatabaseHelper().replaceFeedPosts(feedPosts);
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

  Future<void> loadMorePosts() async{
    try {
      if(mounted){
        loadingState.value = LoadingState.paginating;
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchFeedPosts(posts.value.length, false, true);
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
    await fetchFeedPosts(0, true, false);
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
              ListView.builder(
                itemCount: postsPaginationLimit,
                itemBuilder: (context, index) {
                  return CustomPostWidget(
                    postData: PostClass.getFakeData(), 
                    senderData: UserDataClass.getFakeData(),
                    senderSocials: UserSocialClass.getFakeData(),
                    pageDisplayType: PostDisplayType.feed,
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
                valueListenable: totalPostsLength,
                builder: (context, totalPostsLengthValue, child){
                  return ValueListenableBuilder(
                    valueListenable: posts,
                    builder: ((context, posts, child) {
                      return LoadMoreBottom(
                        addBottomSpace: true,
                        loadMore: () async{
                          if(totalPostsLengthValue > posts.length){
                            await loadMorePosts();
                          }
                        },
                        status: loadingStatusValue,
                        refresh: refresh,
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
                                                  pageDisplayType: PostDisplayType.feed,
                                                  skeletonMode: false,
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
                                                  pageDisplayType: CommentDisplayType.feed,
                                                  skeletonMode: false,
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
