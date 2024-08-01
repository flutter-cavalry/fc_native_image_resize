import 'dart:io';

import 'package:fc_native_image_resize/fc_native_image_resize.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import 'package:tmp_path/tmp_path.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class Task {
  final String name;
  final String srcFile;
  final int width;
  final int height;
  final bool keepAspectRatio;

  String? destFile;
  String? destImgSize;
  String? error;

  Task(
      {required this.name,
      required this.srcFile,
      required this.width,
      required this.height,
      required this.keepAspectRatio});

  Future<void> run() async {
    try {
      var nativeImgUtilPlugin = FcNativeImageResize();
      final destFile = tmpPath() + p.extension(srcFile);
      await nativeImgUtilPlugin.resizeFile(
          srcFile: srcFile,
          destFile: destFile,
          width: width,
          height: height,
          keepAspectRatio: keepAspectRatio,
          format: 'jpeg');
      this.destFile = destFile;
      var imageFile = File(destFile);
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      destImgSize =
          'Decoded size: ${decodedImage.width}x${decodedImage.height}';
    } catch (err) {
      error = err.toString();
    }
  }
}

class _MyAppState extends State<MyApp> {
  String? _srcImage;
  String? _err;
  final ImagePicker _mobilePicker = ImagePicker();
  final _tasks = <Task>[];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Click on the + button to select a photo'),
                const SizedBox(height: 8.0),
                if (_err != null) ...[const SizedBox(height: 8.0), Text(_err!)],
                if (_srcImage != null) ...[
                  const SizedBox(height: 8.0),
                  Text('Source image: $_srcImage'),
                  const SizedBox(height: 8.0),
                  Image(
                    image: FileImage(File(_srcImage!)),
                    width: 200,
                    height: 200,
                  ),
                ],
                ..._tasks.map((task) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8.0),
                      Text('>>> ${task.name}',
                          style: const TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold)),
                      if (task.error != null) ...[
                        const SizedBox(height: 8.0),
                        Text(task.error!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      if (task.destFile != null) ...[
                        const SizedBox(height: 8.0),
                        Text('Dest image: ${task.destFile}'),
                        const SizedBox(height: 8.0),
                        Text(task.destImgSize ?? ''),
                        const SizedBox(height: 8.0),
                        Image(image: FileImage(File(task.destFile!))),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickImage,
          tooltip: 'Pick an image',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      XFile? src;
      if (Platform.isAndroid || Platform.isIOS) {
        src = await _mobilePicker.pickImage(source: ImageSource.gallery);
      } else {
        src = await openFile();
      }
      if (src == null) {
        return;
      }
      final srcPath = src.path;
      setState(() {
        _srcImage = srcPath;
        _err = null;
        _tasks.clear();
      });
      _tasks.add(Task(
          name: 'Resize to 300x300 (keepAspectRatio: true)',
          srcFile: srcPath,
          width: 300,
          height: 300,
          keepAspectRatio: true));
      _tasks.add(Task(
          name: 'Resize to 300x300 (keepAspectRatio: false)',
          srcFile: srcPath,
          width: 300,
          height: 300,
          keepAspectRatio: false));
      _tasks.add(Task(
          name: 'Resize to 300x',
          srcFile: srcPath,
          width: 300,
          height: -1,
          keepAspectRatio: true));
      _tasks.add(Task(
          name: 'Resize to x300',
          srcFile: srcPath,
          width: -1,
          height: 300,
          keepAspectRatio: true));

      // Upscaling task.
      final localImgBytes = await rootBundle.load('res/google.png');
      final smallImgPath = '${tmpPath()}_small.png';
      await File(smallImgPath).writeAsBytes(localImgBytes.buffer.asUint8List());
      _tasks.add(Task(
          name: 'No upscaling to 1000x1000 (keepAspectRatio: true)',
          srcFile: smallImgPath,
          width: 1000,
          height: 1000,
          keepAspectRatio: true));

      _tasks.add(Task(
          name: 'Upscaling to 1000x1000 (keepAspectRatio: false)',
          srcFile: smallImgPath,
          width: 1000,
          height: 1000,
          keepAspectRatio: false));

      await Future.forEach(_tasks, (Task task) async {
        await task.run();
        setState(() {});
      });
    } catch (err) {
      setState(() {
        _err = err.toString();
      });
    }
  }
}
