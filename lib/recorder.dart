import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

typedef _Fn = void Function();

const theSource = AudioSource.microphone;

class SimpleRecorder extends StatefulWidget {
  const SimpleRecorder({Key? key}) : super(key: key);

  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  Codec _codec = Codec.aacMP4;
  String _mPath = 'recording.mp4';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;

  @override
  void initState() {
    _mPlayer!.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _mPlayer!.closeAudioSession();
    _mPlayer = null;

    _mRecorder!.closeAudioSession();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openAudioSession();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'recording.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    _mRecorderIsInited = true;
  }

  void record() {
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        _mplaybackReady = true;
      });
    });
  }

  void play() {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
            fromURI: _mPath,
            //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
            whenFinished: () {
              setState(() {});
            })
        .then((value) {
      setState(() {});
    });
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

// ----------------------------- UI --------------------------------------------

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 400.0,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 2, 199, 226),
                  Color.fromARGB(255, 6, 75, 210)
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom:
                    Radius.elliptical(MediaQuery.of(context).size.width, 100.0),
              ),
            ),
            child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Record your notes here',
                      style: TextStyle(fontSize: 80, color: Colors.white),
                    ),
                    Text(
                      _mPlayer!.isPlaying
                          ? 'Playback in progress'
                          : 'Player is stopped',
                      style: const TextStyle(fontSize: 30),
                    )
                  ]),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildElevatedButton(
                icon: Icons.mic,
                iconColor: Colors.red,
                disableCondition: _mRecorder!.isRecording,
                f: record,
              ),
              const SizedBox(
                width: 30,
              ),
              buildElevatedButton(
                icon: Icons.stop,
                iconColor: Colors.black,
                disableCondition: !_mRecorder!.isRecording,
                f: stopRecorder,
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildElevatedButton(
                icon: Icons.play_arrow,
                iconColor: Colors.black,
                disableCondition: !_mPlayer!.isStopped || !_mplaybackReady,
                f: play,
              ),
              const SizedBox(
                width: 30,
              ),
              buildElevatedButton(
                icon: Icons.stop,
                iconColor: Colors.black,
                disableCondition: _mPlayer!.isStopped,
                f: stopPlayer,
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              elevation: 10.0,
            ),
            onPressed: () {
              setState(() {});
              if (!_mRecorder!.isRecording) play();
              if (_mRecorder!.isRecording) stopPlayer();
            },
            icon: _mRecorder!.isRecording
                ? const Icon(
                    Icons.stop,
                  )
                : const Icon(Icons.play_arrow),
            label: _mRecorder!.isRecording
                ? const Text(
                    "Stop Playing",
                    style: TextStyle(
                      fontSize: 25,
                    ),
                  )
                : const Text(
                    "Start Playing",
                    style: TextStyle(
                      fontSize: 25,
                    ),
                  ),
          ),
          const Text('OR',
              style: TextStyle(
                fontSize: 20,
              )),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload audio file',
                style: TextStyle(fontSize: 25, fontFamily: 'RaleWay')),
            onPressed: () async {
              var dio = Dio();
              var picked = await FilePicker.platform.pickFiles();

              if (picked != null) {
                print(picked.files.first.name);
                PlatformFile file = picked.files.first;
                print('${file.size}');
                FormData formData = FormData.fromMap({
                  "file": await MultipartFile.fromBytes(file.bytes!,
                      filename: file.name)
                });
                var response = await dio.post(
                    'https://wenote-api.neeltron.repl.co/input',
                    data: formData);
                print('${response.statusCode}');
                if (response.statusCode == 200 || response.statusCode == 201) {
                  print("Uploaded!");
                }
              }
            },
          ),
        ],
      ),
    );
  }

  ElevatedButton buildElevatedButton(
      {required IconData icon,
      required Color iconColor,
      required bool disableCondition,
      required void Function() f}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(5.0),
        side: const BorderSide(
          color: Colors.orange,
          width: 3.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        primary: Colors.white,
        elevation: 10.0,
      ),
      onPressed: disableCondition ? null : f,
      icon: Icon(
        icon,
        color: iconColor,
        size: 35.0,
      ),
      label: const Text(''),
    );
  }
}
