import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/class/attachment/media_data_class.dart';
import 'package:social_media_app/class/display/display_post_data_class.dart';
import 'package:social_media_app/class/post/post_class.dart';
import 'package:social_media_app/class/user/user_data_class.dart';
import 'package:social_media_app/class/user/user_social_class.dart';
import 'package:social_media_app/custom/basic-widget/custom_pagination.dart';
import 'package:social_media_app/custom/uploaded-content/custom_post_widget.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/constants/global_library.dart';
import 'package:social_media_app/streams/post_data_stream_class.dart';
import 'package:social_media_app/styles/app_styles.dart';

var dio = Dio();

class ProfilePagePostsWidget extends StatelessWidget {
  final String userID;
  final BuildContext absorberContext;
  const ProfilePagePostsWidget({super.key, required this.userID, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _ProfilePagePostsWidgetStateful(userID: userID, absorberContext: absorberContext);
  }
}

class _ProfilePagePostsWidgetStateful extends StatefulWidget {
  final String userID;
  final BuildContext absorberContext;
  const _ProfilePagePostsWidgetStateful({required this.userID, required this.absorberContext});

  @override
  State<_ProfilePagePostsWidgetStateful> createState() => _ProfilePagePostsWidgetStatefulState();
}

class _ProfilePagePostsWidgetStatefulState extends State<_ProfilePagePostsWidgetStateful> with AutomaticKeepAliveClientMixin{
  late String userID;
  ValueNotifier<LoadingState> loadingState = ValueNotifier(LoadingState.loading);
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);
  ValueNotifier<PaginationStatus> paginationStatus = ValueNotifier(PaginationStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  late StreamSubscription postDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    runDelay(() async => fetchProfilePosts(posts.value.length, false), actionDelayTime);
    postDataStreamClassSubscription = PostDataStreamClass().postDataStream.listen((PostDataStreamControllerClass data) {
      if(data.uniqueID == appStateClass.currentID && mounted){
        posts.value = [data.postClass, ...posts.value];
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

  @override void dispose() async{
    postDataStreamClassSubscription.cancel();
    super.dispose();
    loadingState.dispose();
    posts.dispose();
    paginationStatus.dispose();
    canPaginate.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchProfilePosts(int currentPostsLength, bool isRefreshing) async{
    try {
      if(mounted){
        String stringified = jsonEncode({
          'userID': userID,
          'currentID': appStateClass.currentID,
          'currentLength': currentPostsLength,
          'paginationLimit': postsPaginationLimit,
          'maxFetchLimit': postsServerFetchLimit
        });
        var res = await dio.get('$serverDomainAddress/users/fetchUserPosts', data: stringified);
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List userPostsData = res.data['userPostsData'];
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
            for(int i = 0; i < userPostsData.length; i++){
              Map postData = userPostsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
              PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
              if(mounted){
                updatePostData(postDataClass);
                posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
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

  Future<void> loadMorePosts() async{
    try {
      if(mounted){
        loadingState.value = LoadingState.paginating;
        paginationStatus.value = PaginationStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchProfilePosts(posts.value.length, false);
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
                      return CustomPostWidget(
                        postData: PostClass.getFakeData(),
                        senderData: UserDataClass.getFakeData(), 
                        senderSocials: UserSocialClass.getFakeData(), 
                        pageDisplayType: PostDisplayType.profilePost,
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
                              valueListenable: posts,
                              builder: ((context, posts, child) {
                                return LoadMoreBottom(
                                  addBottomSpace: canPaginateValue,
                                  loadMore: () async{
                                    if(canPaginateValue){
                                      await loadMorePosts();
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
                                        childCount: posts.length, 
                                        (context, index) {
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
                                                    if(userData.blocksCurrentID){
                                                      return Container();
                                                    }
                                                    return ValueListenableBuilder(
                                                      valueListenable: appStateClass.usersSocialsNotifiers.value[posts[index].sender]!.notifier, 
                                                      builder: ((context, userSocials, child) { 
                                                        if(userData.private && !userSocials.followedByCurrentID && userData.userID != appStateClass.currentID){
                                                          return Container();
                                                        }
                                                        return CustomPostWidget(
                                                          postData: postData, 
                                                          senderData: userData,
                                                          senderSocials: userSocials,
                                                          pageDisplayType: PostDisplayType.profilePost,
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
