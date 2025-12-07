import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;

  // Zoom controls
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
        });
        return;
      }

      // Use the back camera to capture pictures
      CameraDescription camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.max,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Get zoom range
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    await _controller!.setZoomLevel(clampedZoom);

    setState(() {
      _currentZoom = clampedZoom;
    });
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 0.5).clamp(_minZoom, _maxZoom);
    _setZoom(newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 0.5).clamp(_minZoom, _maxZoom);
    _setZoom(newZoom);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isInitialized = false;
                });
                _initializeCamera();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Full screen camera preview with zoom controls
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview - full screen without cropping
        Center(
          child: CameraPreview(_controller!),
        ),

        // Zoom controls overlay
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Zoom level indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentZoom.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Zoom slider and buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Zoom out button
                    IconButton(
                      onPressed: _currentZoom > _minZoom ? _zoomOut : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.white,
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Zoom slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: _currentZoom,
                          min: _minZoom,
                          max: _maxZoom,
                          onChanged: (value) => _setZoom(value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Zoom in button
                    IconButton(
                      onPressed: _currentZoom < _maxZoom ? _zoomIn : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.white,
                      iconSize: 36,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
