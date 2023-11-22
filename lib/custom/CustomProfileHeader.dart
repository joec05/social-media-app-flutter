import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/EditUserProfile.dart';
import 'package:social_media_app/ProfileFollowersPage.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/class/UserSocialClass.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';
import '../PrivateChatRoom.dart';
import '../ProfileFollowingPage.dart';
import '../class/UserDataClass.dart';
import 'CustomButton.dart';

var dio = Dio();

class CustomProfileHeader extends StatefulWidget{
  final UserSocialClass userSocials;
  final UserDataClass userData;
  final String userID;
  
  const CustomProfileHeader({super.key, required this.userID, required this.userData, required this.userSocials});

  @override
  State<CustomProfileHeader> createState() =>_CustomProfileHeaderState();
}

class _CustomProfileHeaderState extends State<CustomProfileHeader>{
  late UserDataClass userData;
  late UserSocialClass userSocials;
  late String userID;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    userData = widget.userData;
    userSocials = widget.userSocials;
  }

  @override void dispose(){
    super.dispose();
  }

  String convertDateTimeDisplay(String dateTime){
    List<String> separatedDateTime = dateTime.substring(0, 10).split('-').reversed.toList();
    List<String> months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    separatedDateTime[1] = months[int.parse(separatedDateTime[1])];
    return separatedDateTime.join(' ');
  }

  

  @override
  Widget build(BuildContext context) {
    String currentID = fetchReduxDatabase().currentID;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding, vertical: defaultVerticalPadding),
      child: Column(
        children: [
          Container(
            width: getScreenWidth() * 0.25, height: getScreenWidth() * 0.25,
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
          SizedBox(
            height: getScreenHeight() * 0.0075
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: userData.name,
                        style: const TextStyle(fontSize: 22.5),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle, 
                        child: userData.verified && !userData.suspended && !userData.deleted ?
                          Container(
                            margin: EdgeInsets.only(left: iconsBesideNameProfileMargin),
                            child: Icon(Icons.verified_rounded, size: lockIconProfileWidgetSize),
                          )
                        : 
                          Container(
                            margin: const EdgeInsets.only(left: 0),
                            child: const Icon(Icons.verified_rounded, size: 0),
                          )
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle, 
                        child: userData.private && !userData.suspended && !userData.deleted ?
                          Container(
                            margin: EdgeInsets.only(left: iconsBesideNameProfileMargin),
                            child: Icon(FontAwesomeIcons.lock, size: lockIconProfileWidgetSize),
                          )
                        : 
                          Container(
                            margin: const EdgeInsets.only(left: 0),
                            child: const Icon(FontAwesomeIcons.lock, size: 0),
                          )
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle, 
                        child: userData.mutedByCurrentID && !userData.suspended && !userData.deleted ?
                          Container(
                            margin: EdgeInsets.only(left: iconsBesideNameProfileMargin),
                            child: Icon(FontAwesomeIcons.volumeXmark, size: muteIconProfileWidgetSize),
                          )
                        :
                          Container(
                            margin: const EdgeInsets.only(left: 0),
                            child: const Icon(FontAwesomeIcons.volumeXmark, size: 0),
                          )
                      ),
                    ],
                  ),
                )
              ),
            ],
          ),
          SizedBox(
            height: getScreenHeight() * 0.005
          ),
          Text(userData.suspended || userData.deleted ? '@' : '@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize, color: Colors.lightBlue)),
          !userData.blocksCurrentID && !userData.suspended && !userData.deleted ?
            Column(
              children: [
                userData.bio.isNotEmpty ?
                  Column(
                    children: [
                      SizedBox(
                        height: getScreenHeight() * 0.0175
                      ),
                      Text(userData.bio, style: TextStyle(fontSize: defaultTextFontSize), textAlign: TextAlign.left,)
                    ]
                  )
                  : Container(),
                SizedBox(
                  height: getScreenHeight() * 0.0175
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: (){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: ProfilePageFollowersWidget(userID: userID)
                          )
                        ), navigatorDelayTime);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(displayShortenedCount(userSocials.followersCount), style: const TextStyle(fontSize: 17.5)),
                          Text('Followers', style: TextStyle(fontSize: defaultTextFontSize),)
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: (){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: ProfilePageFollowingWidget(userID: userID)
                          )
                        ), navigatorDelayTime);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(displayShortenedCount(userSocials.followingCount), style: const TextStyle(fontSize: 17.5)),
                          Text('Following', style: TextStyle(fontSize: defaultTextFontSize),)
                        ],
                      ),
                    ),
                    
                  ],
                ),
                SizedBox(
                  height: getScreenHeight() * 0.0175
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end, 
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end, 
                          children: [
                            Icon(Icons.person, size: 20)
                          ]
                        ),
                        SizedBox(
                          width: getScreenWidth() * 0.0075,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end, 
                          children: [
                            Text('Joined at ${convertDateTimeDisplay(userData.dateJoined)}', style: const TextStyle(fontSize: 14.5))      
                          ]
                        )
                      ]
                    ),
                    SizedBox(height: getScreenHeight() * 0.004),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end, 
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end, 
                          children: [
                            Icon(Icons.cake, size: 20)
                          ]
                        ),
                        SizedBox(
                          width: getScreenWidth() * 0.0075,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end, 
                          children: [
                            Text('Born at ${convertDateTimeDisplay(userData.birthDate)}', style: const TextStyle(fontSize: 14.5))      
                          ]
                        )
                      ]
                    ),
                  ],
                ),
                SizedBox(
                  height: getScreenHeight() * 0.0175
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomButton(
                      width: userID == fetchReduxDatabase().currentID ? getScreenWidth() * 0.8 : getScreenWidth() * 0.4, height: getScreenHeight() * 0.065, 
                      buttonColor: userData.blockedByCurrentID ? Colors.red : const Color.fromARGB(255, 70, 125, 170), onTapped: (){
                        if(userData.suspended && userData.deleted){
                          null;
                        }else if(userData.userID == fetchReduxDatabase().currentID){
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
                      userData.userID == fetchReduxDatabase().currentID ? 'Edit Profile'
                      : userData.requestedByCurrentID ? 'Cancel Request' :
                      userSocials.followedByCurrentID ? 'Unfollow' : 'Follow',
                      setBorderRadius: true,
                    ),
                    userID != fetchReduxDatabase().currentID ?
                      CustomButton(
                        width: getScreenWidth() * 0.4, height: getScreenHeight() * 0.065, 
                        buttonColor: Colors.blue, onTapped: userData.blockedByCurrentID || userData.blocksCurrentID || userData.suspended && userData.deleted ? null : (){
                          runDelay(() => Navigator.push(
                            context,
                            SliderRightToLeftRoute(
                              page: PrivateChatRoomWidget(chatID: null, recipient: userData.userID)
                            )
                          ), navigatorDelayTime);
                        },
                        buttonText: 'Message',
                        setBorderRadius: true,
                      )
                    : Container()
                  ],
                )
              ]
            ) 
          : Container(),
          userData.deleted ?
            Container(
              margin: EdgeInsets.only(top: getScreenHeight() * 0.025),
              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.025, vertical: getScreenHeight() * 0.025),
              decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.white), borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.trash, size: 35),
                  SizedBox(height: getScreenHeight() * 0.0225),
                  Text("${userData.name}'s account has been deleted", style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600))
                ],
              ),
            )
          : Container(),
          userData.suspended ?
            Container(
              margin: EdgeInsets.only(top: getScreenHeight() * 0.025),
              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.025, vertical: getScreenHeight() * 0.025),
              decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.white), borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.userSlash, size: 35),
                  SizedBox(height: getScreenHeight() * 0.0225),
                  Text("${userData.name}'s account has been suspended", style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600))
                ],
              ),
            )
          : Container(),
          userData.blocksCurrentID && !userData.suspended && !userData.deleted ?
            Container(
              margin: EdgeInsets.only(top: getScreenHeight() * 0.025),
              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.025, vertical: getScreenHeight() * 0.025),
              decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.white), borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.userXmark, size: 35),
                  SizedBox(height: getScreenHeight() * 0.0225),
                  Text("You have been blocked from accessing ${userData.name}'s account", style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600))
                ],
              ),
            )
          : Container(),
          userData.private && !userSocials.followedByCurrentID && userData.userID != currentID && !userData.suspended && !userData.deleted ?
            Container(
              margin: EdgeInsets.only(top: getScreenHeight() * 0.025),
              padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.025, vertical: getScreenHeight() * 0.025),
              decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.white), borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: Column(
                children: [
                  const Icon(FontAwesomeIcons.userLock, size: 35),
                  SizedBox(height: getScreenHeight() * 0.0225),
                  Text("You have been restricted from accessing ${userData.name}'s private account", style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600))
                ],
              ),
            )
          : Container()
        ],
      )
    );
  }

}