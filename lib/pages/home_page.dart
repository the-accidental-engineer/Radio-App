import 'package:ai_radio/model/radio.dart';
import 'package:ai_radio/utils/ai_util.dart';
import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyRadio>? radios;
  bool onWait = false;
  MyRadio? _selectedRadio;
  Color? _selectedColor;
  bool _isPlaying = false;
  MyRadio? _playingChannelName;

  final sugg = [
    "Play",
    "Stop",
    "Play rock music",
    "Play 107 FM",
    "Play next",
    "Play 104 FM",
    "Pause",
    "Play previous",
    "Play pop music"
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    setUpAlan();

    fetchRadios().whenComplete(() {
      setState(() {
        onWait = true;
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.PLAYING) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      setState(() {});
    });
  }

  fetchRadios() async {
    final radioJson = await rootBundle.loadString('assets/radio.json');
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios![0];
    _selectedColor = Color(int.parse(_selectedRadio!.color));

    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(url);
    _playingChannelName = radios!.firstWhere((element) => element.url == url);
    _selectedRadio = radios!.firstWhere((element) => element.url == url);
    _selectedColor = Color(int.parse(_selectedRadio!.color));

    setState(() {});
  }

  setUpAlan() {
    AlanVoice.addButton(
        "55a4c6a2ab1567aa570048de256bfb452e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.onCommand.add((command) => _handleCommand(command.data));
  }

  _handleCommand(Map<String, dynamic> response) {
    switch (response["command"]) {
      case "play":
        _playMusic(_selectedRadio!.url);
        break;

      case "play_channel":
        final id = response["id"];
        _audioPlayer.pause();
        MyRadio newRadio = radios!.firstWhere((element) => element.id == id);
        radios!.remove(newRadio);
        radios!.insert(0, newRadio);
        _playMusic(newRadio.url);
        break;

      case "stop":
        _audioPlayer.stop();
        break;

      case "next":
        final index = _selectedRadio!.id;
        MyRadio newRadio;
        if (index + 1 > radios!.length) {
          newRadio = radios!.firstWhere((element) => element.id == 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        } else {
          newRadio = radios!.firstWhere((element) => element.id == index + 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;

      case "prev":
        final index = _selectedRadio!.id;
        MyRadio newRadio;
        if (index - 1 <= 0) {
          newRadio =
              radios!.firstWhere((element) => element.id == radios!.length);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        } else {
          newRadio = radios!.firstWhere((element) => element.id == index - 1);
          radios!.remove(newRadio);
          radios!.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;

      default:
        print("Command was ${response["command"]}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Container(
          width: context.percentWidth * 74,
          child: Drawer(
            child: Container(
              color: _selectedColor ?? AIColors.primaryColor2,
              child: radios != null
                  ? [
                      60.heightBox,
                      "All Channels".text.xl.white.semiBold.make().px16(),
                      20.heightBox,
                      ListView(
                        padding: Vx.m0,
                        shrinkWrap: true,
                        children: radios!
                            .map((e) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(e.icon),
                                  ),
                                  title: "${e.name} FM".text.white.make(),
                                  subtitle: e.tagline.text.white.make(),
                                ))
                            .toList(),
                      ).expand()
                    ].vStack(crossAlignment: CrossAxisAlignment.start)
                  : const Offstage(),
            ),
          ),
        ),
        body: Stack(
          children: [
            VxAnimatedBox()
                .size(context.screenWidth, context.screenHeight)
                .animDuration(Duration.zero)
                .withGradient(
                  LinearGradient(
                    colors: [
                      AIColors.primaryColor2,
                      _selectedColor ?? AIColors.primaryColor1
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
                .make(),
            [
              AppBar(
                title: 'AI Radio'.text.xl4.bold.white.make().shimmer(
                    primaryColor: Vx.purple300, secondaryColor: Colors.white),
                elevation: 0.0,
                centerTitle: true,
                backgroundColor: Colors.transparent,
              ).pOnly(
                top: context.percentHeight * 2.5,
              ),
              "Start with - Hey Alan & Ask Alan To👇"
                  .text
                  .italic
                  .semiBold
                  .white
                  .make(),
              SizedBox(
                height: context.percentHeight * 2.5,
              ),
              VxSwiper.builder(
                itemCount: sugg.length,
                height: context.percentHeight * 7,
                autoPlay: true,
                autoPlayAnimationDuration: 2.seconds,
                autoPlayCurve: Curves.linear,
                enableInfiniteScroll: true,
                itemBuilder: (context, index) {
                  final s = sugg[index];
                  return Chip(
                    label: s.text.make(),
                    backgroundColor: Vx.randomColor,
                  );
                },
              )
            ].vStack(alignment: MainAxisAlignment.start),
            onWait
                ? VxSwiper.builder(
                    itemCount: radios!.length,
                    aspectRatio: 1.0,
                    enlargeCenterPage: true,
                    onPageChanged: (index) {
                      _selectedRadio = radios![index];
                      final colorHex = radios![index].color;
                      _selectedColor = Color(int.parse(colorHex));
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final rad = radios![index];
                      return VxBox(
                        child: ZStack(
                          [
                            Positioned(
                              top: 0.0,
                              right: 0.0,
                              child: VxBox(
                                      child: rad.category.text.uppercase.white
                                          .make()
                                          .px16())
                                  .height(40)
                                  .black
                                  .alignCenter
                                  .withRounded(value: 10.0)
                                  .make(),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: VStack(
                                [
                                  rad.name.text.xl3.white.bold.make(),
                                  5.heightBox,
                                  rad.tagline.text.sm.white.semiBold.make(),
                                ],
                                crossAlignment: CrossAxisAlignment.center,
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: [
                                Icon(
                                  CupertinoIcons.play_circle,
                                  color: Colors.white,
                                ),
                                10.heightBox,
                                'Double tap to play'.text.gray300.make(),
                              ].vStack(),
                            ),
                          ],
                        ),
                      )
                          .clip(Clip.antiAlias)
                          .bgImage(
                            DecorationImage(
                              image: NetworkImage(rad.image),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.3),
                                  BlendMode.darken),
                            ),
                          )
                          .border(color: Colors.black, width: 5.0)
                          .withRounded(value: 60.0)
                          .make()
                          .onInkDoubleTap(() {
                        _playMusic(rad.url);
                      }).p12();
                    },
                  ).pOnly(
                    top: context.percentHeight * 24,
                    bottom: context.percentHeight * 16)
                : Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    ),
                  ),
            Align(
                    alignment: Alignment.bottomCenter,
                    child: [
                      if (_isPlaying)
                        'Playing Now - ${_playingChannelName!.name} FM'
                            .text
                            .white
                            .makeCentered(),
                      SizedBox(
                        height: context.percentHeight * 0.3,
                      ),
                      Icon(
                        _isPlaying
                            ? CupertinoIcons.stop_circle
                            : CupertinoIcons.play_circle,
                        color: Colors.white,
                        size: 50.0,
                      ).onInkTap(() {
                        if (_isPlaying) {
                          _audioPlayer.stop();
                        } else {
                          _playMusic(_selectedRadio!.url);
                        }
                      }),
                    ].vStack())
                .pOnly(bottom: context.percentHeight * 4)
          ],
          fit: StackFit.expand,
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );
  }
}
