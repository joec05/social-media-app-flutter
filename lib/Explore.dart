import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/Searched.dart';
import 'package:social_media_app/class/HashtagClass.dart';
import 'package:social_media_app/custom/CustomButton.dart';
import 'package:social_media_app/custom/CustomHashtagWidget.dart';
import 'package:social_media_app/mixin/LifecycleListenerMixin.dart';
import 'package:social_media_app/styles/AppStyles.dart';
import 'package:social_media_app/appdata/GlobalLibrary.dart';
import 'package:social_media_app/transition/RightToLeftTransition.dart';

var dio = Dio();

class ExploreWidget extends StatelessWidget {
  const ExploreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ExploreWidgetStateful();
  }
}

class _ExploreWidgetStateful extends StatefulWidget {
  const _ExploreWidgetStateful();

  @override
  State<_ExploreWidgetStateful> createState() => __ExploreWidgetStatefulState();
}

class __ExploreWidgetStatefulState extends State<_ExploreWidgetStateful> with AutomaticKeepAliveClientMixin, LifecycleListenerMixin {
  TextEditingController searchedController = TextEditingController();
  ValueNotifier<List<HashtagClass>> hashtags = ValueNotifier([]);
  ValueNotifier<bool> verifySearchedFormat = ValueNotifier(false);
  ValueNotifier<bool> displayFloatingBtn = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState(){
    super.initState();
    runDelay(() async => fetchHashtagsData(), actionDelayTime);
    searchedController.addListener(() {
      if(mounted){
        verifySearchedFormat.value = searchedController.text.isNotEmpty;
      }
    });
    _scrollController.addListener(() {
      if(mounted){
        if(_scrollController.position.pixels > animateToTopMinHeight){
          if(!displayFloatingBtn.value){
            displayFloatingBtn.value = true;
          }
        }else{
          if(displayFloatingBtn.value){
            displayFloatingBtn.value = false;
          }
        }
      }
    });
  }

  @override void dispose(){
    super.dispose();
    searchedController.dispose();
    hashtags.dispose();
    displayFloatingBtn.dispose();
    _scrollController.dispose();
  }

  Future<void> fetchHashtagsData() async{
    try {
      String stringified = jsonEncode({
        'paginationLimit': 5,
      });
      if(mounted){
        hashtags.value = [];
      }
      var res = await dio.get('$serverDomainAddress/users/fetchTopHashtags', data: stringified);
      if(res.data.isNotEmpty){
        List hashtagsData = res.data['hashtagsData'];
        for(int i = 0; i < hashtagsData.length; i++){
          Map hashtagData = hashtagsData[i];
          if(mounted){
            hashtags.value = [...hashtags.value, HashtagClass(hashtagData['hashtag'], hashtagData['hashtag_count'])];
          }
        }
      }
    } on Exception catch (e) {
      doSomethingWithException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => fetchHashtagsData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          children: [
            Row(
              children: [
                SizedBox(
                  width: getScreenWidth() * 0.75,
                  height: getScreenHeight() * 0.075,
                  child: TextField(
                    controller: searchedController,
                    decoration: generateSearchTextFieldDecoration('your interests'),
                  )
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: verifySearchedFormat,
                  builder: (context, bool searchedVerified, child){
                    return CustomButton(
                      width: getScreenWidth() * 0.25, height: getScreenHeight() * 0.075, 
                      buttonColor: Colors.red, buttonText: 'Search',
                      onTapped: searchedVerified ? (){
                        runDelay(() => Navigator.push(
                          context,
                          SliderRightToLeftRoute(
                            page: SearchedWidget(searchedText: searchedController.text)
                          )
                        ), navigatorDelayTime);
                      } : null,
                      setBorderRadius: false
                    );
                  }
                )
              ],
            ),
            ValueListenableBuilder(
              valueListenable: hashtags, 
              builder: (context, hashtagsValue, child){
                return Column(
                  children: [
                    for(int i = 0; i < hashtagsValue.length; i++)
                    CustomHashtagDataWidget(hashtagData: hashtagsValue[i], key: UniqueKey())
                  ],
                );
              }
            )
          ],
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: displayFloatingBtn,
        builder: (BuildContext context, bool visible, Widget? child) {
          return Visibility(
            visible: visible,
            child: FloatingActionButton( 
              heroTag: UniqueKey(),
              onPressed: () {  
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 10),
                  curve:Curves.fastOutSlowIn
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          );
        }
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
