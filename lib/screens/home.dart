import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import './settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

Duration durationFromValue(Duration original, double value) {
  var seconds = original.inSeconds * value;
  return original - Duration(seconds: seconds.toInt());
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controller;
  final player = AudioPlayer();

  late Timer timer;

  Settings settings = Settings();

  bool running = false;
  bool audioPlaying = false;

  void _resetTimer() {
    setState(() {
      timer.cancel();
      _controller.stop();
      _controller.value = 0;
    });
  }

  void _switchTimer() {
    setState(() {
      _controller = AnimationController(
          vsync: this,
          duration: nextDuration(_controller.duration ?? Duration.zero))
        ..addListener(() {
          setState(() {});
        });
    });
  }

  void _toggleTimer() {
    setState(() {
      if (running) {
        _controller.stop();
        running = false;
        timer.cancel();
      } else {
        player.stop();
        timer = Timer(
            durationFromValue(_controller.duration!, _controller.value),
            _handleCompletion);
        audioPlaying = false;
        _controller.forward(from: _controller.value);
        running = true;
      }
    });
  }

  void _handleCompletion() {
    player.resume();
    setState(() {
      audioPlaying = true;
      var next = nextDuration(_controller.duration ?? Duration.zero);
      running = false;
      _controller = AnimationController(
        vsync: this,
        duration: next,
      )..addListener(() {
          setState(() {});
        });
    });
  }

  Duration nextDuration(Duration current) {
    if (current == settings.focusDuration) {
      return settings.breakDuration;
    }
    return settings.focusDuration;
  }

  void Function() openSettings(BuildContext context) => () {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (context) => SettingsPage(settings: settings)))
            .then((change) {
          if (!context.mounted) return;
          if (change == null) return;
          setState(() {
            settings = change;
            _handleCompletion();
          });
        });
      };

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: settings.focusDuration,
    )..addListener(() {
        setState(() {});
      });

    super.initState();

    player.setReleaseMode(ReleaseMode.stop);
    player.setSource(settings.alarmSource);
    player.onPlayerComplete.listen((_) {
      setState(() {
        audioPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var timeLeft = durationFromValue(_controller.duration!, _controller.value);
    var minutes = timeLeft.inMinutes;
    var seconds = timeLeft.inSeconds % 60;
    var minutesString = minutes.toString().padLeft(2, "0");
    var secondsString = seconds.toString().padLeft(2, "0");
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                width: 400,
                height: 400,
                padding: const EdgeInsets.all(16.0),
                child: Stack(children: [
                  Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$minutesString:$secondsString',
                                style: const TextStyle(
                                    fontSize: 72.0, fontFamily: 'Victor Mono'))
                          ])),
                  Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CircularProgressIndicator(
                        value: _controller.value,
                        semanticsLabel: "Time left",
                      )),
                ])),
            Container(
                margin: const EdgeInsets.all(4.0),
                child: ElevatedButton(
                  onPressed: _toggleTimer,
                  child: Text(running ? "Pause" : "Start"),
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                    visible: !running && _controller.value > 0,
                    // maintainSize: true,
                    // maintainAnimation: true,
                    // maintainState: true,
                    child: Container(
                        margin: const EdgeInsets.all(4.0),
                        child: OutlinedButton(
                            style: const ButtonStyle(
                              padding:
                                  WidgetStatePropertyAll(EdgeInsets.all(4.0)),
                            ),
                            onPressed: _resetTimer,
                            child: const Text("Reset")))),
                Visibility(
                    visible: !running && _controller.value == 0,
                    // maintainSize: true,
                    // maintainAnimation: true,
                    // maintainState: true,
                    child: Container(
                        margin: const EdgeInsets.all(4.0),
                        child: IconButton.outlined(
                            style: const ButtonStyle(
                              padding:
                                  WidgetStatePropertyAll(EdgeInsets.all(4.0)),
                            ),
                            onPressed: _switchTimer,
                            icon: const Icon(Icons.sync)))),
              ],
            ),
            Visibility(
                visible: audioPlaying,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Container(
                    margin: const EdgeInsets.all(4.0),
                    child: IconButton(
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(4.0)),
                      ),
                      onPressed: () {
                        setState(() {
                          player.stop();
                          audioPlaying = false;
                        });
                      },
                      icon: const Icon(Icons.volume_off),
                    ))),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: openSettings(context),
        child: const Icon(Icons.settings),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
