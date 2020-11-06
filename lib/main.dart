import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(
  MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: FacePage(),
  ),
);

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();    //creating state
}

class _FacePageState extends State<FacePage> {
  File _imageFile;    //File to be processed
  List<Face> _faces;         // Detected Faces after Processing
  bool isLoading = false;
  ui.Image _image;



      //getting image from gallery and detecting them From Firebase ML
  _getImageAndDetectFaces() async {
    final imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);   //file import
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector();    //instance that gets faces
    List<Face> faces = await faceDetector.processImage(image);     // List to store faces in the Image

   //    Saving Data Recieved From Firebase
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }



     //convert this image into bytes so it can be understood by the ML model and the custom painter as well
  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
          (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())    //Loading animation
          : (_imageFile == null)
          ? Center(child: Text('No image selected'))       //if image null message
          : Center(
        child: FittedBox(                                  // Box in center to display image
          child: SizedBox(
            width: _image.width.toDouble(),
            height: _image.height.toDouble(),
            child: CustomPaint(
              painter: FacePainter(_image, _faces),                // Call to CustomPainter Class
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageAndDetectFaces,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}



/************************** Custom Painter Class************************/

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}