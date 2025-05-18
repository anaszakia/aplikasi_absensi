import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart'; // Import main.dart untuk mengakses navigatorKey

class CameraPage extends StatefulWidget {
  final bool isCheckIn;

  const CameraPage({super.key, required this.isCheckIn});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isReady = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) return;

      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      final CameraDescription cameraToUse = frontCamera ?? cameras.first;
      _controller = CameraController(cameraToUse, ResolutionPreset.medium);
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      // Ambil gambar
      final XFile imageFile = await _controller!.takePicture();

      // PERBAIKAN: Gunakan Navigator.pop dengan context dan kembalikan path foto
      if (mounted) {
        setState(() => _isTakingPicture = false);
        // Kembalikan path foto ke halaman sebelumnya
        Navigator.of(context).pop(imageFile.path);
      }
    } catch (e) {
      print("Error taking picture: $e");
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isCheckIn ? 'Absen Masuk' : 'Absen Pulang'),
          backgroundColor: widget.isCheckIn ? Colors.red : Colors.blue,
          leading: BackButton(
            onPressed:
                () => Navigator.of(
                  context,
                ).pop(null), // Kembalikan null jika pengguna membatalkan
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCheckIn ? 'Absen Masuk' : 'Absen Pulang'),
        backgroundColor: widget.isCheckIn ? Colors.red : Colors.blue,
        leading: BackButton(
          onPressed:
              () => Navigator.of(
                context,
              ).pop(null), // Kembalikan null jika pengguna membatalkan
        ),
      ),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller!)),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Colors.black,
            child: Center(
              child:
                  _isTakingPicture
                      ? CircularProgressIndicator(color: Colors.white)
                      : FloatingActionButton(
                        backgroundColor:
                            widget.isCheckIn ? Colors.red : Colors.blue,
                        onPressed: _captureImage,
                        child: Icon(Icons.camera_alt),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
