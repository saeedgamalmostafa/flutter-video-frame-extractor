import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _videoPath;
  String? _framePath;
  VideoPlayerController? _videoController;
  Future<String?> pickVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    } else {
      return null;
    }
  }

  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  Future<String?> extractFrame(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final outputDir = '${tempDir.path}/frames';
    await Directory(outputDir).create(recursive: true);

    final framePath = '$outputDir/frame.png';
    final command = '-i $videoPath -vf "select=eq(n\\,0)" -q:v 3 $framePath';
    await _flutterFFmpeg.execute(command);

    if (await File(framePath).exists()) {
      return framePath;
    } else {
      return null;
    }
  }

  Future<void> _pickVideo() async {
    final videoPath = await pickVideoFile();
    if (videoPath != null) {
      setState(() {
        _videoPath = videoPath;
        _framePath = null;
        _videoController = VideoPlayerController.file(File(videoPath))
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      });
    }
  }

  Future<void> _extractFrame() async {
    if (_videoPath != null) {
      final framePath = await extractFrame(_videoPath!);
      setState(() {
        _framePath = framePath;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Frame Extraction Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Select Video'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _extractFrame,
              child: Text('Extract Frame'),
            ),
            SizedBox(height: 16),
            if (_videoController != null && _videoController!.value.isInitialized)
              Container(
                width: 300,
                height: 200,
                child: VideoPlayer(_videoController!),
              ),
            if (_framePath != null)
              Container(
                width: 300,
                height: 200,
                child: Image.file(File(_framePath!)),
              ),
          ],
        ),
      ),
    );
  }
}
