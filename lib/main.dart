
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tournament_bracket/flutter_tournament_bracket.dart';
// Utilise un alias pour la bibliothèque path uniquement si nécessaire
import 'package:path/path.dart' as p; // Utiliser p comme alias pour path
import 'package:excel/excel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'pages/creation_tournoi.dart';
import 'pages/tournois_en_cours.dart';
import 'pages/json_file_view.dart';

// Point d'entrée principal
void main() {
  runApp(const MyApp());
}

// Helper pour la gestion de la base de données
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final dbFile =
        p.join(dbPath, filePath); // Utilisation de l'alias p pour path

    return await openDatabase(
      dbFile,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const table = '''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lastName TEXT NOT NULL,
        firstName TEXT NOT NULL,
        birthDate TEXT NOT NULL,
        gender TEXT NOT NULL,
        grade TEXT NOT NULL,
        school TEXT NOT NULL,
        city TEXT NOT NULL
      );
    ''';
    await db.execute(table);
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('students', data);
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final db = await instance.database;
    return await db.query('students');
  }
}

// Application principale
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    const String nomProf = ''; // Nom de l'utilisateur

    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: _isDarkTheme
          ? ThemeData.dark().copyWith(
              colorScheme: ThemeData.dark().colorScheme.copyWith(
                    primary: Colors.orange,
                  ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.orange,
              ),
            )
          : ThemeData.light().copyWith(
              colorScheme: ThemeData.light().colorScheme.copyWith(
                    primary: Colors.orange,
                  ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.orange,
              ),
            ),
      home: MyHomePage(
        title: 'Bienvenue $nomProf',
        toggleTheme: () {
          setState(() {
            _isDarkTheme = !_isDarkTheme;
          });
        },
      ),
    );
  }
}

// Page d'accueil
class MyHomePage extends StatefulWidget {
  final String title;
  final VoidCallback toggleTheme;

  const MyHomePage({super.key, required this.title, required this.toggleTheme});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'], // Filtres pour les formats autorisés
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      String districtName = "UnknownDistrict"; // Par défaut
      List<Map<String, dynamic>> students = [];

      // Accédez directement à A13 et A14
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet != null) {
          districtName = (sheet.rows[12][0]?.value?.toString() ?? '') +
              ' ' +
              (sheet.rows[13][0]?.value?.toString() ?? '');
          break; // On suppose qu'on ne traite qu'une feuille
        }
      }

      // Parcourez les données des élèves après la ligne 4
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        if (sheet != null) {
          for (var row in sheet.rows.skip(17)) {
            String lastName = row[0]?.value?.toString() ?? '';
            String firstName = row[1]?.value?.toString() ?? '';
            String birthDate = row[2]?.value?.toString() ?? '';
            String gender = row[3]?.value?.toString() ?? '';
            String grade = row[4]?.value?.toString() ?? '';
            String school = row[7]?.value?.toString() ?? '';
            String city = row[8]?.value?.toString() ?? '';

            students.add({
              'lastName': lastName,
              'firstName': firstName,
              'birthDate': birthDate,
              'gender': gender,
              'grade': grade,
              'school': school,
              'city': city,
            });
          }
        }
      }

      // Nettoyez et formatez le nom du fichier
      districtName = districtName.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final fileName = '$districtName Badminton.json';

      // Créez le répertoire et sauvegardez le fichier JSON
      final directory = await getApplicationDocumentsDirectory();
      final path = Directory('${directory.path}/studentDirectory');
      if (!await path.exists()) {
        await path.create(recursive: true);
      }

      final filePath = '${path.path}/$fileName';
      final jsonFile = File(filePath);
      await jsonFile.writeAsString(jsonEncode(students));

      print('Fichier JSON créé : $filePath');
    } else {
      print('Aucun fichier sélectionné');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Résultats',
          icon: const Icon(Icons.bar_chart),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ResultatsPage()),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Changer de thème',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreationTournoi()),
                );
              },
              child: const Text('Création de tournoi'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TournoisEnCours()),
                );
              },
              child: const Text('Tournois en cours'),
            ),
            const Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        tooltip: 'Ajouter les élèves',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Autres pages
class TournoisEnCours extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournois en cours'),
      ),
      body: const Center(
        child: Text('Tournois en cours'),
      ),
    );
  }
}

/*class CreationTournoi extends StatefulWidget {
  @override
  _CreationTournoiState createState() => _CreationTournoiState();
}

class _CreationTournoiState extends State<CreationTournoi> {
  List<File> _jsonFiles = [];
  bool _isHovered = false; // Variable pour savoir si la souris survole l'icône

  @override
  void initState() {
    super.initState();
    _loadJsonFiles();
  }

  // Charger tous les fichiers JSON dans le répertoire
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
          ? const Center(
              child: Text("Aucun fichier JSON trouvé dans le dossier."))
          : ListView.builder(
              itemCount: _jsonFiles.length,
              itemBuilder: (context, index) {
                final file = _jsonFiles[index];
                final fileName = file.path.split('/').last;

                return ListTile(
                  title: Text(fileName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _isHovered =
                                true; // Change la couleur quand on survole
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _isHovered =
                                false; // Retour à la couleur grise quand on quitte le survol
                          });
                        },
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: _isHovered
                                ? Colors.red
                                : Colors
                                    .grey, // Change la couleur en fonction du survol
                          ),
                          tooltip: "Supprimer le fichier",
                          onPressed: () async {
                            // Confirmation avant suppression
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirmation"),
                                content: Text(
                                    "Voulez-vous supprimer le fichier \"$fileName\" ?"),
                                actions: [
                                  TextButton(
                                    child: const Text("Annuler"),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text("Supprimer"),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            );

                            // Si confirmé, supprimer le fichier
                            if (confirm == true) {
                              await file.delete();
                              _loadJsonFiles(); // Recharger la liste après suppression
                            }
                          },
                        ),
                      ),
                      const Icon(Icons.arrow_forward),
                    ],
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
}*/

class ResultatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
      ),
      body: const Center(
        child: Text('Page Résultats'),
      ),
    );
  }
}

/*
class JsonFileContentView extends StatefulWidget {
  final File file;

  JsonFileContentView({required this.file});

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

  // Charger le fichier JSON
  Future<void> _loadFile() async {
    String content = await widget.file.readAsString();
    List<dynamic> jsonData = jsonDecode(content);
    setState(() {
      _students = List<Map<String, dynamic>>.from(jsonData);
    });
  }

  // Enregistrer les changements dans le fichier JSON
  Future<void> _saveFile() async {
    String jsonContent = jsonEncode(_students);
    await widget.file.writeAsString(jsonContent);
  }

  // Supprimer un élève du fichier
  Future<void> _deleteStudent(int index) async {
    setState(() {
      _students.removeAt(index);
    });
    await _saveFile(); // Sauvegarder les modifications dans le fichier
  }

  // Afficher un formulaire pour ajouter un élève
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
                    'grade': '', // Ajouter un champ "grade" si nécessaire
                    'school': school,
                    'city': '', // Ajouter un champ "city" si nécessaire
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

  // Ajouter un nouvel élève
  void _addStudent(Map<String, dynamic> newStudent) async {
    setState(() {
      _students.add(newStudent);
    });
    await _saveFile(); // Sauvegarder les modifications dans le fichier
  }

  // Fonction pour la création du tournoi
  void _createTournament() {
    // Implémenter la logique pour créer un tournoi
    print("Création du tournoi");
    // Exemple : Naviguer vers une nouvelle page ou afficher un dialogue
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.file.path.split('/').last),
    ),
    body: _students.isEmpty
        ? const Center(child: Text("Aucun élève trouvé."))
        : ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              var student = _students[index];
              return ListTile(
                title: Text("${student['lastName']} ${student['firstName']}"),
                subtitle: Text("École: ${student['school']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteStudent(index);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
    floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Centrer le bouton "Créer le tournoi"
        Align(
          alignment: Alignment.center,  // Aligner le bouton au centre
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Définir la couleur verte
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), // Ajuste la taille du bouton
            ),
            onPressed: _createTournament, // Appeler la fonction de création du tournoi
            child: const Text(
              'Créer le tournoi',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Ajouter un élève (aligné à droite)
        Align(
          alignment: Alignment.bottomRight,  // Aligner le bouton en bas à droite
          child: FloatingActionButton(
            onPressed: _showAddStudentDialog,
            child: const Icon(Icons.add),
            tooltip: 'Ajouter un élève',
          ),
        ),
      ],
    ),
  );
}
}
*/
