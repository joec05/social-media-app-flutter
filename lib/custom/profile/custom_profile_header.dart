import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

class CustomProfileHeader extends StatefulWidget{
  final UserDataClass userData;
  final String userID;
  final bool skeletonMode;
  
  const CustomProfileHeader({super.key, required this.userID, required this.userData, required this.skeletonMode});

  @override
  State<CustomProfileHeader> createState() =>_CustomProfileHeaderState();
}

class _CustomProfileHeaderState extends State<CustomProfileHeader>{
  late UserDataClass userData;
  late String userID;

  @override
  void initState(){
    super.initState();
    userID = widget.userID;
    userData = widget.userData;
  }

  @override void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(!widget.skeletonMode){
      String currentID = appStateRepo.currentID;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: defaultHorizontalPadding, vertical: defaultVerticalPadding),
        child: Column(
          children: [
            Container(
              width: getScreenWidth() * 0.2, height: getScreenWidth() * 0.2,
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
            SizedBox(
              height: getScreenHeight() * 0.01
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
                          style: TextStyle(
                            fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize!,
                            color: Theme.of(context).textTheme.bodyLarge!.color!, 
                            fontWeight: FontWeight.bold
                          )
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
            Text(userData.suspended || userData.deleted ? '@' : '@${userData.username}', style: TextStyle(fontSize: defaultTextFontSize * 0.825, color: Colors.cyanAccent)),
            !userData.blocksCurrentID && !userData.suspended && !userData.deleted ?
              Column(
                children: [
                  userData.bio.isNotEmpty ?
                    Column(
                      children: [
                        SizedBox(
                          height: getScreenHeight() * 0.0125
                        ),
                        Text(userData.bio, style: TextStyle(fontSize: defaultTextFontSize), textAlign: TextAlign.center,)
                      ]
                    )
                    : Container(),
                  SizedBox(
                    height: getScreenHeight() * 0.0125
                  ),
                  ValueListenableBuilder(
                    valueListenable: appStateRepo.usersSocialsNotifiers.value[userID]!.notifier,
                    builder: ((context, UserSocialClass userSocials, child) {
                      return CustomButton(
                        width: getScreenWidth() * 0.55, 
                        height: getScreenHeight() * 0.065, 
                        color: userData.blockedByCurrentID ? Colors.red : const Color.fromARGB(255, 70, 125, 170), 
                        onTapped: (){
                          if(userData.suspended && userData.deleted){
                            null;
                          }else if(userData.userID == appStateRepo.currentID){
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
                      );
                    })
                  )
                ]
              ) 
            : Container(),
            userData.deleted ?
              Container(
                margin: EdgeInsets.only(top: getScreenHeight() * 0.025),
                padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.025, vertical: getScreenHeight() * 0.025),
                decoration: BoxDecoration(border: Border.all(width: 2), borderRadius: const BorderRadius.all(Radius.circular(10))),
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
                decoration: BoxDecoration(border: Border.all(width: 2), borderRadius: const BorderRadius.all(Radius.circular(10))),
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
                decoration: BoxDecoration(border: Border.all(width: 2), borderRadius: const BorderRadius.all(Radius.circular(10))),
                child: Column(
                  children: [
                    const Icon(FontAwesomeIcons.userXmark, size: 35),
                    SizedBox(height: getScreenHeight() * 0.0225),
                    Text("You have been blocked from accessing ${userData.name}'s account", style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600))
                  ],
                ),
              )
            : Container(),
            ValueListenableBuilder(
              valueListenable: appStateRepo.usersSocialsNotifiers.value[userID]!.notifier,
              builder: ((context, UserSocialClass userSocials, child) {
                return userData.private && !userSocials.followedByCurrentID && userData.userID != currentID && !userData.suspended && !userData.deleted ?
                  Container(
                    margin: EdgeInsets.only(top: getScreenHeight() * 0.025),
                    padding: EdgeInsets.symmetric(horizontal: getScreenWidth() * 0.025, vertical: getScreenHeight() * 0.025),
                    decoration: BoxDecoration(border: Border.all(width: 2), borderRadius: const BorderRadius.all(Radius.circular(10))),
                    child: Column(
                      children: [
                        const Icon(FontAwesomeIcons.userLock, size: 35),
                        SizedBox(height: getScreenHeight() * 0.0225),
                        Text("You have been restricted from accessing ${userData.name}'s private account", style: TextStyle(fontSize: defaultTextFontSize, fontWeight: FontWeight.w600))
                      ],
                    ),
                  )
                : Container();
              })
            ),
            !userData.blocksCurrentID && !userData.deleted && !userData.suspended ?
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: getScreenHeight() * 0.0225
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: appStateRepo.usersSocialsNotifiers.value[userData.userID]!.notifier,
                        builder: ((context, UserSocialClass userSocials, child) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
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
                                Text(displayShortenedCount(userSocials.followersCount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                SizedBox(height: getScreenHeight() * 0.0025),
                                Text(userSocials.followersCount == 1 ? 'Follower' : 'Followers', style: TextStyle(fontSize: defaultTextFontSize * 0.7),)
                              ],
                            ),
                          );
                        })
                      ),
                      SizedBox(
                        width: getScreenWidth() * 0.075,
                      ),
                      Container(
                        height: getScreenHeight() * 0.075 ,
                        color: Colors.grey,
                        width: 0.5,
                      ),
                      SizedBox(
                        width: getScreenWidth() * 0.075,
                      ),
                      ValueListenableBuilder(
                        valueListenable: appStateRepo.usersSocialsNotifiers.value[userData.userID]!.notifier,
                        builder: ((context, UserSocialClass userSocials, child) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
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
                                Text(displayShortenedCount(userSocials.followingCount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                SizedBox(height: getScreenHeight() * 0.0025),
                                Text('Following', style: TextStyle(fontSize: defaultTextFontSize * 0.7),)
                              ],
                            ),
                          );
                        })
                      ),
                    ],
                  ),
                  SizedBox(
                    height: getScreenHeight() * 0.02
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end, 
                            children: [
                              Icon(Icons.person, size: 15, color: Colors.blueGrey)
                            ]
                          ),
                          SizedBox(
                            width: getScreenWidth() * 0.0075,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end, 
                            children: [
                              Text(convertDateTimeDisplay(userData.dateJoined), style: TextStyle(fontSize: defaultTextFontSize * 0.75, color: Colors.blueGrey))      
                            ]
                          )
                        ]
                      ),
                      SizedBox(
                        width: getScreenWidth() * 0.06,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end, 
                            children: [
                              Icon(Icons.cake, size: 15, color: Colors.blueGrey)
                            ]
                          ),
                          SizedBox(
                            width: getScreenWidth() * 0.0075,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end, 
                            children: [
                              Text(convertDateTimeDisplay(userData.birthDate), style: TextStyle(fontSize: defaultTextFontSize * 0.75, color: Colors.blueGrey))      
                            ]
                          )
                        ]
                      ),
                    ],
                  ),
                ],
              )
            : Container(),
          ],
        ),
      );
    }else{
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: defaultHorizontalPadding, 
          vertical: defaultVerticalPadding
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: getScreenWidth() * 0.1,
              backgroundImage: NetworkImage(defaultUserProfilePicLink),
            ),
            SizedBox(
              height: getScreenHeight() * 0.01
            ),
            Card(
              margin: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                height: getScreenHeight() * 0.04
              )
            ),
            SizedBox(
              height: getScreenHeight() * 0.005
            ),
            Card(
              margin: EdgeInsets.zero,
              child: SizedBox(
                width: double.infinity,
                height: getScreenHeight() * 0.025
              )
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
            SizedBox(
               height: getScreenHeight() * 0.0225
            ),
            Card(
              margin: EdgeInsets.zero,
              child: CustomButton(
                width: getScreenWidth() * 0.55, height: getScreenHeight() * 0.055,
                color: Colors.transparent, 
                onTapped: (){},
                text: '',
                setBorderRadius: true,
                prefix: null,
                loading: false
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: getScreenHeight() * 0.0225
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: SizedBox(
                    height: getScreenHeight() * 0.075,
                    width: getScreenWidth() * 0.55
                  )
                ),
                SizedBox(
                  height: getScreenHeight() * 0.02
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: SizedBox(
                    height: getScreenHeight() * 0.025,
                    width: getScreenWidth() * 0.55
                  )
                ),
              ],
            )
          ],
        ),
      );
    }
  }

}