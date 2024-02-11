import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class CustomCommentWidget extends StatefulWidget{
  final CommentClass commentData;
  final UserDataClass senderData;
  final UserSocialClass senderSocials;
  final CommentDisplayType pageDisplayType;
  final bool skeletonMode;
  
  const CustomCommentWidget({super.key, required this.commentData, required this.senderData, 
  required this.senderSocials, required this.pageDisplayType, required this.skeletonMode});

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
                        page: CommentLikesListWidget(
                          commentID: commentData.commentID, 
                          commentSender: commentData.sender
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
                        page: CommentBookmarksListWidget(
                          commentID: commentData.commentID, 
                          commentSender: commentData.sender
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
                  child: commentDataClass.sender == appStateClass.currentID ? 
                    CustomButton(
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
                      height: getScreenHeight() * 0.08,
                      buttonColor: Colors.transparent,
                      setBorderRadius: false,
                    )
                  : null
                ),     
                Container(
                  child: commentDataClass.sender == appStateClass.currentID ? 
                    CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => deleteComment(commentData, context), actionDelayTime) ;
                      },
                      buttonText: 'Delete comment',
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
    if(!widget.skeletonMode){
      if(commentData.deleted || senderData.suspended || senderData.deleted){
        return Container();
      }
      if(widget.pageDisplayType == CommentDisplayType.profileComment && !senderData.blocksCurrentID){}
      else if(senderData.mutedByCurrentID || senderData.blockedByCurrentID || senderData.blocksCurrentID){
        return Container();
      }
      if(senderData.private && !senderSocials.followedByCurrentID && senderData.userID != appStateClass.currentID){
        return Container();
      }
      if(widget.pageDisplayType == CommentDisplayType.bookmark && !commentData.bookmarkedByCurrentID){
        return Container();
      }
      List<MediaDatasClass> mediasDatas = (commentData.mediasDatas);
      UserDataClass parentPostSender = appStateClass.usersDataNotifiers.value[commentData.parentPostSender]!.notifier.value;
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
                                        () => runDelay(() => displayCommentBottomSheet(), actionDelayTime),
                                        Icon(Icons.more_horiz, size: moreIconProfileWidgetSize)
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('@${senderData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.lightBlue)),
                                      Text(getTimeDifference(commentData.uploadTime), style: TextStyle(fontSize: defaultTextFontSize * 0.675, color: Colors.grey))
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
                  Text("Replying to @${parentPostSender.username}'s ${commentData.parentPostType}", style: TextStyle(fontSize: defaultTextFontSize * 0.875, color: Colors.blueGrey)),
                  SizedBox(height: getScreenHeight() * 0.01),
                  const Divider(
                    color: Colors.white, height: 2.5, thickness: 1
                  ),
                  SizedBox(height: getScreenHeight() * 0.01),
                  DisplayTextComponent(
                    text: commentData.content, tagsPressable: true, overflow: TextOverflow.ellipsis, 
                    maxLines: 100, style: TextStyle(fontSize: defaultTextFontSize * 0.95), alignment: TextAlign.left, 
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
                                  parentPostType: 'comment',
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
                ],
              )
            )
          )
        )
      );
    }else{
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                            CircleAvatar(
                              radius: getScreenWidth() * 0.05,
                              backgroundImage: NetworkImage(defaultUserProfilePicLink),
                            ),
                            SizedBox(
                              width: getScreenWidth() * 0.02
                            ),
                            Flexible(
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: SizedBox(
                                  height: getScreenHeight() * 0.055,
                                  width: double.infinity,
                                )
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ),
                  SizedBox(height: getScreenHeight() * 0.01),
                  Card(
                    margin: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: getScreenHeight() * 0.025
                    )
                  ),
                  SizedBox(height: getScreenHeight() * 0.01),
                  const Divider(
                    color: Colors.white, height: 2.5, thickness: 1
                  ),
                  SizedBox(height: getScreenHeight() * 0.01),
                  for(int i = 0; i < 3; i++)
                  Column(
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: SizedBox(
                          width: double.infinity,
                          height: getScreenHeight() * 0.025
                        )
                      ),
                      SizedBox(height: i < 2 ? getScreenHeight() * 0.005 : 0)
                    ],
                  ),
                  SizedBox(height: getScreenHeight() * 0.01),
                  const Divider(
                    color: Colors.white, height: 2.5, thickness: 1
                  ),
                  SizedBox(height: getScreenHeight() * 0.005),
                  Card(
                    margin: EdgeInsets.zero,
                    child: SizedBox(
                      width: double.infinity,
                      height: getScreenHeight() * 0.045
                    )
                  )
                ],
              ),
            )
          )
        )
      );
    }
  }
}