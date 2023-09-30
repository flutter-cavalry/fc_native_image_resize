import 'dart:io';

import 'package:fc_native_image_resize/fc_native_image_resize.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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

class _MyAppState extends State<MyApp> {
  String? _destImg;
  String? _err;
  String _imgSizeInfo = '';
  final ImagePicker _mobilePicker = ImagePicker();
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
              ? Text(_err != null
                  ? _err!
                  : 'Click on the + button to select a photo')
              : Column(
                  children: [
                    SelectableText(_destImg!),
                    Text(_imgSizeInfo),
                    Image(image: FileImage(File(_destImg!)))
                  ],
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
      var dest = tmpPath() + p.extension(src.name);
      setState(() {
        _err = null;
      });
      await _nativeImgUtilPlugin.resizeFile(
          srcFile: src.path,
          destFile: dest,
          width: 300,
          height: 300,
          keepAspectRatio: true,
          srcFileUri: Platform.isAndroid,
          format: 'jpeg');
      var imageFile = File(dest);
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      setState(() {
        _destImg = dest;
        _imgSizeInfo =
            'Decoded size: ${decodedImage.width}x${decodedImage.height}';
      });
    } catch (err) {
      setState(() {
        _destImg = null;
        _err = err.toString();
      });
    }
  }
}
