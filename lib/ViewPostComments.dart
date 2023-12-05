// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as d;
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/DisplayCommentDataClass.dart';
import 'package:social_media_app/class/DisplayPostDataClass.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomPagination.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/state/main.dart';
import 'class/CommentClass.dart';
import 'class/MediaDataClass.dart';
import 'class/PostClass.dart';
import 'custom/CustomCommentWidget.dart';
import 'custom/CustomPostWidget.dart';
import 'streams/CommentDataStreamClass.dart';
import 'styles/AppStyles.dart';

var dio = d.Dio();

class ViewPostCommentsWidget extends StatelessWidget {
  final PostClass selectedPostData;

  const ViewPostCommentsWidget({super.key, required this.selectedPostData});

  @override
  Widget build(BuildContext context) {
    return ViewPostCommentsWidgetStateful(selectedPostData: selectedPostData);
  }
}

class ViewPostCommentsWidgetStateful extends StatefulWidget {
  final PostClass selectedPostData;
  const ViewPostCommentsWidgetStateful({super.key, required this.selectedPostData});

  @override
  State<ViewPostCommentsWidgetStateful> createState() => _ViewPostCommentsWidgetStatefulState();
}

class _ViewPostCommentsWidgetStatefulState extends State<ViewPostCommentsWidgetStateful> with LifecycleListenerMixin{
  late PostClass selectedPostData;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<DisplayPostDataClass?> selectedPost = ValueNotifier(null);
  ValueNotifier<LoadingStatus> loadingCommentsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(true);
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    selectedPostData = widget.selectedPostData;
    runDelay(() async => fetchPostData(comments.value.length, false, false), actionDelayTime);
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == selectedPostData.postID){
          comments.value = [data.commentClass, ...comments.value];
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
    commentDataStreamClassSubscription.cancel();
    super.dispose();
    isLoading.dispose();
    comments.dispose();
    loadingCommentsStatus.dispose();
    canPaginate.dispose();
    selectedPost.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchPostData(int currentCommentsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'sender': selectedPostData.sender,
          'postID': selectedPostData.postID,
          'currentID': appStateClass.currentID,
          'currentLength': currentCommentsLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': postsServerFetchLimit
        });
        d.Response res;
        if(!isPaginating){
          res = await dio.get('$serverDomainAddress/users/fetchSelectedPostComments', data: stringified);
        }else{
          res = await dio.get('$serverDomainAddress/users/fetchSelectedPostCommentsPagination', data: stringified);
        }
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List allPostsData = [...res.data['commentsData']];
            if(!isPaginating){
              allPostsData.insert(0, res.data['selectedPostData']);
            }
            if(mounted){
              canPaginate.value = res.data['canPaginate'];
            }
            List userProfileDataList = res.data['usersProfileData'];
            List usersSocialsDatasList = res.data['usersSocialsData'];
            
            for(int i = 0; i < userProfileDataList.length; i++){
              Map userProfileData = userProfileDataList[i];
              UserDataClass userDataClass = UserDataClass.fromMap(userProfileData);
              UserSocialClass userSocialClass = UserSocialClass.fromMap(usersSocialsDatasList[i]);
              if(mounted){
                updateUserData(userDataClass, context);
                updateUserSocials(userDataClass, userSocialClass, context);
              }
            }
            for(int i = 0; i < allPostsData.length; i++){
              if(allPostsData[i]['type'] == 'post'){
                Map postData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                if(mounted){
                  updatePostData(postDataClass, context);
                  selectedPost.value = DisplayPostDataClass(postData['sender'], postData['post_id']);
                }
              }else{
                Map commentData = allPostsData[i];
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
          await fetchPostData(comments.value.length, false, true);
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
    return Scaffold(
      appBar: AppBar(
        leading: defaultLeadingWidget(context),
        title: const Text('View Post'), 
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
                  valueListenable: loadingCommentsStatus,
                  builder: (context, loadingStatusValue, child){
                    return ValueListenableBuilder(
                      valueListenable: canPaginate,
                      builder: (context, canPaginateValue, child){
                        return ValueListenableBuilder(
                          valueListenable: comments,
                          builder: ((context, comments, child) {
                            return LoadMoreBottom(
                              addBottomSpace: canPaginate.value,
                              loadMore: () async{
                                if(canPaginate.value){
                                  await loadMoreComments();
                                }
                              },
                              status: loadingStatusValue,
                              refresh: null,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: <Widget>[
                                  SliverToBoxAdapter(
                                    child: ValueListenableBuilder(
                                      valueListenable: selectedPost, 
                                      builder: ((context, selectedPost, child) {
                                        if(selectedPost != null){
                                          return ValueListenableBuilder<PostClass>(
                                            valueListenable: appStateClass.postsNotifiers.value[selectedPost.sender]![selectedPost.postID]!.notifier,
                                            builder: ((context, postData, child) {
                                              return ValueListenableBuilder(
                                                valueListenable: appStateClass.usersDataNotifiers.value[selectedPost.sender]!.notifier, 
                                                builder: ((context, userData, child) {
                                                  if(!postData.deleted){
                                                    return ValueListenableBuilder(
                                                      valueListenable: appStateClass.usersSocialsNotifiers.value[selectedPost.sender]!.notifier, 
                                                      builder: ((context, userSocials, child) {
                                                        return CustomPostWidget(
                                                          postData: postData, 
                                                          senderData: userData,
                                                          senderSocials: userSocials,
                                                          pageDisplayType: PostDisplayType.viewPost,
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
                                          return loadingPageWidget();
                                        }
                                      })
                                    )
                                  ),
                                  SliverToBoxAdapter(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: defaultVerticalPadding),
                                      child: const Column(
                                        children: [
                                          Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))
                                        ]
                                      )
                                    )
                                  ),
                                  SliverList(delegate: SliverChildBuilderDelegate(
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
                                                return ValueListenableBuilder(
                                                  valueListenable: appStateClass.usersSocialsNotifiers.value[comments[index].sender]!.notifier, 
                                                  builder: ((context, userSocials, child) {
                                                    return CustomCommentWidget(
                                                      commentData: commentData, 
                                                      senderData: userData,
                                                      senderSocials: userSocials,
                                                      pageDisplayType: CommentDisplayType.viewComment,
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