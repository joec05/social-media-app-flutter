import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/PostLikesList.dart';
import 'package:social_media_app/PostBookmarksList.dart';
import 'package:social_media_app/ProfilePage.dart';
import 'package:social_media_app/ViewPostComments.dart';
import 'package:social_media_app/WriteComment.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/class/PostClass.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../EditPost.dart';
import '../class/UserDataClass.dart';
import '../class/UserSocialClass.dart';
import '../extenstions/StringEllipsis.dart';
import 'CustomButton.dart';
import 'CustomTextSpan.dart';

enum PostDisplayType{
  feed, profilePost, viewPost, searchedPost, bookmark
}

var dio = Dio();

class CustomPostWidget extends StatefulWidget{
  final PostClass postData;
  final UserDataClass senderData;
  final UserSocialClass senderSocials;
  final PostDisplayType pageDisplayType;

  const CustomPostWidget({
    super.key, required this.postData, required this.senderData, 
    required this.senderSocials, required this.pageDisplayType
  });

  @override
  State<CustomPostWidget> createState() =>_CustomPostWidgetState();
}

class _CustomPostWidgetState extends State<CustomPostWidget>{

  late PostClass postData;
  late UserDataClass senderData;
  late UserSocialClass senderSocials;

  @override initState(){
    super.initState();
    senderData = widget.senderData;
    postData = widget.postData;
    senderSocials = widget.senderSocials;
  }

  @override
  void dispose(){
    super.dispose();
  }


  void displayPostBottomSheet(){
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 56, 54, 54),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0)
              )
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: getScreenHeight() * 0.015),
                Container(
                  height: getScreenHeight() * 0.01,
                  width: getScreenWidth() * 0.15,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  )
                ),
                SizedBox(height: getScreenHeight() * 0.015),
                CustomButton(
                  onTapped: (){
                    Navigator.pop(bottomSheetContext);
                    runDelay(() => Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: PostLikesListWidget(
                          postID: postData.postID, postSender: postData.sender
                        )
                      )
                    ), navigatorDelayTime);
                  },
                  buttonText: 'View likes',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                ),
                CustomButton(
                  onTapped: (){
                    Navigator.pop(bottomSheetContext);
                    runDelay(() => Navigator.push(
                      context,
                      SliderRightToLeftRoute(
                        page: PostBookmarksListWidget(
                          postID: postData.postID, postSender: postData.sender
                        )
                      )
                    ), navigatorDelayTime);
                  },
                  buttonText: 'View bookmarks',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  buttonColor: Colors.transparent,
                  setBorderRadius: false,
                ),
                Container(
                  child: postData.sender == appStateClass.currentID ? 
                    CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: EditPostWidget(
                              postData: postData
                            )
                          )
                        ), navigatorDelayTime);
                      },
                      buttonText: 'Edit post',
                      width: double.infinity,
                      height: getScreenHeight() * 0.08,
                      buttonColor: Colors.transparent,
                      setBorderRadius: false,
                    )
                  : null
                ), 
                Container(
                  child: postData.sender == appStateClass.currentID ? 
                    CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => deletePost(postData), actionDelayTime);
                      },
                      buttonText: 'Delete post',
                      width: double.infinity,
                      height: getScreenHeight() * 0.08,
                      buttonColor: Colors.transparent,
                      setBorderRadius: false,
                    )
                    
                  : null
                ), 
              ]
            )
          )
        );
      }
    );
  }

  
  @override
  Widget build(BuildContext context){
    if(postData.deleted || senderData.suspended || senderData.deleted){
      return Container();
    }
    if(widget.pageDisplayType == PostDisplayType.profilePost && !senderData.blocksCurrentID){}
    else if(senderData.mutedByCurrentID || senderData.blockedByCurrentID || senderData.blocksCurrentID){
      return Container();
    }
    if(senderData.private && !senderSocials.followedByCurrentID && senderData.userID != appStateClass.currentID){
      return Container();
    }
    if(widget.pageDisplayType == PostDisplayType.bookmark && !postData.bookmarkedByCurrentID){
      return Container();
    }

    List<MediaDatasClass> mediasDatas = (postData.mediasDatas);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (){
            runDelay(() => Navigator.push(
              context,
              SliderRightToLeftRoute(
                page: ViewPostCommentsWidget(selectedPostData: postData)
              )
            ), navigatorDelayTime);
          },
          splashFactory: InkRipple.splashFactory,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: (){
                              runDelay(() => Navigator.push(
                                context,
                                SliderRightToLeftRoute(
                                  page: ProfilePageWidget(userID: postData.sender)
                                )
                              ), 0);
                            },
                            child: Container(
                              width: getScreenWidth() * 0.1, height: getScreenWidth() * 0.1,
                              decoration: BoxDecoration(
                                border: Border.all(width: 2, color: Colors.white),
                                borderRadius: BorderRadius.circular(100),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    senderData.profilePicLink
                                  ), fit: BoxFit.fill
                                )
                              ),
                            ),
                          ),
                          SizedBox(
                            width: getScreenWidth() * 0.02
                          ),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              StringEllipsis.convertToEllipsis(senderData.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.bold)
                                            )
                                          ),
                                          senderData.verified && !senderData.suspended && !senderData.deleted ?
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: iconsBesideNameProfileMargin
                                                ),
                                                Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize),
                                              ]
                                            )
                                          : Container(),
                                          senderData.private && !senderData.suspended && !senderData.deleted ?
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: iconsBesideNameProfileMargin
                                                ),
                                                Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                                              ],
                                            )
                                          : Container(),
                                        ],
                                      ),
                                    ),
                                    generatePostMoreOptionsWidget(
                                      () => runDelay(() => displayPostBottomSheet(), actionDelayTime),
                                      Icon(Icons.more_horiz, size: moreIconProfileWidgetSize)
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('@${senderData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.lightBlue)),
                                    Text(getTimeDifference(postData.uploadTime), style: TextStyle(fontSize: defaultTextFontSize * 0.675, color: Colors.grey))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ),
                SizedBox(height: getScreenHeight() * 0.01),
                const Divider(
                  color: Colors.white, height: 2.5, thickness: 1
                ),
                SizedBox(height: getScreenHeight() * 0.01),
                DisplayTextComponent(
                  text: postData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                  maxLines: 100, style: TextStyle(fontSize: defaultTextFontSize * 0.95), alignment: TextAlign.left, 
                  context: context
                ),
                SizedBox(height: postData.content.isNotEmpty ? getScreenHeight() * 0.01 : 0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for(int i = 0; i < mediasDatas.length; i++)
                    mediaDataPostComponentWidget(mediasDatas[i], context)
                  ],
                ),
                const Divider(
                  color: Colors.white, height: 2.5, thickness: 1
                ),
                SizedBox(height: getScreenHeight() * 0.005),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    generatePostActionWidget(
                      (){
                        runDelay((){
                          if(postData.likedByCurrentID){
                            unlikePost(postData);
                          }else{
                            likePost(postData);
                          }
                        }, actionDelayTime);
                      },
                      Row(
                        children: [
                          postData.likedByCurrentID ?
                            const Icon(FontAwesomeIcons.solidHeart, size: 20, color: Colors.red)
                          : 
                            const Icon(FontAwesomeIcons.heart, size: 20),
                          SizedBox(width: getScreenWidth() * 0.02),
                          Text(displayShortenedCount(postData.likesCount))
                        ],
                      )
                    ),
                    generatePostActionWidget(
                      (){
                        runDelay((){
                          if(postData.bookmarkedByCurrentID){
                            unbookmarkPost(postData);
                          }else{
                            bookmarkPost(postData);
                          }
                        }, actionDelayTime);
                      },
                      Row(
                        children: [
                          postData.bookmarkedByCurrentID ?
                              const Icon(Icons.bookmark_added, size: 22.5, color: Colors.green)
                            : 
                              const Icon(Icons.bookmark_add, size: 22.5),
                          SizedBox(width: getScreenWidth() * 0.02),
                          Text(displayShortenedCount(postData.bookmarksCount))
                        ],
                      ),
                    ),
                    generatePostActionWidget(
                      (){
                        runDelay((){
                          Navigator.push(
                            context,
                            SliderRightToLeftRoute(
                              page: WriteCommentWidget(
                                parentPostSender: postData.sender,
                                parentPostID: postData.postID,
                                parentPostType: 'post',
                              )
                            )
                          );
                        }, navigatorDelayTime);
                      },
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.solidComment, size: 20, color: Colors.grey),
                          SizedBox(width: getScreenWidth() * 0.02),
                          Text(displayShortenedCount(postData.commentsCount))
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        )
      )
    );
  }
}