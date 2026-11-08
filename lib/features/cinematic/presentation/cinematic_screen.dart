import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';

enum ViewMode { normal, mobile, cinematic }

class CinematicScreen extends StatefulWidget {
  final String type; // 'pdf', 'comic', or 'image'
  final String path;
  final String fileName;

  const CinematicScreen({
    super.key, 
    required this.type, 
    required this.path, 
    required this.fileName,
  });

  @override
  State<CinematicScreen> createState() => _CinematicScreenState();
}

class _CinematicScreenState extends State<CinematicScreen> {
  ViewMode _currentMode = ViewMode.normal;
  PdfController? _pdfController;
  List<String> _comicPages = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    if (widget.type == 'pdf') {
      _pdfController = PdfController(document: PdfDocument.openFile(widget.path));
    } else if (widget.type == 'comic') {
      final dir = Directory(widget.path);
      if (await dir.exists()) {
        final files = await dir.list().toList();
        _comicPages = files
            .where((f) => f is File && (f.path.endsWith('.jpg') || f.path.endsWith('.png') || f.path.endsWith('.jpeg')))
            .map((f) => f.path)
            .toList();
        
        // Sort alphabetically to ensure correct page order
        _comicPages.sort();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _toggleViewMode() {
    setState(() {
      if (_currentMode == ViewMode.normal) {
        _currentMode = ViewMode.mobile;
      } else if (_currentMode == ViewMode.mobile) {
        _currentMode = ViewMode.cinematic;
      } else {
        _currentMode = ViewMode.normal;
      }
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
            Text('${_currentMode.toString().split('.').last.toUpperCase()} • ${widget.type.toUpperCase()}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_currentMode == ViewMode.normal ? Icons.smartphone : (_currentMode == ViewMode.mobile ? Icons.movie : Icons.image)),
            tooltip: 'Switch View Mode',
            onPressed: _toggleViewMode,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Main Viewer Area
          Center(
            child: _buildViewer(),
          ),

          // Page Indicator (For Comics)
          if (widget.type == 'comic' && _comicPages.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} / ${_comicPages.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          // Floating Zoom Controls
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (widget.type == 'pdf') _pdfController?.zoomIn();
                    // PhotoView handles pinch natively, button zoom can be added via controller if needed
                  },
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: Colors.black54,
                  child: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    if (widget.type == 'pdf') _pdfController?.zoomOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    if (widget.type == 'pdf') {
      return _pdfController == null 
          ? const CircularProgressIndicator(color: Colors.blue)
          : PdfView(
              controller: _pdfController!,
              scrollDirection: _currentMode == ViewMode.cinematic ? Axis.horizontal : Axis.vertical,
              pageLoader: const Center(child: CircularProgressIndicator(color: Colors.blue)),
              errorBuilder: (error) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
            );
    } 
    
    if (widget.type == 'comic') {
      if (_comicPages.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('No images found in this CBZ/ZIP file.', style: TextStyle(color: Colors.red)),
          ),
        );
      }
      
      return PageView.builder(
        itemCount: _comicPages.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        scrollDirection: _currentMode == ViewMode.cinematic ? Axis.horizontal : Axis.vertical,
        itemBuilder: (context, index) {
          return PhotoView(
            imageProvider: FileImage(File(_comicPages[index])),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        },
      );
    }

    // Fallback for single image
    return PhotoView(
      imageProvider: FileImage(File(widget.path)),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }
}
