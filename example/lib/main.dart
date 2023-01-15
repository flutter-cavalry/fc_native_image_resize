import 'dart:io';

import 'package:fc_native_image_resize/fc_native_image_resize.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

class _MyAppState extends State<MyApp> {
  String? _destImg;
  String _imgSizeInfo = '';
  final _nativeImgUtilPlugin = FcNativeImageResize();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: _destImg == null
              ? const Text('Click on the + button to select a photo')
              : Column(
                  children: [
                    SelectableText(_destImg!),
                    Text(_imgSizeInfo),
                    Image(image: FileImage(File(_destImg!)))
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _selectImage,
          tooltip: 'Select an image',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      var result = await FilePicker.platform.pickFiles();
      if (result == null) {
        return;
      }
      var src = result.files.single.path!;
      var dest = tmpPath() + p.extension(src);
      await _nativeImgUtilPlugin.resizeFile(
          srcFile: src,
          destFile: dest,
          width: 300,
          height: 300,
          keepAspectRatio: true,
          type: 'jpeg');
      var imageFile = File(dest); // Or any other way to get a File instance.
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      setState(() {
        _destImg = dest;
        _imgSizeInfo =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
      });
    } catch (err) {
      debugPrint('Error: $err');
    }
  }
}
