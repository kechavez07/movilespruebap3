import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../logica/database/db_helper.dart';
import '../AI/pdf_analyzer_service.dart';
import '../whitgest/ux/widgets.dart';

class BatchPdfScannerPage extends StatefulWidget {
  final Prueba prueba;
  const BatchPdfScannerPage({super.key, required this.prueba});

  @override
  State<BatchPdfScannerPage> createState() => _BatchPdfScannerPageState();
}

class _BatchPdfScannerPageState extends State<BatchPdfScannerPage> {
  List<File> _selectedPdfs = [];
  bool _isAnalyzing = false;
  String? _analysisError;
  List<Map<String, dynamic>> _batchResults = [];
  
  Future<void> _pickPdfs() async {
    print("📁 [BatchPdfScanner] Iniciando selección de PDFs...");
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        print("📁 [BatchPdfScanner] ✅ Archivos seleccionados: ${result.paths.length}");
        for (var path in result.paths) {
          print("📁 [BatchPdfScanner]   - $path");
        }
        setState(() {
          _selectedPdfs = result.paths.map((path) => File(path!)).toList();
          _analysisError = null;
        });
      } else {
        print("📁 [BatchPdfScanner] ❌ No se seleccionaron archivos");
      }
    } catch (e) {
      print("❌ [BatchPdfScanner] Error al seleccionar PDFs: $e");
      setState(() => _analysisError = "Error al seleccionar PDFs: $e");
    }
  }

  Future<void> _analyzePdfs() async {
    if (_selectedPdfs.isEmpty) {
      showSnackBar(context, "Selecciona al menos un PDF", isError: true);
      return;
    }

    print("\n🎯 [BatchPdfScanner] ========== INICIANDO ANÁLISIS DE LOTE ==========");
    print("🎯 [BatchPdfScanner] PDFs seleccionados: ${_selectedPdfs.length}");

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _batchResults = [];
    });

    final provider = Provider.of<AppProvider>(context, listen: false);
    final questions = provider.preguntas;
    print("🎯 [BatchPdfScanner] Preguntas cargadas: ${questions.length}\n");

    try {
      List<Map<String, dynamic>> results = [];
      PdfAnalyzerService pdfAnalyzer = PdfAnalyzerService(); // Nuevo servicio

      for (int i = 0; i < _selectedPdfs.length; i++) {
        final pdfFile = _selectedPdfs[i];
        final fileName = pdfFile.path.split('/').last.replaceAll('.pdf', '');

        print("\n📄 [BatchPdfScanner] ==========================================");
        print("📄 [BatchPdfScanner] PDF ${i + 1}/${_selectedPdfs.length}: $fileName");
        print("📄 [BatchPdfScanner] ==========================================\n");

        try {
          // Usar el nuevo servicio especializado en PDFs
          print("🔍 [BatchPdfScanner] Analizando PDF con PdfAnalyzerService...");
          var rawResult = await pdfAnalyzer.analyzePdf(pdfFile, questions.length);

          print("\n✅ [BatchPdfScanner] Análisis completado");
          print("📊 [BatchPdfScanner] Nombre: '${rawResult['studentName'] ?? fileName}'");
          print("📊 [BatchPdfScanner] Respuestas detectadas: ${(rawResult['answers'] as List?)?.length ?? 0}");

          // Calificar
          double score = 0;
          List<Map<String, dynamic>> questionResults = [];
          List<dynamic> studentAnswers = rawResult['answers'] ?? [];

          for (var ans in studentAnswers) {
            int qIndex = (ans['q'] as int) - 1;
            if (qIndex >= 0 && qIndex < questions.length) {
              String val = ans['val']?.toString() ?? "";
              String correctAnswer = questions[qIndex].respuestaCorrecta.trim().toUpperCase();
              String studentAnswer = val.trim().toUpperCase();
              bool isCorrect = studentAnswer == correctAnswer;

              print("📊 [BatchPdfScanner] P${qIndex + 1}: '$studentAnswer' vs '$correctAnswer' ${isCorrect ? '✅' : '❌'}");

              if (isCorrect) score += questions[qIndex].valor;

              questionResults.add({
                'numero': qIndex + 1,
                'texto': questions[qIndex].texto,
                'respuesta_estudiante': val.trim().isEmpty ? "(No respondida)" : val.trim(),
                'respuesta_correcta': correctAnswer,
                'correcta': isCorrect,
                'valor': questions[qIndex].valor,
              });
            }
          }

          // Rellenar preguntas no respondidas
          for (int j = 0; j < questions.length; j++) {
            if (!questionResults.any((q) => q['numero'] == j + 1)) {
              questionResults.add({
                'numero': j + 1,
                'texto': questions[j].texto,
                'respuesta_estudiante': "(No respondida)",
                'respuesta_correcta': questions[j].respuestaCorrecta.trim().toUpperCase(),
                'correcta': false,
                'valor': questions[j].valor,
              });
            }
          }

          questionResults.sort((a, b) => (a['numero'] as int).compareTo(b['numero'] as int));

          print("📊 [BatchPdfScanner] Calificación final: $score / ${questions.length} (${(score / questions.length * 100).toStringAsFixed(1)}%)\n");

          results.add({
            'studentName': rawResult['studentName'] ?? fileName,
            'fileName': fileName,
            'score': score,
            'totalQuestions': questions.length,
            'percentage': (score / questions.length * 100),
            'questionResults': questionResults,
            'correct': questionResults.where((q) => q['correcta'] == true).length,
            'incorrect': questionResults.where((q) => q['correcta'] == false).length,
          });

          print("✅ [BatchPdfScanner] $fileName guardado en resultados\n");
        } catch (e) {
          print("❌ [BatchPdfScanner] Error procesando $fileName: $e\n");
          results.add({
            'studentName': fileName,
            'fileName': fileName,
            'error': e.toString(),
          });
        }
      }

      print("\n🎉 [BatchPdfScanner] ========== ANÁLISIS COMPLETADO ==========");
      print("🎉 [BatchPdfScanner] Exitosos: ${results.where((r) => !r.containsKey('error')).length}");
      print("🎉 [BatchPdfScanner] Con error: ${results.where((r) => r.containsKey('error')).length}");
      print("🎉 [BatchPdfScanner] =========================================\n");

      // Limpiar
      await pdfAnalyzer.dispose();

      setState(() {
        _isAnalyzing = false;
        _batchResults = results;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = "Error al procesar PDFs: $e";
      });
      print("❌ [BatchPdfScanner] Error fatal: $e\n");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analizar PDFs (Lote)")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "📄 Selecciona uno o varios PDFs de respuestas.\nLa IA los analizará automáticamente.",
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // Botones de selección
            if (!_isAnalyzing) ...[
              ElevatedButton.icon(
                onPressed: _pickPdfs,
                icon: const Icon(Icons.upload_file),
                label: const Text("Seleccionar PDFs"),
              ),
              const SizedBox(height: 8),
              Text(
                "PDFs seleccionados: ${_selectedPdfs.length}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            if (_selectedPdfs.isNotEmpty && !_isAnalyzing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _analyzePdfs,
                icon: const Icon(Icons.auto_awesome),
                label: const Text("Analizar PDFs"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                ),
              ),
            ],

            if (_isAnalyzing)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      "Analizando ${_selectedPdfs.length} PDF(s)...",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

            // Error
            if (_analysisError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "❌ ${_analysisError!}",
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Resultados
            if (_batchResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                "📊 Resultados",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _batchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final result = _batchResults[index];

                  if (result.containsKey('error')) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result['studentName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "❌ Error: ${result['error']}",
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildResultCard(context, result);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Map<String, dynamic> result) {
    final bool isPassing = result['percentage'] >= 60;

    return Container(
      decoration: BoxDecoration(
        color: isPassing ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: isPassing ? Colors.green : Colors.orange,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['studentName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${result['score'].toStringAsFixed(1)} / ${result['totalQuestions']} (${result['percentage'].toStringAsFixed(1)}%)",
                    style: TextStyle(
                      fontSize: 14,
                      color: isPassing ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isPassing ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPassing ? "✅ Aprobó" : "⚠️ Reprobó",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text("✅ Correctas", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${result['correct']}",
                            style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text("❌ Incorrectas", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${result['incorrect']}",
                            style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("📋 Detalles:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result['questionResults'].length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, qIndex) {
                    final q = result['questionResults'][qIndex];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: q['correcta'] ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("P${q['numero']}. ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Expanded(
                                child: Text(q['texto'], style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                              Text(q['correcta'] ? "✅" : "❌"),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Tu respuesta:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(q['respuesta_estudiante'], style: TextStyle(fontWeight: FontWeight.bold, color: q['correcta'] ? Colors.green : Colors.red, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Correcta:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(q['respuesta_correcta'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _saveResult(result),
                    child: const Text("💾 Guardar Resultado"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResult(Map<String, dynamic> result) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    try {
      // Crear o buscar estudiante
      final studentName = result['studentName'];
      Estudiante? student;

      try {
        student = provider.estudiantes.firstWhere((e) => e.nombre.toLowerCase() == studentName.toLowerCase());
      } catch (_) {
        // Crear nuevo
        student = Estudiante(
          nombre: studentName,
          identificacion: "AUTO-${DateTime.now().millisecondsSinceEpoch}",
        );
        final id = await DatabaseHelper.instance.createEstudiante(student);
        student = Estudiante(id: id, nombre: student.nombre, identificacion: student.identificacion);
        await provider.loadEstudiantes();
      }

      // Guardar resultado
      final res = Resultado(
        pruebaId: widget.prueba.id!,
        estudianteId: student.id!,
        calificacion: result['score'],
        fechaRealizacion: DateTime.now(),
      );

      await provider.addResultado(res);
      showSnackBar(context, "✅ Resultado de ${result['studentName']} guardado", isError: false);
    } catch (e) {
      showSnackBar(context, "❌ Error al guardar: $e", isError: true);
    }
  }
}
