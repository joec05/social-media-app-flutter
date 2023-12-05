// ignore: file_names
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';

enum AudioState{
  mute, unmute
}

enum VideoSourceType{
  file, network, asset
}

enum DurationEndDisplay{
  remainingDuration, 
  totalDuration
}

class CustomVideoPlayer extends StatefulWidget {
  final VideoPlayerController playerController;
  final int skipDuration;
  final int rewindDuration;
  final VideoSourceType videoSourceType;
  final DurationEndDisplay durationEndDisplay;
  final bool displayMenu;
  final Color thumbColor;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color overlayBackgroundColor;
  final Color pressablesBackgroundColor;
  final int overlayDisplayDuration;
  final Alignment defaultAlignment;

  const CustomVideoPlayer({
    Key? key, required this.playerController, required this.skipDuration, 
    required this.rewindDuration, required this.videoSourceType,
    required this.durationEndDisplay, required this.displayMenu, required this.thumbColor,
    required this.activeTrackColor, required this.inactiveTrackColor,
    required this.overlayBackgroundColor, required this.pressablesBackgroundColor,
    required this.overlayDisplayDuration, required this.defaultAlignment
  }): super(key: key);

  @override
  CustomVideoPlayerState createState() => CustomVideoPlayerState();
}

class CustomVideoPlayerState extends State<CustomVideoPlayer> {
  ValueNotifier<VideoPlayerController> playerController = ValueNotifier(VideoPlayerController.asset(''));
  ValueNotifier<Duration> timeRemaining = ValueNotifier(Duration.zero);
  ValueNotifier<bool> overlayVisible = ValueNotifier(true);
  Timer? _overlayTimer;
  ValueNotifier<bool> isDraggingSlider = ValueNotifier(false); //this variable is necessary to prevent the slider updating as the video plays when the user is dragging the slider
  ValueNotifier<double> currentPosition = ValueNotifier(0.0);
  ValueNotifier<bool> hasPlayedOnce = ValueNotifier(false); //this variable is necessary to indicate that the user has played the video and will no longer display the play_circle icon
  ValueNotifier<String> displayCurrentDuration = ValueNotifier('00:00'); //this variable will be displayed indicating the current duration / slided duration
  TapDownDetails _doubleTapDetails = TapDownDetails();
  ValueNotifier<bool> isSkipping = ValueNotifier<bool>(false); //this variable is necessary to indicate the user has skipped the video and will display the icon as well as start the timer
  ValueNotifier<bool> isRewinding = ValueNotifier<bool>(false); //this variable is necessary to indicate the user has rewound the video and will display the icon as well as start the timer
  ValueNotifier<bool> isFullScreenValue = ValueNotifier(false); //this variable is necessary to indicate which icon to display depending on whether the user has opened the full or not
  AudioState audioState = AudioState.unmute; //this variable is neccessary to store the current state of the VideoPlayerController's audio: whether it is currently muted or unmuted
  double currentPlaybackSpeed = 1.0; //this variable is necessary to mark out the default current playback speed when trying to change the playback speed

  var standardTextFontSize = 14.5; //font size of the text in this page

  var videoControlActionIconSize = 50.0; //size of the play, pause, replay icons 

  var menuMainContainerButtonMargin = EdgeInsets.symmetric(vertical: 0.01 * PlatformDispatcher.instance.views.first.physicalSize.height/ PlatformDispatcher.instance.views.first.devicePixelRatio); //top and bottom margin of the buttons in the menu page

  var menuButtonWidth = 0.8 * PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio; //width of the buttons in the menu page

  var menuButtonStyle = ElevatedButton.styleFrom( //the styling of the buttons in the menu page
    backgroundColor: Colors.orange,
    fixedSize: Size(0.8 * PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio, 0.075 * PlatformDispatcher.instance.views.first.physicalSize.height/ PlatformDispatcher.instance.views.first.devicePixelRatio),
    textStyle: const TextStyle(
      fontSize: 16.9,
      fontWeight: FontWeight.w400
    )
  );

  var videoControlFullScreenIconSize = 30.0; //size of the full screen and shrink screen icons

  @override
  void initState(){
    super.initState();
    setupController();
  }

  void setupController() async{
    if(widget.playerController.value.isInitialized){
      playerController = ValueNotifier(widget.playerController);
      playerController.value.addListener(() {
        updateCurrentPosition();
        updateOverlayIcon();
      });
      playerController.value.setLooping(false);
    }
  }

  void updateCurrentPosition(){ //update position of slider while video is playing as well as the time remaining
    if(mounted){
      if(!isDraggingSlider.value && playerController.value.value.isInitialized){
        currentPosition.value = playerController.value.value.position.inMilliseconds / playerController.value.value.duration.inMilliseconds;
        displayCurrentDuration.value = _formatDuration(playerController.value.value.position);
        if(widget.durationEndDisplay == DurationEndDisplay.remainingDuration){
          timeRemaining.value = playerController.value.value.duration - playerController.value.value.position;
        }
      }
    }
  }

  void updateOverlayIcon(){ //triggered when the video ends
    if(playerController.value.value.position.inMilliseconds.toDouble() == playerController.value.value.duration.inMilliseconds.toDouble() && !playerController.value.value.isPlaying && mounted){
      overlayVisible.value = true;
      _overlayTimer?.cancel();
    }
  }

  String _formatDuration(Duration duration) { //convert duration to string
    String hours = (duration.inHours).toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (hours == '00') {
      return '$minutes:$seconds';
    } else {
      return '$hours:$minutes:$seconds';
    }
  }

  String formatSeconds(int seconds) { //convert total seconds to string
    int hours = seconds ~/ 3600;
    int minutes = (seconds ~/ 60) % 60;
    int remainingSeconds = seconds % 60;
    
    String formattedTime = '';
    
    if (hours > 0) {
      formattedTime += '${hours.toString().padLeft(2, '0')}:';
    }
    
    formattedTime += '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    
    return formattedTime;
  }


  void _togglePlayPause() {
    if(!hasPlayedOnce.value){ //if the video player is just initialized and hasn't played at all
      playerController.value.play();
      Timer(const Duration(milliseconds: 100), () {
        _startOverlayTimer();
      });
    }else if(playerController.value.value.position.inMilliseconds.toDouble() == playerController.value.value.duration.inMilliseconds.toDouble() && !playerController.value.value.isPlaying){ //if video has ended and no longer plays
      playerController.value.play();
      playerController.value.seekTo(const Duration(milliseconds: 0));
    }else if(playerController.value.value.isPlaying){ //if the video is playing
      playerController.value.pause();
    }else if(!playerController.value.value.isPlaying){ //if the video is paused
      playerController.value.play();
    }
    hasPlayedOnce.value = true;
    overlayVisible.value = true;
  }

  @override
  void dispose() {
    _overlayTimer?.cancel(); //dispose the timer
    super.dispose();
  }
  
  void onSliderStart(value){ //triggered if the user started dragging the slider
    overlayVisible.value = true;
    _overlayTimer?.cancel();
    currentPosition.value = value; //update the position of the slider
  }

  void onSliderChange(value){ //triggered if the user is dragging the user
    isDraggingSlider.value = true;
    currentPosition.value = value; //update the position of the slider
    var currentSecond = (value * playerController.value.value.duration.inMilliseconds / 1000).floor();
    displayCurrentDuration.value = formatSeconds(currentSecond); //only the display of the current duration will change, the video will still play as usual
  }

  void onSliderEnd(value){
    var duration = ((value * playerController.value.value.duration.inMilliseconds) ~/ 10) * 10;
    playerController.value.seekTo(Duration(milliseconds: duration));
    currentPosition.value = value;
    Timer(const Duration(milliseconds: 25), () {
      if(!playerController.value.value.isPlaying){
        playerController.value.play();
      }
      isDraggingSlider.value = false;
      overlayVisible.value = true;
      if(value < 1){
        Timer(const Duration(milliseconds: 100), () {
          _startOverlayTimer();
        });
      }else if(value >= 1){
        _overlayTimer?.cancel();
      }
    });
  }

  void skip(){
    int duration = min(playerController.value.value.duration.inMilliseconds, playerController.value.value.position.inMilliseconds + widget.skipDuration);
    playerController.value.seekTo(Duration(milliseconds: duration));
    Timer(const Duration(milliseconds: 25), () {
      if(!playerController.value.value.isPlaying){
        playerController.value.play();
      }
      if(duration / playerController.value.value.duration.inMilliseconds >= 1){
        _overlayTimer?.cancel();
      }
    });
  }

  void rewind(){
    int duration = max(0, playerController.value.value.position.inMilliseconds - widget.rewindDuration);
    playerController.value.seekTo(Duration(milliseconds: duration));
    Timer(const Duration(milliseconds: 25), () {
      if(!playerController.value.value.isPlaying){
        playerController.value.play();
      }
      if(duration / playerController.value.value.duration.inMilliseconds >= 1){
        _overlayTimer?.cancel();
      }
    });
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(Duration(milliseconds: widget.overlayDisplayDuration), () {
      if(mounted){
        overlayVisible.value = false;
      }
    });
  }

  void _toggleOverlay() {
    if(hasPlayedOnce.value){
      overlayVisible.value = !overlayVisible.value;
      if (overlayVisible.value) {
        _startOverlayTimer();
      } else {
        _overlayTimer?.cancel();
      }
    }
  }

  Widget displayActionIcon(VideoPlayerController playerController){
    IconData icon = Icons.play_circle;
    if(!playerController.value.isInitialized){
      icon = Icons.play_circle;
    }else{
      if(!hasPlayedOnce.value){
        icon = Icons.play_circle;
      }else if(playerController.value.position.inMilliseconds >= playerController.value.duration.inMilliseconds){
        icon = Icons.replay_rounded;
      }else if(playerController.value.isPlaying){
        icon = Icons.pause;
      }else if(hasPlayedOnce.value && !playerController.value.isPlaying){
        icon = Icons.play_arrow; 
      }
    }
    return Container(
      color: widget.pressablesBackgroundColor,
      child: Icon(icon, size: videoControlActionIconSize),
    );
  }  

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    Offset selectedPosition = _doubleTapDetails.localPosition;
    if(selectedPosition.dx >= 0 && selectedPosition.dx <= PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.35){
      rewind();
      isRewinding.value = true;
      isSkipping.value = false;
      Timer(const Duration(milliseconds: 1500), () {
        isRewinding.value = false;
      });
    }else if(selectedPosition.dx >= PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.65 && selectedPosition.dx <= PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio){
      skip();
      isSkipping.value = true;
      isRewinding.value = false;
      Timer(const Duration(milliseconds: 1500), () {
        isSkipping.value = false;
      });
    }
  }

  void displayVideoOptions(){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: menuMainContainerButtonMargin,
                child: SizedBox(
                  width: menuButtonWidth,
                  child: ElevatedButton(
                    style: menuButtonStyle,
                    onPressed: (){
                      Navigator.of(context).pop();
                      displayPlaybackSpeedOptions();
                    },
                    child: const Text('Set playback speed')
                  )
                )
              ),
              Container(
                margin: menuMainContainerButtonMargin,
                child: SizedBox(
                  width: menuButtonWidth,
                  child: ElevatedButton(
                    style: menuButtonStyle,
                    onPressed: (){
                      if (audioState == AudioState.mute) {
                        playerController.value.setVolume(1.0);
                        audioState = AudioState.unmute;
                      }else if(audioState == AudioState.unmute){
                        playerController.value.setVolume(0.0);
                        audioState = AudioState.mute;
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text(audioState == AudioState.mute ? 'Unmute' : 'Mute')
                  )
                )
              ),
            ],
          )
        );
      }
    );
  }

  void showFullScreenVideoPlayer(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context2) {
        return WillPopScope(
          onWillPop: () async{
            if(isFullScreenValue.value){
              Navigator.of(context2).pop();
              isFullScreenValue.value = false;
              return false;
            }
            return false;
          },
          child: Scaffold(
            body: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: videoPlayerComponent(playerController.value, context2),
              
            ),
          )
        );
      },
    );
  }

  void displayPlaybackSpeedOptions(){
    List playbackSpeeds = [
      0.25,
      0.5,
      0.75,
      1.0,
      1.5,
      2.0
    ];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            children: [
              for(int i = 0; i < playbackSpeeds.length; i++)
              Container(
                margin: menuMainContainerButtonMargin,
                child: SizedBox(
                  width: menuButtonWidth,
                  child: currentPlaybackSpeed != playbackSpeeds[i] ?
                    ElevatedButton(
                      style: menuButtonStyle,
                      onPressed: (){
                        playerController.value.setPlaybackSpeed(playbackSpeeds[i]);
                        currentPlaybackSpeed = playbackSpeeds[i];
                        Navigator.of(context).pop();
                      },
                      child: Text('${playbackSpeeds[i]}')
                    )
                  :
                    ElevatedButton.icon(
                      style: menuButtonStyle,
                      icon: const Icon(Icons.check),
                      onPressed: (){
                        playerController.value.setPlaybackSpeed(playbackSpeeds[i]);
                        Navigator.of(context).pop();
                      },
                      label: Text('${playbackSpeeds[i]}')
                    )
                )
                  ),
            ],
          )
        );
      }
    );
  }


  Widget videoPlayerComponent(VideoPlayerController videoPlayerController, context2){
    Widget component = GestureDetector(
      onTap: _toggleOverlay,
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        children: [
          Container(
            alignment: isFullScreenValue.value ? Alignment.center : widget.defaultAlignment,
            child: Stack(
              children: [
                VideoPlayer(videoPlayerController),
                Positioned(
                  right: 10,
                  top: 10,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: overlayVisible,
                    builder: (BuildContext context, bool overlayVisible, Widget? child) {
                      return overlayVisible && widget.displayMenu ? 
                        Container(
                          color: widget.pressablesBackgroundColor,
                          child: AnimatedOpacity(
                            opacity: overlayVisible ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: GestureDetector(
                              onTap: displayVideoOptions,
                              child: const Icon(Icons.menu, size: 32.5)
                            )
                          )
                        )
                      : Container();
                    }
                  )
                ),
                Positioned.fill(
                  left: 0,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: overlayVisible,
                      builder: (BuildContext context, bool overlayVisible, Widget? child) {
                        return ValueListenableBuilder(
                          valueListenable: videoPlayerController,
                          builder: (BuildContext context, playerController, Widget? child) {
                            return overlayVisible ? 
                               GestureDetector(
                                onTap: _togglePlayPause,
                                child: AnimatedOpacity(
                                  opacity: overlayVisible ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: displayActionIcon(videoPlayerController)
                                )
                              )
                            : Container();
                          }
                        );
                      }
                    )
                  )
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: overlayVisible,
                    builder: (BuildContext context, bool overlayVisible, Widget? child) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: hasPlayedOnce,
                        builder: (BuildContext context, bool hasPlayedOnce, Widget? child) {
                          return overlayVisible && hasPlayedOnce ?
                            GestureDetector(
                              onTap: (){},
                              child: Container(
                               
                                padding: EdgeInsets.symmetric(horizontal: 0.01 * PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio, vertical: PlatformDispatcher.instance.views.first.physicalSize.height/ PlatformDispatcher.instance.views.first.devicePixelRatio * 0.01),
                                color: widget.overlayBackgroundColor,
                                child: AnimatedOpacity(
                                  opacity: overlayVisible && hasPlayedOnce ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Column(
                                    children: [
                                    
                                      ValueListenableBuilder<bool>(
                                        valueListenable: isFullScreenValue,
                                        builder: (BuildContext context, bool isFullScreen, Widget? child) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(horizontal: PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.025),
                                            child:Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                
                                                ValueListenableBuilder<String>(
                                                  valueListenable: displayCurrentDuration,
                                                  builder: (BuildContext context, String displayCurrentDuration, Widget? child) {
                                                    return widget.durationEndDisplay == DurationEndDisplay.totalDuration ?
                                                      Text(
                                                        '$displayCurrentDuration / ${_formatDuration(videoPlayerController.value.duration)}',
                                                        style: TextStyle(fontSize: standardTextFontSize)
                                                      )
                                                    : 
                                                      ValueListenableBuilder<Duration>(
                                                        valueListenable: timeRemaining,
                                                        builder: (BuildContext context, Duration timeRemaining, Widget? child) {
                                                          return Text(
                                                            '$displayCurrentDuration / -${_formatDuration(timeRemaining)}',
                                                            style: TextStyle(fontSize: standardTextFontSize)
                                                          );
                                                        }
                                                      );
                                                  }
                                                ),
                                                GestureDetector(
                                                  onTap: () async{
                                                    if(!isFullScreen){
                                                      showFullScreenVideoPlayer(context);
                                                      isFullScreenValue.value = true;
                                                    }else{
                                                      Navigator.of(context2).pop();
                                                      isFullScreenValue.value = false;
                                                    }
                                                  },
                                                  child: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, size: videoControlFullScreenIconSize)
                                                )
                                              ]
                                            )
                                          );
                                        }
                                      ),
                                        
                                      SizedBox(
                                        height: 15,
                                        child: SliderTheme(
                                          data: SliderThemeData(
                                            trackHeight: 3.0,
                                            thumbColor: widget.thumbColor,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 0.0),
                                            activeTrackColor: widget.activeTrackColor,
                                            inactiveTrackColor: widget.inactiveTrackColor
                                          ),
                                          child: ValueListenableBuilder<double>(
                                            valueListenable: currentPosition,
                                            builder: (BuildContext context, double currentPosition, Widget? child) {
                                              return Slider(
                                                min: 0.0,
                                                max: max(1.0, currentPosition),
                                                value: currentPosition,
                                                onChangeStart: ((value){
                                                  onSliderStart(value);
                                                }),
                                                onChanged: (newValue) {
                                                  onSliderChange(newValue);
                                                },
                                                onChangeEnd: (newValue){
                                                  onSliderEnd(newValue);
                                                },
                                              );
                                            }
                                          )
                                        ),
                                          
                                      ),
                                    ]
                                  
                                  )
                                )
                              )
                            )
                            : Container();
                        }
                      );
                    }
                  )
                  
                ),
              ]
            )
          ),
          
          Positioned(
            left: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: isRewinding,
              builder: (BuildContext context, bool isRewinding, Widget? child) {
                return SizedBox(
                  width: PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.5,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isRewinding ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        color: widget.pressablesBackgroundColor,
                        padding: EdgeInsets.all(PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.02),
                        child: const Icon(FontAwesomeIcons.backward, size: 30)
                      )
                    )
                  )
                );
              }
            )
          ),
          Positioned(
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: isSkipping,
              builder: (BuildContext context, bool isSkipping, Widget? child) {
                return SizedBox(
                  width: PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.5,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isSkipping ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        color: widget.pressablesBackgroundColor,
                        padding: EdgeInsets.all(PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio * 0.02),
                        child: const Icon(FontAwesomeIcons.forward, size: 30)
                      )
                    )
                  )
                );
              }
            )
          )
        ],
      )
    );

    return component;
  }
  
  @override
  Widget build(BuildContext context) {
    return playerController.value.value.isInitialized ? 
      videoPlayerComponent(playerController.value, context)
    : const Center(child: CircularProgressIndicator());
  }
}

double getScreenHeight(){
  return PlatformDispatcher.instance.views.first.physicalSize.height / PlatformDispatcher.instance.views.first.devicePixelRatio;
}

double getScreenWidth(){
  return PlatformDispatcher.instance.views.first.physicalSize.width / PlatformDispatcher.instance.views.first.devicePixelRatio;
}