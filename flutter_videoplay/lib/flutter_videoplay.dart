library flutter_page_video;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:orientation/orientation.dart';
import 'dart:async';
import 'dart:io';

//此地址仅用于智仔视频播放使用
const String localhost_Host = 'http://www.zhizai.xin/';
const String bos_Host = 'http://resource.zhizai.xin/';

class SimpleViewPlayer extends StatefulWidget {
  String source;
  String photoImg;
  bool isFullScreen;

  SimpleViewPlayer(this.source, {this.photoImg : '', this.isFullScreen : false});

  @override
  SimpleViewPlayerState createState() => SimpleViewPlayerState();
}

class SimpleViewPlayerState extends State<SimpleViewPlayer> {
  VideoPlayerController controller;
  VoidCallback listener;
  bool hideBottom = true;

  @override
  void initState() {
    super.initState();

    reloadVideo();

    Screen.keepOn(true);
    if (widget.isFullScreen) {
      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void reloadVideo() {
    listener = () {
//      print(controller.value.hasError.toString() +
//          '---------------- ${mounted.toString()}' + widget.source);
      if (!mounted) {
        return;
      }
      //视频播放失败切换播放源
      if (controller.value.hasError && !controller.value.isPlaying) {
        controller.dispose();
        controller.removeListener(listener);
        widget.source = widget.source.replaceAll(bos_Host, localhost_Host);
//        print(controller.value.hasError.toString() +
//            '---------------- ${mounted.toString()}' + widget.source);
        controller = VideoPlayerController.network(widget.source);
        controller.initialize().then((_) {
          setState(() {});
        });
        controller.setLooping(true);
        controller.addListener(listener);
      } else
        setState(() {});
    };

    controller = VideoPlayerController.network(widget.source);
    controller.initialize().then((_) {
      setState(() {});
    });
    controller.setLooping(true);
    controller.addListener(listener);
//    controller.play();
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();
    Screen.keepOn(false);
    if (widget.isFullScreen) {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayView(
        controller,
        widget.photoImg,
        allowFullScreen: !widget.isFullScreen,
      ),
    );
  }


}

class PlayView extends StatefulWidget {
  VideoPlayerController controller;
  bool allowFullScreen;
  bool fullScreen_video;
  String backImg;//视频封面图

  PlayView(this.controller, this.backImg,
      {this.allowFullScreen: true, this.fullScreen_video: false});

  @override
  _PlayViewState createState() => _PlayViewState();
}

class _PlayViewState extends State<PlayView> {
  VideoPlayerController get controller => widget.controller;
  bool hideBottom = false;
  bool videoisPlay = false;

  Timer _timer;

  @override
  void initState() {
    super.initState();

//    showTool();
    if (controller.value.isPlaying) {
      setState(() {
        hideBottom = true;
      });
    }

    if (widget.fullScreen_video) {
      videoisPlay = true;
      _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        debugPrint("定时器正常运作");
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void showTool() {
    if (hideBottom) {
      setState(() {
        hideBottom = false;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) {
          return;
        }
        if (controller.value.isPlaying) {
          setState(() {
            hideBottom = true;
          });
        }
      });
    }
  }

  void onClickPlay() {
    if (!controller.value.initialized) {
      return;
    }
//    setState(() {
//      hideBottom = false;
//    });
    if (controller.value.isPlaying) {
      controller.pause();
      setState(() {
        hideBottom = false;
      });
    } else {
//      Future.delayed(const Duration(seconds: 3), () {
//      if (!mounted) {
//        return;
//      }
//      if (!controller.value.initialized) {
//        return;
//      }
//        if (controller.value.isPlaying && !hideBottom) {
//          setState(() {
//            hideBottom = true;
//          });
//        }
//      });

      controller.play();
      videoisPlay = true;
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) {
          return;
        }
        setState(() {
          hideBottom = true;
        });
      });
    }
    setState(() {});
  }

  void onClickFullScreen() {
    if (MediaQuery
        .of(context)
        .orientation == Orientation.portrait) {
      // current portrait , enter fullscreen
      SystemChrome.setEnabledSystemUIOverlays([]);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);

      Navigator.of(context)
          .push(PageRouteBuilder(
        settings: RouteSettings(isInitialRoute: false),
        pageBuilder: (BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget child) {
              return Scaffold(
                resizeToAvoidBottomPadding: false,
                body: PlayView(controller, widget.backImg, fullScreen_video: true,),
              );
            },
          );
        },
      ))
          .then((value) {
        // exit fullscreen
        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      });
    }
  }

  void onClickExitFullScreen() {
    if (MediaQuery
        .of(context)
        .orientation == Orientation.landscape) {
      // current landscape , exit fullscreen
      Navigator.of(context).pop();

      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
//      fullScreen_video = false;
      if (_timer != null) {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme
        .of(context)
        .primaryColor;
    if (controller.value.initialized) {
      final Size size = controller.value.size;

//      debugPrint('视频加载信息------------' + controller.value.duration.toString());
      return InkWell(
        child: Container(
            color: Colors.black,
            child: Stack(
              children: <Widget>[
                Center(
                    child: AspectRatio(
                      aspectRatio: size.width / size.height,
                      child: VideoPlayer(controller),
                    )),
                !videoisPlay ? Align(
                  //显示底部默认图 'http://b-ssl.duitang.com/uploads/item/201505/06/20150506202306_WYEi5.jpeg'
                  alignment: Alignment.center,
                  child: Image.network(widget.backImg, fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width),
                ) : Container(),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: hideBottom
                        ? Container()
                        : Opacity(
                      opacity: 0.8,
                      child: Container(
                          height: 40.0,
                          color: Colors.grey,
                          child: Row(
//                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              GestureDetector(
                                child: Container(
                                  child: controller.value.isPlaying
                                      ? Icon(
                                    Icons.pause,
                                    color: primaryColor,
                                  )
                                      : Icon(
                                    Icons.play_arrow,
                                    color: primaryColor,
                                  ),
                                ),
                                onTap: onClickPlay,
                              ),
                              Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: Center(
                                    child: Text(
                                      "${controller.value.position.toString()
                                          .split(".")[0]}",
                                      style:
                                      TextStyle(color: Colors.white),
                                    ),
                                  )),
                              Expanded(
                                  child:
                                  Platform.isIOS ? controller.value.duration
                                      .toString() ==
                                      '0:00:00.000000' ?
                                  Center(
                                    child: Text(
                                      "数据加载异常,请重试",
                                      style:
                                      TextStyle(color: Colors.white),
                                    ),
                                  ) : VideoProgressIndicator(
                                    controller,
                                    allowScrubbing: true,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 1.0, vertical: 1.0),
                                    colors: VideoProgressColors(
                                        playedColor: primaryColor),
                                  ) : VideoProgressIndicator(
                                    controller,
                                    allowScrubbing: true,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 1.0, vertical: 1.0),
                                    colors: VideoProgressColors(
                                        playedColor: primaryColor),
                                  )),
                              Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 5.0),
                                  child: Center(
                                    child: Text(
                                      "${controller.value.duration.toString()
                                          .split(".")[0]}",
                                      style:
                                      TextStyle(color: Colors.white),
                                    ),
                                  )),
                              Container(
                                child: widget.allowFullScreen
                                    ? Container(
                                  child: MediaQuery
                                      .of(context)
                                      .orientation ==
                                      Orientation.portrait
                                      ? GestureDetector(
                                    child: Icon(
                                      Icons.fullscreen,
                                      color: primaryColor,
                                      size: 30,
                                    ),
                                    onTap: onClickFullScreen,
                                  )
                                      : GestureDetector(
                                    child: Icon(
                                      Icons.fullscreen_exit,
                                      color: primaryColor,
                                      size: 30,
                                    ),
                                    onTap:
                                    onClickExitFullScreen,
                                  ),
                                )
                                    : Container(),
                              )
                            ],
                          )),
                    )),
                Align(
                    alignment: Alignment.center,
                    child: controller.value.isPlaying || hideBottom
                        ? Container()
                        : IconButton(icon: Icon(
                      Icons.play_circle_filled,
                      color: primaryColor,
                      size: 48.0,
                    ), onPressed: onClickPlay)
                )
              ],
            )),
        onTap: showTool,
      );
    } else if (controller.value.hasError && !controller.value.isPlaying) {
      return Container(
        color: Colors.black,
        child: Center(
          child: RaisedButton(
            onPressed: () {
              controller.initialize();
              controller.setLooping(true);
              controller.play();
            },
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            child: Text("play error, try again!"),
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
