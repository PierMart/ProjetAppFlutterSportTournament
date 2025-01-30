import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'tournois_en_cours.dart';

class JsonFileContentView extends StatefulWidget {
  final File file;

  const JsonFileContentView({super.key, required this.file});

  @override
  _JsonFileContentViewState createState() => _JsonFileContentViewState();
}

class _JsonFileContentViewState extends State<JsonFileContentView> {
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    String content = await widget.file.readAsString();
    List<dynamic> jsonData = jsonDecode(content);
    setState(() {
      _students = List<Map<String, dynamic>>.from(jsonData);
    });
  }

  Future<void> _saveFile() async {
    String jsonContent = jsonEncode(_students);
    await widget.file.writeAsString(jsonContent);
  }

  Future<void> _deleteStudent(int index) async {
    setState(() {
      _students.removeAt(index);
    });
    await _saveFile();
  }

  void _showAddStudentDialog() {
    final _formKey = GlobalKey<FormState>();
    String lastName = '';
    String firstName = '';
    String school = '';
    String gender = '';
    String birthDate = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un élève'),
          content: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  onChanged: (value) => lastName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  onChanged: (value) => firstName = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prénom';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'École'),
                  onChanged: (value) => school = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une école';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Sexe'),
                  value: gender.isEmpty ? null : gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value!;
                    });
                  },
                  items: ['M', 'F']
                      .map((sex) => DropdownMenuItem<String>(
                            value: sex,
                            child: Text(sex),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Map<String, dynamic> newStudent = {
                    'lastName': lastName,
                    'firstName': firstName,
                    'gender': gender,
                    'grade': '',
                    'school': school,
                    'city': '',
                  };
                  _addStudent(newStudent);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addStudent(Map<String, dynamic> newStudent) async {
    setState(() {
      _students.add(newStudent);
    });
    await _saveFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
      ),
      body: Stack(
        children: [
          _students.isEmpty
              ? const Center(child: Text("Aucun élève trouvé."))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100.0), // Add padding to the bottom
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    var student = _students[index];
                    return ListTile(
                      title: Text("${student['lastName']} ${student['firstName']}"),
                      subtitle: Text("École: ${student['school']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteStudent(index);
                        },
                      ),
                    );
                  },
                ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: _showAddStudentDialog,
                  child: const Icon(Icons.add),
                  tooltip: 'Ajouter un élève',
                ),
                FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TournoisEnCours()),
                    );
                  },
                  child: const Icon(Icons.play_arrow),
                  tooltip: 'Lancer le tournoi',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}