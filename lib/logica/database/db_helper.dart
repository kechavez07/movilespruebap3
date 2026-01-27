
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('evaluador_tests.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE materias (
  id $idType,
  nombre $textType,
  descripcion $textType
)
''');

    await db.execute('''
CREATE TABLE estudiantes (
  id $idType,
  nombre $textType,
  identificacion $textType
)
''');

    await db.execute('''
CREATE TABLE pruebas (
  id $idType,
  materiaId $intType,
  nombre $textType,
  nombreDocente $textType,
  introduccion $textType,
  fechaCreacion $textType,
  FOREIGN KEY (materiaId) REFERENCES materias (id)
)
''');

    await db.execute('''
CREATE TABLE preguntas (
  id $idType,
  pruebaId $intType,
  texto $textType,
  tipo $intType,
  opciones $textType,
  respuestaCorrecta $textType,
  valor $doubleType,
  FOREIGN KEY (pruebaId) REFERENCES pruebas (id)
)
''');

    await db.execute('''
CREATE TABLE resultados (
  id $idType,
  pruebaId $intType,
  estudianteId $intType,
  calificacion $doubleType,
  fechaRealizacion $textType,
  FOREIGN KEY (pruebaId) REFERENCES pruebas (id),
  FOREIGN KEY (estudianteId) REFERENCES estudiantes (id)
)
''');
  }

  // --- CRUD Materias ---
  Future<int> createMateria(Materia materia) async {
    final db = await instance.database;
    return await db.insert('materias', materia.toMap());
  }

  Future<List<Materia>> readAllMaterias() async {
    final db = await instance.database;
    final result = await db.query('materias');
    return result.map((json) => Materia.fromMap(json)).toList();
  }
  
  Future<int> updateMateria(Materia materia) async {
    final db = await instance.database;
    return db.update(
      'materias',
      materia.toMap(),
      where: 'id = ?',
      whereArgs: [materia.id],
    );
  }

  Future<int> deleteMateria(int id) async {
    final db = await instance.database;
    return await db.delete(
      'materias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Estudiantes ---
  Future<int> createEstudiante(Estudiante estudiante) async {
    final db = await instance.database;
    return await db.insert('estudiantes', estudiante.toMap());
  }

  Future<List<Estudiante>> readAllEstudiantes() async {
    final db = await instance.database;
    final result = await db.query('estudiantes');
    return result.map((json) => Estudiante.fromMap(json)).toList();
  }

  Future<int> updateEstudiante(Estudiante estudiante) async {
    final db = await instance.database;
    return db.update(
      'estudiantes',
      estudiante.toMap(),
      where: 'id = ?',
      whereArgs: [estudiante.id],
    );
  }

  Future<int> deleteEstudiante(int id) async {
    final db = await instance.database;
    return await db.delete(
      'estudiantes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Pruebas ---
  Future<int> createPrueba(Prueba prueba) async {
    final db = await instance.database;
    return await db.insert('pruebas', prueba.toMap());
  }

  Future<List<Prueba>> readPruebasByMateria(int materiaId) async {
    final db = await instance.database;
    final result = await db.query(
      'pruebas',
      where: 'materiaId = ?',
      whereArgs: [materiaId],
    );
    return result.map((json) => Prueba.fromMap(json)).toList();
  }

  // --- CRUD Preguntas ---
  Future<int> createPregunta(Pregunta pregunta) async {
    final db = await instance.database;
    return await db.insert('preguntas', pregunta.toMap());
  }

  Future<List<Pregunta>> readPreguntasByPrueba(int pruebaId) async {
    final db = await instance.database;
    final result = await db.query(
      'preguntas',
      where: 'pruebaId = ?',
      whereArgs: [pruebaId],
    );
    return result.map((json) => Pregunta.fromMap(json)).toList();
  }
  
  Future<int> updatePregunta(Pregunta pregunta) async {
    final db = await instance.database;
    return db.update(
      'preguntas',
      pregunta.toMap(),
      where: 'id = ?',
      whereArgs: [pregunta.id],
    );
  }
  
  Future<int> deletePregunta(int id) async {
    final db = await instance.database;
    return await db.delete(
      'preguntas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Resultados ---
  Future<int> createResultado(Resultado resultado) async {
    final db = await instance.database;
    return await db.insert('resultados', resultado.toMap());
  }
  
  Future<List<Resultado>> readResultadosByPrueba(int pruebaId) async {
    final db = await instance.database;
    final result = await db.query(
      'resultados',
      where: 'pruebaId = ?',
      whereArgs: [pruebaId],
    );
    return result.map((json) => Resultado.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
