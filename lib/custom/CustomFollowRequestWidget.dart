import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../ProfilePage.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import '../class/UserDataClass.dart';
import '../class/UserSocialClass.dart';
import '../extenstions/StringEllipsis.dart';
import 'CustomButton.dart';

var dio = Dio();

class CustomFollowRequestWidget extends StatefulWidget{
  final UserDataClass userData;
  final UserSocialClass userSocials;
  final FollowRequestType followRequestType;
  
  const CustomFollowRequestWidget({super.key, required this.userData, required this.userSocials, required this.followRequestType});

  @override
  State<CustomFollowRequestWidget> createState() =>_CustomFollowRequestWidgetState();
}

class _CustomFollowRequestWidgetState extends State<CustomFollowRequestWidget>{

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
    if(userData.blocksCurrentID || userData.blockedByCurrentID || userData.suspended || userData.deleted){
      return Container();
    }

    if(widget.followRequestType == FollowRequestType.From){
      if(!userData.requestedByCurrentID){
        return Container();
      }
    }

    if(widget.followRequestType == FollowRequestType.To){
      if(!userData.requestsToCurrentID){
        return Container();
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding / 2, vertical: defaultVerticalPadding / 2),
      color: Colors.transparent,
      child:Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (){
            runDelay(() => Navigator.push(
              context,
              SliderRightToLeftRoute(
                page: ProfilePageWidget(userID: userData.userID)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              ), navigatorDelayTime);
                            },
                            child: Container(
                              width: getScreenWidth() * 0.125, height: getScreenWidth() * 0.125,
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
                                          Flexible(child: Text(StringEllipsis.convertToEllipsis(userData.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.bold))),
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
                                          userData.mutedByCurrentID && !userData.suspended && !userData.deleted ?
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
                              ],
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                  ]
                ),
                SizedBox(height: getScreenHeight() * 0.02),
                Container(
                  child: widget.followRequestType == FollowRequestType.From ?
                    CustomButton(
                      width: double.infinity, height: getScreenHeight() * 0.055, 
                      buttonColor: Colors.red, onTapped: (){
                        cancelFollowRequest(userData);
                      },
                      buttonText: 'Cancel Request',
                      setBorderRadius: false,
                    )
                  :
                    Row(
                      children: [
                        CustomButton(
                          width: getScreenWidth() * 0.4, height: getScreenHeight() * 0.055, 
                          buttonColor: Colors.red, onTapped: (){
                            rejectFollowRequest(userData);
                          },
                          buttonText: 'Reject',
                          setBorderRadius: false,
                        ),
                        SizedBox(width: getScreenWidth() * 0.1),
                        CustomButton(
                          width: getScreenWidth() * 0.4, height: getScreenHeight() * 0.055, 
                          buttonColor: Colors.lightBlue, onTapped: (){
                            acceptFollowRequest(userData.userID);
                          },
                          buttonText: 'Accept',
                          setBorderRadius: false,
                        )
                      ],
                    )
                )
              ]
            )
          )
        )
      )
    );
  }
}