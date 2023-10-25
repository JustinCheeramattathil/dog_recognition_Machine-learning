import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWorking = false;
  String result = '';
  CameraController? cameraController;
  CameraImage? imgCamera;
  
  List<CameraDescription>?cameras;

  initCamera()async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController!.startImageStream((imageFromStream) => {
              if (!isWorking)
                {
                  isWorking = true,
                  imgCamera = imageFromStream,
                  runModelOnStreamFrames(),
                }
            });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  runModelOnStreamFrames() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera!.height,
        imageWidth: imgCamera!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true,
      );
      result = '';

      recognitions!.forEach((response) {
        result += response["label"] +
            " " +
            (response['confidence'] as double).toStringAsFixed(2) +
            "\n\n";
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    cameraController?.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Dogs Breed Recognizer'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/back.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 320,
                    width: 360,
                    child: Image.asset('assets/frame.jpg'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      initCamera();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 35),
                      height: 270,
                      width: 360,
                      child: imgCamera == null
                          ? Container(
                              height: 270,
                              width: 360,
                              child: const Icon(
                                Icons.photo_camera_front,
                                color: Colors.pink,
                                size: 40,
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: cameraController!.value.aspectRatio,
                              child: CameraPreview(cameraController!),
                            ),
                    ),
                  ),
                )
              ],
            ),
            Center(
                child: Container(
              margin: const EdgeInsets.only(top: 55),
              child: SingleChildScrollView(
                child: Text(
                  result,
                  style: const TextStyle(
                    backgroundColor: Colors.white54,
                    fontSize: 25,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ))
          ],
        ),
      ),
    ));
  }
}
