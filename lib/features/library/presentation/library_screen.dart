import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:archive/archive_io.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, String>> _importedComics = [];
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ComicCine Library'),
        actions: [
          IconButton(
            icon: _isImporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Icon(Icons.add),
            onPressed: _isImporting ? null : _importComic,
          ),
        ],
      ),
      body: _importedComics.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Your library is empty', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  SizedBox(height: 10),
                  Text('Tap + to import PDF, CBZ, or Images', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _importedComics.length,
              itemBuilder: (context, index) {
                final comic = _importedComics[index];
                final isComic = comic['type'] == 'comic';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(isComic ? Icons.auto_stories : Icons.picture_as_pdf, color: isComic ? const Color(0xFF3B82F6) : Colors.red, size: 40),
                    title: Text(comic['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(comic['size']!, style: const TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.play_circle_fill, color: Color(0xFF3B82F6), size: 40),
                    onTap: () {
                      context.push('/cinematic?type=${comic['type']}&path=${Uri.encodeComponent(comic['path']!)}&name=${Uri.encodeComponent(comic['name']!)}');
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _importComic() async {
    try {
      setState(() => _isImporting = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'cbz', 'zip', 'jpg', 'png', 'jpeg'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final platformFile = result.files.first;
      if (platformFile.path == null) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not get file path. Select from local storage.'), backgroundColor: Colors.red),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = platformFile.name;
      final ext = fileName.split('.').last.toLowerCase();

      String finalPath = platformFile.path!;
      String type = 'image';

      if (ext == 'pdf') {
        type = 'pdf';
        finalPath = '${directory.path}/$fileName';
        await File(platformFile.path!).copy(finalPath);
      } else if (ext == 'cbz' || ext == 'zip') {
        type = 'comic';
        final folderName = fileName.replaceAll(RegExp(r'\.(cbz|zip)$'), '');
        final extractDir = Directory('${directory.path}/$folderName');
        
        if (!await extractDir.exists()) {
          await extractDir.create(recursive: true);
        }

        // Extract ZIP/CBZ
        final bytes = await File(platformFile.path!).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            final extractedFile = File('${extractDir.path}/${file.name}');
            await extractedFile.create(recursive: true);
            await extractedFile.writeAsBytes(data);
          }
        }
        finalPath = extractDir.path;
      } else {
        // Single Image
        type = 'image';
        finalPath = '${directory.path}/$fileName';
        await File(platformFile.path!).copy(finalPath);
      }

      setState(() {
        _importedComics.add({
          'name': fileName,
          'path': finalPath,
          'size': '${(platformFile.size / 1024 / 1024).toStringAsFixed(2)} MB',
          'type': type,
        });
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported: $fileName'), backgroundColor: Colors.green),
      );

    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
