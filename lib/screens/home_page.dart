import 'package:flutter/material.dart';
import 'package:social_media_app/global_files.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  void connect(){
    socket.connect();
    socket.on('error', (_) => debugPrint("Sorry, there seems to be an issue with the connection!"));
    socket.on('connect_error', (err) => debugPrint('$err'));
    socket.on('connect', (_){
      String ? id = socket.id!;
      if(mounted){
        appStateRepo.socketID = id;
      }
      debugPrint('$id is socket id');
    });
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
    }
  }

  @override void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          const Text('Social Media App', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                          SizedBox(height: getScreenHeight() * 0.085),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[                        
                          CustomButton(
                            width: getScreenWidth() * 0.6, height: getScreenHeight() * 0.075, 
                            color: const Color.fromARGB(255, 151, 145, 87), text: 'Sign Up', 
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
                            setBorderRadius: true,
                            prefix: null,
                            loading: false,
                          ),
                          SizedBox(height: getScreenHeight() * 0.02),
                          CustomButton(
                            width: getScreenWidth() * 0.6, height: getScreenHeight() * 0.075, 
                            color: const Color.fromARGB(255, 151, 145, 87), text: 'Login With Email', 
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
                            setBorderRadius: true,
                            prefix: null,
                            loading: false,
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
  }
}