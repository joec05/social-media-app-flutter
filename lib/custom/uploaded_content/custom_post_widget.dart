import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class CustomPostWidget extends StatefulWidget{
  final PostClass postData;
  final UserDataClass senderData;
  final UserSocialClass senderSocials;
  final PostDisplayType pageDisplayType;
  final bool skeletonMode;

  const CustomPostWidget({
    super.key, required this.postData, required this.senderData, 
    required this.senderSocials, required this.pageDisplayType, required this.skeletonMode
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
                  text: 'View likes',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  color: Colors.transparent,
                  setBorderRadius: false,
                  prefix: null,
                  loading: false
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
                  text: 'View bookmarks',
                  width: double.infinity,
                  height: getScreenHeight() * 0.08,
                  color: Colors.transparent,
                  setBorderRadius: false,
                  prefix: null,
                  loading: false
                ),
                Container(
                  child: postData.sender == appStateRepo.currentID ? 
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
                      text: 'Edit post',
                      width: double.infinity,
                      height: getScreenHeight() * 0.08,
                      color: Colors.transparent,
                      setBorderRadius: false,
                      prefix: null,
                      loading: false
                    )
                  : null
                ), 
                Container(
                  child: postData.sender == appStateRepo.currentID ? 
                    CustomButton(
                      onTapped: (){
                        Navigator.pop(bottomSheetContext);
                        runDelay(() => deletePost(context, postData), actionDelayTime);
                      },
                      text: 'Delete post',
                      width: double.infinity,
                      height: getScreenHeight() * 0.08,
                      color: Colors.transparent,
                      setBorderRadius: false,
                      prefix: null,
                      loading: false
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
      if(postData.deleted || senderData.suspended || senderData.deleted){
        return Container();
      }
      if(widget.pageDisplayType == PostDisplayType.profilePost && !senderData.blocksCurrentID){}
      else if(senderData.mutedByCurrentID || senderData.blockedByCurrentID || senderData.blocksCurrentID){
        return Container();
      }
      if(senderData.private && !senderSocials.followedByCurrentID && senderData.userID != appStateRepo.currentID){
        return Container();
      }
      if(widget.pageDisplayType == PostDisplayType.bookmark && !postData.bookmarkedByCurrentID){
        return Container();
      }
      List<MediaDatasClass> mediasDatas = (postData.mediasDatas);
    
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Theme.of(context).cardColor,
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
                                  border: Border.all(width: 2),
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
                                      Text('@${senderData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.cyanAccent)),
                                      Text(getTimeDifference(postData.uploadTime), style: TextStyle(fontSize: defaultTextFontSize * 0.675))
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
                  Divider(
                    color: Theme.of(context).dividerColor,
                    height: 2.5, 
                    thickness: 1
                  ),
                  SizedBox(height: getScreenHeight() * 0.01),
                  DisplayTextComponent(
                    text: postData.content, 
                    tagsPressable: true, 
                    overflow: TextOverflow.ellipsis, 
                    maxLines: 100, 
                    style: TextStyle(fontSize: defaultTextFontSize * 0.95, color: Theme.of(context).textTheme.labelMedium!.color), 
                    alignment: TextAlign.left, 
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
                  Divider(
                    color: Theme.of(context).dividerColor,
                    height: 2.5, 
                    thickness: 1
                  ),
                  SizedBox(height: getScreenHeight() * 0.005),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      generatePostActionWidget(
                        (){
                          runDelay((){
                            if(postData.likedByCurrentID){
                              unlikePost(context, postData);
                            }else{
                              likePost(context, postData);
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
                              unbookmarkPost(context, postData);
                            }else{
                              bookmarkPost(context, postData);
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
                            const Icon(FontAwesomeIcons.solidComment, size: 20),
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
    }else{
      return Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
        color: Theme.of(context).cardColor,
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
                  Divider(
                    color: Theme.of(context).dividerColor,
                    height: 2.5, 
                    thickness: 1
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
                  Divider(
                    color: Theme.of(context).dividerColor,
                    height: 2.5, 
                    thickness: 1
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