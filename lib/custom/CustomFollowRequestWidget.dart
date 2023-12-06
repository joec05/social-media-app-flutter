import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
  final bool skeletonMode;
  
  const CustomFollowRequestWidget({
    super.key, required this.userData, required this.userSocials, required this.followRequestType,
    required this.skeletonMode
  });

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
    if(!widget.skeletonMode){
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (){
              runDelay(() => Navigator.push(
                context,
                SliderRightToLeftRoute(
                  page: ProfilePageWidget(userID: userData.userID)
                )
              ), 0);
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
                  SizedBox(height: getScreenHeight() * 0.015),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Skeleton.replace(
                                    width: getScreenWidth() * 0.1, 
                                    height: getScreenWidth() * 0.1,
                                    child: CircleAvatar(
                                      radius: getScreenWidth() * 0.05,
                                      backgroundImage: const NetworkImage(''),
                                    )
                                  ),
                                  SizedBox(
                                    width: getScreenWidth() * 0.02
                                  ),
                                  Flexible(
                                    child: Card(
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
                      )
                    ]
                  ),
                  SizedBox(height: getScreenHeight() * 0.015),
                  Card(
                    child: CustomButton(
                      width: double.infinity, height: getScreenHeight() * 0.055, 
                      buttonColor: Colors.transparent, 
                      onTapped: (){},
                      buttonText: '',
                      setBorderRadius: true,
                    ),
                  ),
                ]
              )
            )
          )
        )
      );
    }
  }
}