import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/ProfilePage.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/MediaDataClass.dart';
import 'package:social_media_app/class/CommentClass.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../EditComment.dart';
import '../ViewCommentComments.dart';
import '../WriteComment.dart';
import '../class/UserDataClass.dart';
import '../class/UserSocialClass.dart';
import '../extenstions/StringEllipsis.dart';
import 'CustomButton.dart';
import 'CustomTextSpan.dart';

var dio = Dio();

enum CommentDisplayType{
  feed, profileComment, viewComment, searchedComment, bookmark
}

class CustomCommentWidget extends StatefulWidget{
  final CommentClass commentData;
  final UserDataClass senderData;
  final UserSocialClass senderSocials;
  final CommentDisplayType pageDisplayType;
  
  const CustomCommentWidget({super.key, required this.commentData, required this.senderData, 
  required this.senderSocials, required this.pageDisplayType});

  @override
  State<CustomCommentWidget> createState() =>_CustomCommentWidgetState();
}

class _CustomCommentWidgetState extends State<CustomCommentWidget>{

  late CommentClass commentData;
  late UserDataClass senderData;
  late UserSocialClass senderSocials;

  @override initState(){
    super.initState();
    senderData = widget.senderData;
    commentData = widget.commentData;
    senderSocials = widget.senderSocials;
  }

  @override
  void dispose(){
    super.dispose();
  }


  void displayCommentBottomSheet(){
    CommentClass commentDataClass = widget.commentData;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [ 
                Container(
                  child: commentDataClass.sender == fetchReduxDatabase().currentID ? 
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (){},
                        splashFactory: InkRipple.splashFactory,
                        child: CustomButton(
                          onTapped: (){
                            Navigator.pop(bottomSheetContext);
                            runDelay(() => Navigator.push(
                              context,
                              SliderRightToLeftRoute(
                                page: EditCommentWidget(commentData: commentData)
                              )
                            ), navigatorDelayTime);
                          },
                          buttonText: 'Edit comment',
                          width: double.infinity,
                          height: getScreenHeight() * 0.075,
                          buttonColor: Colors.transparent,
                          setBorderRadius: false,
                        )
                      )
                    )
                    
                  : null
                ),     
                Container(
                  child: commentDataClass.sender == fetchReduxDatabase().currentID ? 
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (){},
                        splashFactory: InkRipple.splashFactory,
                        child: CustomButton(
                          onTapped: (){
                            Navigator.pop(bottomSheetContext);
                            runDelay(() => deleteComment(commentData, context), actionDelayTime) ;
                          },
                          buttonText: 'Delete comment',
                          width: double.infinity,
                          height: getScreenHeight() * 0.075,
                          buttonColor: Colors.transparent,
                          setBorderRadius: false,
                        )
                      )
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
    if(commentData.deleted || senderData.suspended || senderData.deleted){
      return Container();
    }
    if(widget.pageDisplayType == CommentDisplayType.profileComment && !senderData.blocksCurrentID){}
    else if(senderData.mutedByCurrentID || senderData.blockedByCurrentID || senderData.blocksCurrentID){
      return Container();
    }
    if(senderData.private && !senderSocials.followedByCurrentID && senderData.userID != fetchReduxDatabase().currentID){
      return Container();
    }
    if(widget.pageDisplayType == CommentDisplayType.bookmark && !commentData.bookmarkedByCurrentID){
      return Container();
    }
    List<MediaDatasClass> mediasDatas = (commentData.mediasDatas);
    UserDataClass parentPostSender = fetchReduxDatabase().usersDatasNotifiers.value[commentData.parentPostSender]!.notifier.value;
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
                page: ViewCommentCommentsWidget(selectedCommentData: commentData)
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
                                  page: ProfilePageWidget(userID: commentData.sender)
                                )
                              ), navigatorDelayTime);
                            },
                            child: Container(
                              width: getScreenWidth() * 0.125, height: getScreenWidth() * 0.125,
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
                            width: getScreenWidth() * 0.03
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          Flexible(child: Text(StringEllipsis.convertToEllipsis(senderData.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold))),
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
                                      () => runDelay(() => displayCommentBottomSheet(), actionDelayTime),
                                      Icon(Icons.more_horiz, size: moreIconProfileWidgetSize)
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: getScreenHeight() * 0.0015
                                ),
                                Text('@${senderData.username}', style: TextStyle(fontSize: defaultTextFontSize, color: Colors.lightBlue))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: getScreenHeight() * 0.01),
                Text("Replying to @${parentPostSender.username}'s ${commentData.parentPostType}", style: TextStyle(fontSize: defaultTextFontSize, color: Colors.blueGrey)),
                SizedBox(height: getScreenHeight() * 0.01),
                const Divider(
                  color: Colors.white, height: 2.5, thickness: 1
                ),
                SizedBox(height: getScreenHeight() * 0.01),
                DisplayTextComponent(
                  text: commentData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                  maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize), alignment: TextAlign.left, 
                  context: context
                ),
                SizedBox(height: commentData.content.isNotEmpty ? getScreenHeight() * 0.01 : 0),
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
                          if(commentData.likedByCurrentID){
                            unlikeComment(commentData);
                          }else{
                            likeComment(commentData);
                          }
                        }, actionDelayTime);
                      },
                      Row(
                        children: [
                          commentData.likedByCurrentID ?
                            const Icon(FontAwesomeIcons.solidHeart, size: 20, color: Colors.red)
                          : 
                            const Icon(FontAwesomeIcons.heart, size: 20),
                          SizedBox(width: getScreenWidth() * 0.02),
                          Text(displayShortenedCount(commentData.likesCount))
                        ],
                      )
                    ),
                    generatePostActionWidget(
                      (){
                        runDelay((){
                          if(commentData.bookmarkedByCurrentID){
                            unbookmarkComment(commentData);
                          }else{
                            bookmarkComment(commentData);
                          }
                        }, actionDelayTime);
                      },
                      Row(
                        children: [
                          commentData.bookmarkedByCurrentID ?
                              const Icon(Icons.bookmark_added, size: 22.5, color: Colors.green)
                            : 
                              const Icon(Icons.bookmark_add, size: 22.5),
                          SizedBox(width: getScreenWidth() * 0.02),
                          Text(displayShortenedCount(commentData.bookmarksCount))
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
                                parentPostSender: commentData.sender,
                                parentPostID: commentData.commentID,
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
                          Text(displayShortenedCount(commentData.commentsCount))
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: getScreenHeight() * 0.005),
                Text(getTimeDifference(commentData.uploadTime), style: const TextStyle(fontSize: 13, color: Colors.grey))
              ],
            )
          )
        )
      )
    );
  }
}