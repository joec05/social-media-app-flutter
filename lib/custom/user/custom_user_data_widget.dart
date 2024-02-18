import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class CustomUserDataWidget extends StatefulWidget{
  final UserDataClass userData;
  final UserSocialClass userSocials;
  final UserDisplayType userDisplayType;
  final String? profilePageUserID;
  final bool? isLiked;
  final bool? isBookmarked;
  final bool skeletonMode;
  
  const CustomUserDataWidget({
    super.key, required this.userData, required this.userSocials, required this.userDisplayType, 
    required this.profilePageUserID, required this.isLiked, required this.isBookmarked, 
    required this.skeletonMode
  });

  @override
  State<CustomUserDataWidget> createState() =>_CustomUserDataWidgetState();
}

class _CustomUserDataWidgetState extends State<CustomUserDataWidget>{

  late UserDataClass userData;
  late UserSocialClass userSocials;

  @override initState(){
    super.initState();
    userData = widget.userData;
    userSocials = widget.userSocials;
  }

  @override void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    if(!widget.skeletonMode){
      if(widget.userDisplayType == UserDisplayType.followers || widget.userDisplayType == UserDisplayType.following){
        if(userData.blockedByCurrentID || userData.blocksCurrentID){
          return Container();
        }
        if(widget.profilePageUserID == appStateRepo.currentID){
          if(widget.userDisplayType == UserDisplayType.followers){
            if(!userSocials.followsCurrentID){
              return Container();
            }
          }else if(widget.userDisplayType == UserDisplayType.following){
            if(!userSocials.followedByCurrentID){
              return Container();
            }
          }
        }
      }
      if(userData.userID == appStateRepo.currentID){
        if(widget.userDisplayType == UserDisplayType.likes){
          if(!widget.isLiked!){
            return Container();
          }
        }

        if(widget.userDisplayType == UserDisplayType.bookmarks){
          if(!widget.isBookmarked!){
            return Container();
          }
        }
      }
      if(widget.userDisplayType != UserDisplayType.searchedUsers){
        if(userData.suspended || userData.deleted){
          return Container();
        }
      }
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
                  page: ProfilePageWidget(userID: userData.userID)
                ),
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
                                    page: ProfilePageWidget(userID: userData.userID)
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
                                      userData.profilePicLink
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
                                                StringEllipsis.convertToEllipsis(userData.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize * 0.9, fontWeight: FontWeight.bold)
                                              )
                                            ),
                                            userData.verified && !userData.suspended && !userData.deleted ?
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: iconsBesideNameProfileMargin
                                                  ),
                                                  Icon(Icons.verified_rounded, size: verifiedIconProfileWidgetSize),
                                                ]
                                              )
                                            : Container(),
                                            userData.private && !userData.suspended && !userData.deleted ?
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: iconsBesideNameProfileMargin
                                                  ),
                                                  Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                                                ],
                                              )
                                            : Container(),
                                            userData.mutedByCurrentID ?
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: iconsBesideNameProfileMargin
                                                  ),
                                                  Icon(FontAwesomeIcons.volumeXmark, size: muteIconProfileWidgetSize),
                                                ],
                                              )
                                            : Container(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text('@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.cyanAccent)),
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
                  userData.bio.isNotEmpty && !userData.blocksCurrentID && !userData.suspended && !userData.deleted ?
                    Column(
                      children: [
                        SizedBox(height: getScreenHeight() * 0.015),
                        Text(userData.bio, maxLines: 3, style: TextStyle(fontSize: defaultTextFontSize * 0.85)),
                      ],
                    )
                  : Container(),
                  !userData.blocksCurrentID && !userData.suspended && !userData.deleted ?
                    Column(
                      children: [
                        SizedBox(height: getScreenHeight() * 0.015),
                        CustomButton(
                          width: double.infinity, height: getScreenHeight() * 0.055, 
                          color: userData.blockedByCurrentID ? Colors.red : const Color.fromARGB(255, 70, 125, 170), 
                          onTapped: (){
                            if(userData.userID == appStateRepo.currentID){
                              runDelay(() => Navigator.push(
                                context,
                                SliderRightToLeftRoute(
                                  page: const EditProfileStateless()
                                )
                              ), navigatorDelayTime);
                            }else{
                              if(userData.blockedByCurrentID){
                                unblockUser(context, userData);
                              }else if(userSocials.followedByCurrentID){
                                unfollowUser(context, userData, userSocials);
                              }else if(userData.requestedByCurrentID){
                                cancelFollowRequest(context, userData);
                              }else{
                                followUser(context, userData, userSocials);
                              }
                            }
                          },
                          text: userData.blockedByCurrentID ? 'Unblock' :
                          userData.userID == appStateRepo.currentID ? 'Edit Profile'
                          : userData.requestedByCurrentID ? 'Cancel Request' :
                          userSocials.followedByCurrentID ? 'Unfollow' : 'Follow',
                          setBorderRadius: true,
                          prefix: null,
                          loading: false
                        ),
                      ],
                    )
                  : Container()
                ]
              )
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
            onTap: (){
              runDelay(() => Navigator.push(
                context,
                SliderRightToLeftRoute(
                  page: ProfilePageWidget(userID: userData.userID)
                ),
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
                  Column(
                    children: [
                      SizedBox(height: getScreenHeight() * 0.015),
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
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(height: getScreenHeight() * 0.015),
                      Card(
                        margin: EdgeInsets.zero,
                        child: CustomButton(
                          width: double.infinity, height: getScreenHeight() * 0.055, 
                          color: Colors.transparent, 
                          onTapped: (){},
                          text: '',
                          setBorderRadius: true,
                          prefix: null,
                          loading: false
                        ),
                      ),
                    ],
                  )
                ]
              )
            )
          )
        )
      ); 
    }
  }
}