import 'dart:io';
import 'package:flutter/material.dart';
import 'json_file_view.dart';
import 'package:path_provider/path_provider.dart';

class CreationTournoi extends StatefulWidget {
  const CreationTournoi({super.key});

  @override
  _CreationTournoiState createState() => _CreationTournoiState();
}

class _CreationTournoiState extends State<CreationTournoi> {
  List<File> _jsonFiles = [];

  @override
  void initState() {
    super.initState();
    _loadJsonFiles();
  }

  Future<void> _loadJsonFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = Directory('${directory.path}/studentDirectory');

    if (await path.exists()) {
      setState(() {
        _jsonFiles = path
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList();
      });
    } else {
      setState(() {
        _jsonFiles = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fichiers JSON disponibles"),
      ),
      body: _jsonFiles.isEmpty
          ? const Center(child: Text("Aucun fichier JSON trouvé dans le dossier."))
          : ListView.builder(
              itemCount: _jsonFiles.length,
              itemBuilder: (context, index) {
                final file = _jsonFiles[index];
                final fileName = file.path.split('/').last;

                return ListTile(
                  title: Text(fileName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirmation"),
                          content: Text("Voulez-vous supprimer le fichier \"$fileName\" ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Supprimer"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await file.delete();
                        _loadJsonFiles();
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JsonFileContentView(file: file),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}