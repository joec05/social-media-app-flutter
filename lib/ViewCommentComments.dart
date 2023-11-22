// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as d;
import 'package:flutter/material.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/DisplayCommentDataClass.dart';
import 'package:social_media_app/class/PostClass.dart';
import 'package:social_media_app/class/PostNotifier.dart';
import 'package:social_media_app/class/UserDataClass.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/custom/CustomPagination.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import '../redux/reduxLibrary.dart';
import 'class/CommentClass.dart';
import 'class/CommentNotifier.dart';
import 'class/DisplayPostDataClass.dart';
import 'class/MediaDataClass.dart';
import 'class/UserDataNotifier.dart';
import 'class/UserSocialNotifier.dart';
import 'custom/CustomCommentWidget.dart';
import 'custom/CustomPostWidget.dart';
import 'streams/CommentDataStreamClass.dart';
import 'styles/AppStyles.dart';

var dio = d.Dio();

class ViewCommentCommentsWidget extends StatelessWidget {
  final CommentClass selectedCommentData;

  const ViewCommentCommentsWidget({super.key, required this.selectedCommentData});

  @override
  Widget build(BuildContext context) {
    return ViewCommentCommentsWidgetStateful(selectedCommentData: selectedCommentData);
  }
}

class ViewCommentCommentsWidgetStateful extends StatefulWidget {
  final CommentClass selectedCommentData;
  const ViewCommentCommentsWidgetStateful({super.key, required this.selectedCommentData});

  @override
  State<ViewCommentCommentsWidgetStateful> createState() => _ViewCommentCommentsWidgetStatefulState();
}

class _ViewCommentCommentsWidgetStatefulState extends State<ViewCommentCommentsWidgetStateful> with LifecycleListenerMixin{
  late CommentClass selectedCommentData;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<List<DisplayCommentDataClass>> comments = ValueNotifier([]);
  ValueNotifier<LoadingStatus> loadingCommentsStatus = ValueNotifier(LoadingStatus.loaded);
  ValueNotifier<bool> canPaginate = ValueNotifier(false);
  ValueNotifier<DisplayCommentDataClass?> selectedComment = ValueNotifier(null);
  ValueNotifier<dynamic> parentPost = ValueNotifier(null);
  late StreamSubscription commentDataStreamClassSubscription;
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    selectedCommentData = widget.selectedCommentData;
    fetchCommentData(comments.value.length, false, false);
    commentDataStreamClassSubscription = CommentDataStreamClass().commentDataStream.listen((CommentDataStreamControllerClass data) {
      if(mounted){
        if(data.uniqueID == selectedCommentData.commentID){
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
    selectedComment.dispose();
    parentPost.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchCommentData(int currentCommentsLength, bool isRefreshing, bool isPaginating) async{
    try {
      if(mounted){
        isLoading.value = true;
        String stringified = jsonEncode({
          'sender': selectedCommentData.sender,
          'commentID': selectedCommentData.commentID,
          'currentID': fetchReduxDatabase().currentID,
          'currentLength': currentCommentsLength,
          'paginationLimit': usersPaginationLimit,
          'maxFetchLimit': postsServerFetchLimit
        });
        d.Response res ;
        if(!isPaginating){
          res = await dio.get('$serverDomainAddress/users/fetchSelectedCommentComments', data: stringified);
        }else{
          res = await dio.get('$serverDomainAddress/users/fetchSelectedCommentCommentsPagination', data: stringified);
        }
        
        if(res.data.isNotEmpty){
          if(res.data['message'] == 'Successfully fetched data'){
            List allPostsData = [...res.data['commentsData']];
            if(!isPaginating){
              res.data['parentPostData']['type'] = 'parent_${res.data['parentPostData']['type']}';
              res.data['selectedCommentData']['type'] = 'selected_${res.data['selectedCommentData']['type']}';
              allPostsData.insertAll(0, [res.data['parentPostData'], res.data['selectedCommentData']]);
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
              if(allPostsData[i]['type'] == 'parent_post'){
                Map postData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(postData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                PostClass postDataClass = PostClass.fromMap(postData, newMediasDatas);
                if(mounted){
                  updatePostData(postDataClass, context);
                  parentPost.value = DisplayPostDataClass(postData['sender'], postData['post_id']);
                }
              }else{
                Map commentData = allPostsData[i];
                List<dynamic> mediasDatasFromServer = jsonDecode(commentData['medias_datas']);            
                List<MediaDatasClass> newMediasDatas = [];
                newMediasDatas = await loadMediasDatas(mediasDatasFromServer);
                CommentClass commentDataClass = CommentClass.fromMap(commentData, newMediasDatas);
                if(mounted){
                  updateCommentData(commentDataClass, context);
                  if(commentData['type'] == 'parent_comment'){
                    parentPost.value = DisplayCommentDataClass(commentData['sender'], commentData['comment_id']);
                  }else if(commentData['type'] == 'selected_comment'){
                    selectedComment.value = DisplayCommentDataClass(commentData['sender'], commentData['comment_id']);
                  }else{
                    comments.value = [...comments.value, DisplayCommentDataClass(commentData['sender'], commentData['comment_id'])];
                  }
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
          await fetchCommentData(comments.value.length, false, true);
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
        title: const Text('View Comment'), 
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
                                                  valueListenable: parentPost, 
                                                  builder: ((context, parentPost, child) {
                                                    if(parentPost != null){
                                                      return parentPost is DisplayPostDataClass ?
                                                        StoreConnector<AppState, ValueNotifier<Map<String, Map<String, PostNotifier>>>>(
                                                          converter: (store) => store.state.postsNotifiers,
                                                          builder: (context, ValueNotifier<Map<String, Map<String, PostNotifier>>> postsNotifiers){
                                                            return ValueListenableBuilder<PostClass>(
                                                              valueListenable: postsNotifiers.value[parentPost.sender]![parentPost.postID]!.notifier,
                                                              builder: ((context, postData, child) {
                                                                return ValueListenableBuilder(
                                                                  valueListenable: usersDatasNotifiers.value[parentPost.sender]!.notifier, 
                                                                  builder: ((context, userData, child) {
                                                                    if(!postData.deleted){
                                                                      return ValueListenableBuilder(
                                                                        valueListenable: usersSocialsNotifiers.value[parentPost.sender]!.notifier, 
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
                                                          }
                                                        )
                                                      : parentPost is DisplayCommentDataClass ?
                                                        ValueListenableBuilder<CommentClass>(
                                                          valueListenable: commentsNotifiers.value[parentPost.sender]![parentPost.commentID]!.notifier,
                                                          builder: ((context, commentData, child) {
                                                            return ValueListenableBuilder(
                                                              valueListenable: usersDatasNotifiers.value[parentPost.sender]!.notifier, 
                                                              builder: ((context, userData, child) {
                                                                if(!commentData.deleted){
                                                                  return ValueListenableBuilder(
                                                                    valueListenable: usersSocialsNotifiers.value[parentPost.sender]!.notifier, 
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
                                                        )
                                                      : Container();
                                                    }else{
                                                      return Container();
                                                    }
                                                  })
                                                )
                                              ),
                                              SliverToBoxAdapter(
                                                child: ValueListenableBuilder(
                                                  valueListenable: selectedComment, 
                                                  builder: ((context, selectedComment, child) {
                                                    if(selectedComment != null){
                                                      return ValueListenableBuilder<CommentClass>(
                                                        valueListenable: commentsNotifiers.value[selectedComment.sender]![selectedComment.commentID]!.notifier,
                                                        builder: ((context, commentData, child) {
                                                          return ValueListenableBuilder(
                                                            valueListenable: usersDatasNotifiers.value[selectedComment.sender]!.notifier, 
                                                            builder: ((context, userData, child) {
                                                              if(!commentData.deleted){
                                                                return ValueListenableBuilder(
                                                                  valueListenable: usersSocialsNotifiers.value[selectedComment.sender]!.notifier, 
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
                                                    }else{
                                                      return Container();
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