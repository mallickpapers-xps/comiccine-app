import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';

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
            icon: _isImporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
            onPressed: _isImporting ? null : _importComic,
          ),
        ],
      ),
      body: _importedComics.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('Your library is empty', style: TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text('Tap + to import PDF, CBZ, or Images', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _importedComics.length,
              itemBuilder: (context, index) {
                final comic = _importedComics[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                    title: Text(comic['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(comic['size']!, style: const TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.play_circle_fill, color: Color(0xFF3B82F6), size: 40),
                    onTap: () {
                      context.push('/cinematic?path=${Uri.encodeComponent(comic['path']!)}&name=${Uri.encodeComponent(comic['name']!)}');
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
        allowedExtensions: ['pdf', 'cbz', 'cbr', 'zip', 'jpg', 'png', 'jpeg'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final platformFile = result.files.first;

      if (platformFile.path == null) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not get file path. Try selecting from local storage, not cloud.'), backgroundColor: Colors.red),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${platformFile.name}';
      final sourceFile = File(platformFile.path!);
      final destFile = File(filePath);

      await sourceFile.copy(destFile.path);

      setState(() {
        _importedComics.add({
          'name': platformFile.name,
          'path': destFile.path,
          'size': '${(platformFile.size / 1024 / 1024).toStringAsFixed(2)} MB',
        });
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported: ${platformFile.name}'), backgroundColor: Colors.green),
      );

    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
