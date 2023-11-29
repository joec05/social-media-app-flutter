// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart' as d;
import 'package:flutter/material.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/redux/reduxLibrary.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'caching/sqfliteConfiguration.dart';
import 'class/DisplayPostDataClass.dart';
import 'class/PostClass.dart';
import 'class/PostNotifier.dart';
import 'class/UserDataNotifier.dart';
import 'class/UserSocialNotifier.dart';
import 'custom/CustomPagination.dart';
import 'custom/CustomPostWidget.dart';

var dio = d.Dio();

class SearchedPostsWidget extends StatelessWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const SearchedPostsWidget({super.key, required this.searchedText, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _SearchedPostsWidgetStateful(searchedText: searchedText, absorberContext: absorberContext);
  }
}

class _SearchedPostsWidgetStateful extends StatefulWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const _SearchedPostsWidgetStateful({required this.searchedText, required this.absorberContext});

  @override
  State<_SearchedPostsWidgetStateful> createState() => _SearchedPostsWidgetStatefulState();
}

class _SearchedPostsWidgetStatefulState extends State<_SearchedPostsWidgetStateful> with AutomaticKeepAliveClientMixin{
  late String searchedText;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<DisplayPostDataClass>> posts = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingPostsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<int> totalPostsLength = ValueNotifier(postsServerFetchLimit);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    searchedText = widget.searchedText;
    runDelay(() async => fetchSearchedPosts(posts.value.length, false, false), actionDelayTime);
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
    super.dispose();
    isLoading.dispose();
    posts.dispose();
    loadingPostsStatus.dispose();
    totalPostsLength.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchSearchedPosts(int currentPostsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = '';
        d.Response res;
        if(!isPaginating){
          stringified = jsonEncode({
            'searchedText': widget.searchedText,
            'currentID': fetchReduxDatabase().currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedPosts', data: stringified);
        }else{
          List paginatedSearchedPosts = await DatabaseHelper().fetchPaginatedSearchedPosts(currentPostsLength, postsPaginationLimit);
          stringified = jsonEncode({
            'searchedText': widget.searchedText,
            'searchedPostsEncoded': jsonEncode(paginatedSearchedPosts),
            'currentID': fetchReduxDatabase().currentID,
            'currentLength': currentPostsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedPostsPagination', data: stringified);
        }
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data' && mounted){
            if(!isPaginating){
              List searchedPosts = res.data['searchedPosts'];
              await DatabaseHelper().replaceAllSearchedPosts(searchedPosts);
            }
            List modifiedSearchedPostsData = res.data['modifiedSearchedPosts'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              posts.value = [];
            }
            if(!isPaginating && mounted){
              totalPostsLength.value = min(res.data['totalPostsLength'], postsServerFetchLimit);
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
            for(int i = 0; i < modifiedSearchedPostsData.length; i++){
              Map postData = modifiedSearchedPostsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
              PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
              if(mounted){
                updatePostData(postDataClass, context);
                if(posts.value.length < totalPostsLength.value){
                  posts.value = [...posts.value, DisplayPostDataClass(postData['sender'], postData['post_id'])];
                }
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

  Future<void> loadMorePosts() async{
    try {
      if(mounted){
        loadingPostsStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchSearchedPosts(posts.value.length, false, true);
          if(mounted){
            loadingPostsStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> refresh() async{
    fetchSearchedPosts(0, true, false);
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
                return StoreConnector<AppState, ValueNotifier<Map<String, Map<String, PostNotifier>>>>(
                  converter: (store) => store.state.postsNotifiers,
                  builder: (context, ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers){
                    return StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
                      converter: (store) => store.state.usersDatasNotifiers,
                      builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
                        return StoreConnector<AppState, ValueNotifier<Map<String, UserSocialNotifier>>>(
                          converter: (store) => store.state.usersSocialsNotifiers,
                          builder: (context, ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers){
                            return ValueListenableBuilder(
                              valueListenable: loadingPostsStatus,
                              builder: (context, loadingStatusValue, child){
                                return ValueListenableBuilder(
                                  valueListenable: totalPostsLength,
                                  builder: (context, totalPostsLengthValue, child){
                                    return ValueListenableBuilder(
                                      valueListenable: posts,
                                      builder: ((context, posts, child) {
                                        return LoadMoreBottom(
                                          addBottomSpace: posts.length < totalPostsLengthValue,
                                          loadMore: () async{
                                            if(posts.length < totalPostsLengthValue){
                                              await loadMorePosts();
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
                                                childCount: posts.length, 
                                                (context, index) {
                                                  if(postsNotifiers.value[posts[index].sender] == null){
                                                    return Container();
                                                  }
                                                  if(postsNotifiers.value[posts[index].sender]![posts[index].postID] == null){
                                                    return Container();
                                                  }
                                                  return ValueListenableBuilder<PostClass>(
                                                    valueListenable: postsNotifiers.value[posts[index].sender]![posts[index].postID]!.notifier,
                                                    builder: ((context, postData, child) {
                                                      return ValueListenableBuilder(
                                                        valueListenable: usersDatasNotifiers.value[posts[index].sender]!.notifier, 
                                                        builder: ((context, userData, child) {
                                                          if(!postData.deleted){
                                                            return ValueListenableBuilder(
                                                              valueListenable: usersSocialsNotifiers.value[posts[index].sender]!.notifier, 
                                                              builder: ((context, userSocials, child) {
                                                                return CustomPostWidget(
                                                                  postData: postData, 
                                                                  senderData: userData,
                                                                  senderSocials: userSocials,
                                                                  pageDisplayType: PostDisplayType.searchedPost,
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

  @override
  bool get wantKeepAlive => true;
}
