
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/app_models.dart';

class AppProvider with ChangeNotifier {
  List<Materia> _materias = [];
  List<Estudiante> _estudiantes = [];
  List<Prueba> _pruebas = [];
  List<Pregunta> _preguntas = [];
  List<Resultado> _resultados = [];

  List<Materia> get materias => _materias;
  List<Estudiante> get estudiantes => _estudiantes;
  List<Prueba> get pruebas => _pruebas;
  List<Pregunta> get preguntas => _preguntas;
  List<Resultado> get resultados => _resultados;

  // -- Materias --
  Future<void> loadMaterias() async {
    _materias = await DatabaseHelper.instance.readAllMaterias();
    notifyListeners();
  }

  Future<void> addMateria(Materia m) async {
    await DatabaseHelper.instance.createMateria(m);
    await loadMaterias();
  }
  
  Future<void> deleteMateria(int id) async {
    await DatabaseHelper.instance.deleteMateria(id);
    await loadMaterias();
  }

  // -- Estudiantes --
  Future<void> loadEstudiantes() async {
    _estudiantes = await DatabaseHelper.instance.readAllEstudiantes();
    notifyListeners();
  }

  Future<void> addEstudiante(Estudiante e) async {
    await DatabaseHelper.instance.createEstudiante(e);
    await loadEstudiantes();
  }

  // -- Pruebas --
  Future<void> loadPruebas(int materiaId) async {
    _pruebas = await DatabaseHelper.instance.readPruebasByMateria(materiaId);
    notifyListeners();
  }

  Future<void> addPrueba(Prueba p) async {
    await DatabaseHelper.instance.createPrueba(p);
    await loadPruebas(p.materiaId);
  }

  // -- Preguntas --
  Future<void> loadPreguntas(int pruebaId) async {
    _preguntas = await DatabaseHelper.instance.readPreguntasByPrueba(pruebaId);
    notifyListeners();
  }

  Future<void> addPregunta(Pregunta p) async {
    await DatabaseHelper.instance.createPregunta(p);
    await loadPreguntas(p.pruebaId);
  }
  
  Future<void> deletePregunta(int id, int pruebaId) async {
    await DatabaseHelper.instance.deletePregunta(id);
    await loadPreguntas(pruebaId);
  }

  // -- Resultados --
  Future<void> loadResultados(int pruebaId) async {
    _resultados = await DatabaseHelper.instance.readResultadosByPrueba(pruebaId);
    notifyListeners();
  }

  Future<void> addResultado(Resultado r) async {
    await DatabaseHelper.instance.createResultado(r);
    await loadResultados(r.pruebaId);
  }
}
