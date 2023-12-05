import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../EditUserProfile.dart';
import '../ProfilePage.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import '../class/UserDataClass.dart';
import '../class/UserSocialClass.dart';
import '../extenstions/StringEllipsis.dart';
import 'CustomButton.dart';

var dio = Dio();

class CustomUserDataWidget extends StatefulWidget{
  final UserDataClass userData;
  final UserSocialClass userSocials;
  final UserDisplayType userDisplayType;
  final String? profilePageUserID;
  final bool? isLiked;
  final bool? isBookmarked;
  
  const CustomUserDataWidget({
    super.key, required this.userData, required this.userSocials, required this.userDisplayType, 
    required this.profilePageUserID, required this.isLiked, required this.isBookmarked
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
    if(widget.userDisplayType == UserDisplayType.followers || widget.userDisplayType == UserDisplayType.following){
      if(userData.blockedByCurrentID || userData.blocksCurrentID){
        return Container();
      }
      if(widget.profilePageUserID == appStateClass.currentID){
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
    if(userData.userID == appStateClass.currentID){
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
      color: Colors.transparent,
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
                                border: Border.all(width: 2, color: Colors.white),
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
                                    Text('@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.8, color: Colors.lightBlue)),
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
                        buttonColor: userData.blockedByCurrentID ? Colors.red : const Color.fromARGB(255, 70, 125, 170), 
                        onTapped: (){
                          if(userData.userID == appStateClass.currentID){
                            runDelay(() => Navigator.push(
                              context,
                              SliderRightToLeftRoute(
                                page: const EditProfileStateless()
                              )
                            ), navigatorDelayTime);
                          }else{
                            if(userData.blockedByCurrentID){
                              unblockUser(userData);
                            }else if(userSocials.followedByCurrentID){
                              unfollowUser(userData, userSocials);
                            }else if(userData.requestedByCurrentID){
                              cancelFollowRequest(userData);
                            }else{
                              followUser(userData, userSocials);
                            }
                          }
                        },
                        buttonText: userData.blockedByCurrentID ? 'Unblock' :
                        userData.userID == appStateClass.currentID ? 'Edit Profile'
                        : userData.requestedByCurrentID ? 'Cancel Request' :
                        userSocials.followedByCurrentID ? 'Unfollow' : 'Follow',
                        setBorderRadius: true,
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
  }
}