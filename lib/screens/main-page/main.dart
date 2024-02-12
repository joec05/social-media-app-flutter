import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:social_media_app/global_files.dart';

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
    authRepo.initializeAuthListener();
    runApp(const MyApp());
  } catch (_) {
    debugPrint("An error occured when starting the app");
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
      home: const OnboardingPage()
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
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
    if(mounted) {
      try {
        Map lifecycleData = await SharedPreferencesClass().fetchCurrentUser();
        if(mounted) {
          if(lifecycleData['user_id'].isEmpty){
            isLoginToAccount.value = false;
          }else{
            bool hasPassedLoginLimit = DateTime.now().difference(DateTime.parse(lifecycleData['last_lifecycle_time']).toLocal()).inMinutes > timeDifferenceToLogOut;
            if(!hasPassedLoginLimit) {
              var verifyAccountExistence = await checkAccountExists(lifecycleData['user_id']);
              if(verifyAccountExistence != null && mounted) {
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
                    isLoginToAccount.value = true;
                  }
                }else{
                  isLoginToAccount.value = false;
                }
              }else{
                isLoginToAccount.value = false;
              }
            }else{
              isLoginToAccount.value = false;
            }
          }
        }
      } catch (_) {
        if(mounted) {
          handler.displaySnackbar(
            context, 
            SnackbarType.error, 
            tErr.unknown
          );
        }
      }
    }
  }

  Future<dynamic> checkAccountExists(String userID) async{
    dynamic res = await fetchDataRepo.fetchData(
      context, 
      RequestGet.checkAccountExists, 
      {
        'userID': userID
      }
    );
    return res;
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