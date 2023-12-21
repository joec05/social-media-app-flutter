import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/chats.dart';
import 'package:social_media_app/login_with_email.dart';
import 'package:social_media_app/login_with_username.dart';
import 'package:social_media_app/sign_up.dart';
import 'package:social_media_app/caching/sqlite_configuration.dart';
import 'package:social_media_app/class/shared_preferences_class.dart';
import 'package:social_media_app/custom/custom_button.dart';
import 'package:social_media_app/firebase/firebase_constants.dart';
import 'package:social_media_app/observer/global_observer.dart';
import 'package:social_media_app/socket/main.dart';
import 'package:social_media_app/state/main.dart';
import 'package:social_media_app/styles/app_styles.dart';
import 'package:social_media_app/transition/right_to_left_transition.dart';
import 'main_page.dart';
import 'package:social_media_app/appdata/global_library.dart';

void main() async{
  try {
    WidgetsFlutterBinding.ensureInitialized();
    ByteData data = await PlatformAssetBundle().load('assets/certificate/ca.pem');
    SecurityContext.defaultContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
    await DatabaseHelper().initDatabase();
    GlobalObserver globalObserver = GlobalObserver();
    WidgetsBinding.instance.addObserver(globalObserver);
    await firebaseInitialization;
    await firebaseAppCheckInitialization;
    runApp(const MyApp());
  } on Exception catch (e) {
    doSomethingWithException(e);
  }
  //WidgetsBinding.instance.removeObserver(globalObserver);
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      onGenerateRoute: (settings) {
        if (settings.name == "/chats-list") {
          return generatePageRouteBuilder(settings, const ChatsWidget());
        }
        return null;
      },
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => const MyHomePage(title: 'Social Media App'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ValueNotifier<bool?> isLoginToAccount = ValueNotifier(null);  
  
  void connect(){
    socket.connect();
    socket.on('error', (_) => debugPrint("Sorry, there seems to be an issue with the connection!"));
    socket.on('connect_error', (err) => debugPrint('$err'));
    socket.on('connect', (_){
      String ? id = socket.id!;
      if(mounted){
        appStateClass.socketID = id;
      }
      debugPrint('$id is socket id');
    });
  }

  void defaultLogin() async{
    try {
      Map lifecycleData = await SharedPreferencesClass().fetchCurrentUser();
      if(lifecycleData['user_id'].isEmpty){
        if(mounted){
          isLoginToAccount.value = false;
        }
      }else{
        bool hasPassedLoginLimit =  DateTime.now().difference(DateTime.parse(lifecycleData['last_lifecycle_time']).toLocal()).inMinutes > timeDifferenceToLogOut;
        if(!hasPassedLoginLimit){
          var verifyAccountExistence = await checkAccountExists(lifecycleData['user_id']);
          if(verifyAccountExistence['message'] == 'Successfully checked account existence'){
            if(verifyAccountExistence['exists'] == true){
              appStateClass.currentID = lifecycleData['user_id'];
              runDelay(() => Navigator.pushAndRemoveUntil(
                context,
                SliderRightToLeftRoute(
                  page: const MainPageWidget()
                ),
                (Route<dynamic> route) => false
              ), navigatorDelayTime);
              if(mounted){
                isLoginToAccount.value = true;
              }
            }
          }else{
            if(mounted){
              isLoginToAccount.value = false;
            }
          }
        }else{
          if(mounted){
            isLoginToAccount.value = false;
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  Future<dynamic> checkAccountExists(String userID) async{
    var dio = Dio();
    String stringified = jsonEncode({
      'userID': userID
    });
    var res = await dio.get('$serverDomainAddress/users/checkAccountExists', data: stringified);
    return res.data;
  }

  @override
  void initState() {
    super.initState();
    if(mounted){
      connect();
      defaultLogin();
    }
  }

  @override void dispose(){
    super.dispose();
    isLoginToAccount.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isLoginToAccount,
      builder: (context, bool? isLoginToAccountValue, child){
        if(isLoginToAccountValue == false){
          return Scaffold(
            body: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: defaultFrontPageDecoration,
                child: Stack(
                  children: [
                    Positioned(
                      left: -getScreenWidth() * 0.45,
                      top: -getScreenWidth() * 0.25,
                      child: Container(
                        width: getScreenWidth(),
                        height: getScreenWidth(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          color: Colors.amber.withOpacity(0.65)
                        ),
                      ),
                    ),
                    Positioned(
                      right: -getScreenWidth() * 0.55,
                      top: getScreenWidth() * 0.85,
                      child: Container(
                        width: getScreenWidth(),
                        height: getScreenWidth(),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(200),
                          color: Colors.blue.withOpacity(0.8)
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Text('Social Media App', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black)),
                                SizedBox(height: getScreenHeight() * 0.085),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[                        
                                CustomButton(
                                  width: getScreenWidth() * 0.6, height: getScreenHeight() * 0.075, 
                                  buttonColor: const Color.fromARGB(255, 151, 145, 87), buttonText: 'Sign Up', 
                                  onTapped: (){
                                    runDelay((){
                                      resetReduxData();
                                      runDelay(() => Navigator.push(
                                        context,
                                        SliderRightToLeftRoute(
                                          page: const SignUpStateless()
                                        )
                                      ), navigatorDelayTime);
                                    }, actionDelayTime);
                                  }, 
                                  setBorderRadius: true
                                ),
                                SizedBox(height: getScreenHeight() * 0.02),
                                CustomButton(
                                  width: getScreenWidth() * 0.6, height: getScreenHeight() * 0.075, 
                                  buttonColor: const Color.fromARGB(255, 151, 145, 87), buttonText: 'Login With Email', 
                                  onTapped: (){
                                    runDelay((){
                                      resetReduxData();
                                      runDelay(() => Navigator.push(
                                        context,
                                        SliderRightToLeftRoute(
                                          page: const LoginWithEmailStateless()
                                        )
                                      ), navigatorDelayTime);
                                    }, actionDelayTime);
                                  },
                                  setBorderRadius: true
                                ),
                                SizedBox(height: getScreenHeight() * 0.02),
                                CustomButton(
                                  width: getScreenWidth() * 0.6, height: getScreenHeight() * 0.075, 
                                  buttonColor: const Color.fromARGB(255, 151, 145, 87), buttonText: 'Login With Username', 
                                  onTapped: (){
                                    runDelay((){
                                      resetReduxData();
                                      runDelay(() => Navigator.push(
                                        context,
                                        SliderRightToLeftRoute(
                                          page: const LoginWithUsernameStateless()
                                        )
                                      ), navigatorDelayTime);
                                    }, actionDelayTime);
                                  },
                                  setBorderRadius: true
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )
              ),
            )
          );
        }else{
          if(isLoginToAccountValue == null){
            return Scaffold(
              body: Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: defaultFrontPageDecoration,
                  child: const Icon(FontAwesomeIcons.solidCircleUser, size: 100, color: Colors.black)
                )
              )
            );
          }
          return Scaffold(
            appBar: AppBar(
              leading: defaultLeadingWidget(context),
              title: const Text('Feed'), 
              titleSpacing: defaultAppBarTitleSpacing,
              flexibleSpace: Container(
                decoration: defaultAppBarDecoration
              )
            ),
            body: Container()
          );
        }
      }
    );
  }
}