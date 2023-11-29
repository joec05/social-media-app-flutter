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
import 'class/DisplayCommentDataClass.dart';
import 'class/CommentClass.dart';
import 'class/CommentNotifier.dart';
import 'class/UserDataNotifier.dart';
import 'class/UserSocialNotifier.dart';
import 'custom/CustomPagination.dart';
import 'custom/CustomCommentWidget.dart';

var dio = d.Dio();

class SearchedCommentsWidget extends StatelessWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const SearchedCommentsWidget({super.key, required this.searchedText, required this.absorberContext});

  @override
  Widget build(BuildContext context) {
    return _SearchedCommentsWidgetStateful(searchedText: searchedText, absorberContext: absorberContext);
  }
}

class _SearchedCommentsWidgetStateful extends StatefulWidget {
  final String searchedText;
  final BuildContext absorberContext;
  const _SearchedCommentsWidgetStateful({required this.searchedText, required this.absorberContext});

  @override
  State<_SearchedCommentsWidgetStateful> createState() => _SearchedCommentsWidgetStatefulState();
}

class _SearchedCommentsWidgetStatefulState extends State<_SearchedCommentsWidgetStateful> with AutomaticKeepAliveClientMixin{
  late String searchedText;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingCommentsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<int> totalCommentsLength = ValueNotifier(postsServerFetchLimit);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    searchedText = widget.searchedText;
    runDelay(() async => fetchSearchedComments(comments.value.length, false, false), actionDelayTime);
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
    comments.dispose();
    loadingCommentsStatus.dispose();
    totalCommentsLength.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchSearchedComments(int currentCommentsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = '';
        d.Response res;
        if(!isPaginating){
          stringified = jsonEncode({
            'searchedText': widget.searchedText,
            'currentID': fetchReduxDatabase().currentID,
            'currentLength': currentCommentsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedComments', data: stringified);
        }else{
          List paginatedSearchedComments = await DatabaseHelper().fetchPaginatedSearchedComments(currentCommentsLength, postsPaginationLimit);
          stringified = jsonEncode({
            'searchedText': widget.searchedText,
            'searchedCommentsEncoded': jsonEncode(paginatedSearchedComments),
            'currentID': fetchReduxDatabase().currentID,
            'currentLength': currentCommentsLength,
            'paginationLimit': postsPaginationLimit,
            'maxFetchLimit': postsServerFetchLimit
          });
          res = await dio.get('$serverDomainAddress/users/fetchSearchedCommentsPagination', data: stringified);
        }
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            if(!isPaginating){
              List searchedComments = res.data['searchedComments'];
              await DatabaseHelper().replaceAllSearchedComments(searchedComments);
            }
            List modifiedSearchedCommentsData = res.data['modifiedSearchedComments'];
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            if(isRefreshing && mounted){
              comments.value = [];
            }
            if(!isPaginating && mounted){
              totalCommentsLength.value = min(res.data['totalCommentsLength'], postsServerFetchLimit);
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
            for(int i = 0; i < modifiedSearchedCommentsData.length; i++){
              Map commentData = modifiedSearchedCommentsData[i];
              List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
              List<MediaDatasClass> newMediasDatas = [];
              newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
              CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
              if(mounted){ 
                updateCommentData(commentDataClass, context);
                if(comments.value.length < totalCommentsLength.value){
                  comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
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

  Future<void> loadMoreComments() async{
    try {
      if(mounted){
        loadingCommentsStatus.value = LoadingStatus.loading;
        Timer.periodic(const Duration(milliseconds: 1500), (Timer timer) async{
          timer.cancel();
          await fetchSearchedComments(comments.value.length, false, true);
          if(mounted){
            loadingCommentsStatus.value = LoadingStatus.loaded;
          }
        });
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<void> refresh() async{
    await fetchSearchedComments(0, true, false);
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
                return StoreConnector<AppState, ValueNotifier<Map<String, Map<String, CommentNotifier>>>>(
                  converter: (store) => store.state.commentsNotifiers,
                  builder: (context, ValueNotifier<Map<String, Map<String, CommentNotifier>>> commentsNotifiers){
                    return StoreConnector<AppState, ValueNotifier<Map<String, UserDataNotifier>>>(
                      converter: (store) => store.state.usersDatasNotifiers,
                      builder: (context, ValueNotifier<Map<String, UserDataNotifier>> usersDatasNotifiers){
                        return StoreConnector<AppState, ValueNotifier<Map<String, UserSocialNotifier>>>(
                          converter: (store) => store.state.usersSocialsNotifiers,
                          builder: (context, ValueNotifier<Map<String, UserSocialNotifier>> usersSocialsNotifiers){
                            return ValueListenableBuilder(
                              valueListenable: loadingCommentsStatus,
                              builder: (context, loadingStatusValue, child){
                                return ValueListenableBuilder(
                                  valueListenable: totalCommentsLength,
                                  builder: (context, totalCommentsLengthValue, child){
                                    return ValueListenableBuilder(
                                      valueListenable: comments,
                                      builder: ((context, comments, child) {
                                        return LoadMoreBottom(
                                          addBottomSpace: comments.length < totalCommentsLengthValue,
                                          loadMore: () async{
                                            if(comments.length < totalCommentsLengthValue){
                                              await loadMoreComments();
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
                                                childCount: comments.length, 
                                                (context, index) {
                                                  if(commentsNotifiers.value[comments[index].sender] == null){
                                                    return Container();
                                                  }
                                                  if(commentsNotifiers.value[comments[index].sender]![comments[index].commentID] == null){
                                                    return Container();
                                                  }
                                                  return ValueListenableBuilder<CommentClass>(
                                                    valueListenable: commentsNotifiers.value[comments[index].sender]![comments[index].commentID]!.notifier,
                                                    builder: ((context, commentData, child) {
                                                      return ValueListenableBuilder(
                                                        valueListenable: usersDatasNotifiers.value[comments[index].sender]!.notifier, 
                                                        builder: ((context, userData, child) {
                                                          if(!commentData.deleted){
                                                            return ValueListenableBuilder(
                                                              valueListenable: usersSocialsNotifiers.value[comments[index].sender]!.notifier, 
                                                              builder: ((context, userSocials, child) {
                                                                return CustomCommentWidget(
                                                                  commentData: commentData, 
                                                                  senderData: userData,
                                                                  senderSocials: userSocials,
                                                                  pageDisplayType: CommentDisplayType.searchedComment,
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
