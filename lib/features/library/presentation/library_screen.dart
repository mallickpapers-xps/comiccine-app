import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ComicCine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _importComic(context),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text('Your library is empty', style: TextStyle(fontSize: 20, color: Colors.grey)),
            SizedBox(height: 10),
            Text('Tap + to import comics', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _importComic(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['cbz', 'cbr', 'zip', 'pdf', 'jpg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported: ${result.files.first.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
