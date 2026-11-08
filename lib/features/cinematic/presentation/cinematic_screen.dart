import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';

enum ViewMode { normal, mobile, cinematic }

class CinematicShot {
  final double x;
  final double y;
  final double width;
  final double height;
  final Duration duration;

  CinematicShot({required this.x, required this.y, required this.width, required this.height, this.duration = const Duration(seconds: 3)});
}

class CinematicScreen extends StatefulWidget {
  final String type;
  final String path;
  final String fileName;

  const CinematicScreen({super.key, required this.type, required this.path, required this.fileName});

  @override
  State<CinematicScreen> createState() => _CinematicScreenState();
}

class _CinematicScreenState extends State<CinematicScreen> with TickerProviderStateMixin {
  ViewMode _currentMode = ViewMode.normal;
  PdfController? _pdfController;
  List<String> _comicPages = [];
  int _currentPage = 0;
  
  // Cinematic Animation Variables (Fixed Null Safety)
  late AnimationController _animationController;
  Animation<Rect?>? _cameraAnimation;
  bool _isPlayingCinematic = false;
  int _currentShotIndex = 0;
  List<CinematicShot> _shots = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animationController.addListener(() {
      setState(() {}); 
    });
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isPlayingCinematic) {
        _playNextShot();
      }
    });
  }

  Future<void> _loadContent() async {
    if (widget.type == 'pdf') {
      _pdfController = PdfController(document: PdfDocument.openFile(widget.path));
    } else if (widget.type == 'comic') {
      final dir = Directory(widget.path);
      if (await dir.exists()) {
        final files = await dir.list().toList();
        _comicPages = files.where((f) => f is File && (f.path.endsWith('.jpg') || f.path.endsWith('.png') || f.path.endsWith('.jpeg'))).map((f) => f.path).toList();
        _comicPages.sort();
      }
    }
    if (mounted) setState(() {});
  }

  void _generateCinematicShots(double imageWidth, double imageHeight) {
    _shots = [
      CinematicShot(x: 0, y: 0, width: imageWidth * 0.6, height: imageHeight * 0.5),
      CinematicShot(x: imageWidth * 0.4, y: 0, width: imageWidth * 0.6, height: imageHeight * 0.5),
      CinematicShot(x: 0, y: imageHeight * 0.5, width: imageWidth * 0.5, height: imageHeight * 0.5),
      CinematicShot(x: imageWidth * 0.5, y: imageHeight * 0.5, width: imageWidth * 0.5, height: imageHeight * 0.5),
    ];
  }

  void _startCinematicPlayback(double imageWidth, double imageHeight) {
    if (_shots.isEmpty) _generateCinematicShots(imageWidth, imageHeight);
    
    setState(() {
      _isPlayingCinematic = true;
      _currentShotIndex = 0;
    });
    _playNextShot();
  }

  void _playNextShot() {
    if (_currentShotIndex >= _shots.length) {
      setState(() => _isPlayingCinematic = false);
      return;
    }

    final shot = _shots[_currentShotIndex];
    final targetRect = Rect.fromLTWH(shot.x, shot.y, shot.width, shot.height);
    
    // Fixed: Provide safe non-null default for begin value
    final beginRect = _cameraAnimation?.value ?? Rect.fromLTWH(0, 0, 800, 1200);
    
    _cameraAnimation = RectTween(
      begin: beginRect,
      end: targetRect,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.duration = shot.duration;
    _animationController.forward(from: 0.0);
    _currentShotIndex++;
  }

  void _stopCinematicPlayback() {
    _animationController.stop();
    setState(() => _isPlayingCinematic = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  void _toggleViewMode() {
    setState(() {
      _currentMode = _currentMode == ViewMode.normal ? ViewMode.mobile : (_currentMode == ViewMode.mobile ? ViewMode.cinematic : ViewMode.normal);
      if (_currentMode != ViewMode.cinematic) _stopCinematicPlayback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.fileName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_currentMode == ViewMode.cinematic ? '🎬 CINEMATIC MODE ACTIVE' : '${_currentMode.toString().split('.').last.toUpperCase()} • ${widget.type.toUpperCase()}', 
                 style: TextStyle(color: _currentMode == ViewMode.cinematic ? Colors.redAccent : Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: Icon(_currentMode == ViewMode.normal ? Icons.smartphone : (_currentMode == ViewMode.mobile ? Icons.movie : Icons.image)), onPressed: _toggleViewMode),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(child: _buildViewer()),
          
          if (widget.type != 'pdf')
            Positioned(
              bottom: 100,
              left: 20,
              child: FloatingActionButton.extended(
                backgroundColor: _isPlayingCinematic ? Colors.red : const Color(0xFF3B82F6),
                icon: Icon(_isPlayingCinematic ? Icons.stop : Icons.play_arrow, color: Colors.white),
                label: Text(_isPlayingCinematic ? 'Stop Cinematic' : 'Play Cinematic', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (_isPlayingCinematic) {
                    _stopCinematicPlayback();
                  } else {
                    _startCinematicPlayback(800, 1200); 
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    if (widget.type == 'pdf') {
      return _pdfController == null ? const CircularProgressIndicator(color: Colors.blue) : PdfView(controller: _pdfController!);
    } 
    
    if (widget.type == 'comic') {
      if (_comicPages.isEmpty) return const Center(child: Text('No images found.', style: TextStyle(color: Colors.red)));
      
      return PageView.builder(
        itemCount: _comicPages.length,
        onPageChanged: (index) { setState(() => _currentPage = index); _stopCinematicPlayback(); },
        scrollDirection: _currentMode == ViewMode.cinematic ? Axis.horizontal : Axis.vertical,
        itemBuilder: (context, index) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Fixed: Safely check for null value
              if (_isPlayingCinematic && _cameraAnimation?.value != null) {
                final rect = _cameraAnimation!.value!;
                final scaleX = constraints.maxWidth / rect.width;
                final scaleY = constraints.maxHeight / rect.height;
                final scale = min(scaleX, scaleY);
                
                final offsetX = (constraints.maxWidth - rect.width * scale) / 2 - rect.left * scale;
                final offsetY = (constraints.maxHeight - rect.height * scale) / 2 - rect.top * scale;

                return Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: PhotoView.customChild(
                      child: Image.file(File(_comicPages[index]), fit: BoxFit.none),
                      minScale: 1.0,
                      maxScale: 4.0,
                    ),
                  ),
                );
              }
              
              return PhotoView(
                imageProvider: FileImage(File(_comicPages[index])),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              );
            }
          );
        },
      );
    }
    return const Center(child: Text('Unsupported format for Cinematic Mode', style: TextStyle(color: Colors.white)));
  }
}
