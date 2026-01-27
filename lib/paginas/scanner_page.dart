
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../logica/database/db_helper.dart';
import '../AI/hybrid_analyzer_service.dart';
import '../whitgest/ux/widgets.dart';

class ScannerPage extends StatefulWidget {
  final Prueba prueba;
  const ScannerPage({super.key, required this.prueba});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  File? _image;
  bool _isAnalyzing = false;
  String? _analysisError;
  Map<String, dynamic>? _analysisResult;
  double _calculatedScore = 0.0;
  List<Map<String, dynamic>> _questionResults = [];
  
  // Selection
  Estudiante? _selectedStudent;
  final TextEditingController _newStudentNameCtrl = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    print("📷 [ScannerPage] Iniciando selección de imagen...");
    print("📷 [ScannerPage] Fuente: ${source == ImageSource.camera ? 'Cámara' : 'Galería'}");
    
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    
    if (picked != null) {
      print("📷 [ScannerPage] ✅ Imagen seleccionada: ${picked.path}");
      setState(() {
        _image = File(picked.path);
        _analysisResult = null;
        _analysisError = null;
      });
      print("📷 [ScannerPage] Iniciando análisis...");
      _analyze();
    } else {
      print("📷 [ScannerPage] ❌ No se seleccionó ninguna imagen");
    }
  }

  Future<void> _analyze() async {
    print("🔍 [ScannerPage] Iniciando análisis...");
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });
    
    final provider = Provider.of<AppProvider>(context, listen: false);
    final questions = provider.preguntas;
    
    print("🔍 [ScannerPage] Preguntas cargadas: ${questions.length}");
    
    try {
      print("🔍 [ScannerPage] Creando servicio Híbrido (Gemini + OCR)...");
      HybridAnalyzerService service = HybridAnalyzerService();
      
      print("🔍 [ScannerPage] Llamando a analyzeImage...");
      var rawResult = await service.analyzeImage(_image!, questions.length);
      
      print("🔍 [ScannerPage] ✅ Resultado recibido");
      print("🔍 [ScannerPage] Resultado: $rawResult");
      
      if (rawResult.isEmpty) {
        print("❌ [ScannerPage] Error: resultado vacío");
        throw Exception("No se pudo analizar la imagen.");
      }
      
      print("🔍 [ScannerPage] Iniciando calificación...");
      // Grading Logic
      double score = 0;
      List<dynamic> studentAnswers = rawResult['answers'] ?? [];
      List<Map<String, dynamic>> questionResults = [];
      
      print("🔍 [ScannerPage] Respuestas del estudiante: ${studentAnswers.length}");
      
      for (var ans in studentAnswers) {
        int qIndex = (ans['q'] as int) - 1;
        if (qIndex >= 0 && qIndex < questions.length) {
          String val = ans['val']?.toString() ?? "";
          String correctAnswer = questions[qIndex].respuestaCorrecta.trim().toUpperCase();
          String studentAnswer = val.trim().toUpperCase();
          bool isCorrect = studentAnswer == correctAnswer;
          
          print("🔍 [ScannerPage] P${qIndex + 1}: Estudiante='$studentAnswer' Correcta='$correctAnswer' ${isCorrect ? '✅' : '❌'}");
          
          if (isCorrect) {
            score += questions[qIndex].valor;
          }
          
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
      
      print("🔍 [ScannerPage] Calificación calculada: $score / ${questions.length}");
      
      // Rellenar preguntas no respondidas
      for (int i = 0; i < questions.length; i++) {
        if (!questionResults.any((q) => q['numero'] == i + 1)) {
          print("🔍 [ScannerPage] Pregunta ${i + 1} no respondida");
          questionResults.add({
            'numero': i + 1,
            'texto': questions[i].texto,
            'respuesta_estudiante': "(No respondida)",
            'respuesta_correcta': questions[i].respuestaCorrecta.trim().toUpperCase(),
            'correcta': false,
            'valor': questions[i].valor,
          });
        }
      }
      
      // Ordenar por número de pregunta
      questionResults.sort((a, b) => (a['numero'] as int).compareTo(b['numero'] as int));
      
      // Attempt to match student name
      String detectedName = rawResult['studentName'] ?? "";
      print("🔍 [ScannerPage] Nombre detectado: '$detectedName'");
      
      Estudiante? match;
      if (detectedName.isNotEmpty) {
        try {
          match = provider.estudiantes.firstWhere((e) => e.nombre.toLowerCase().contains(detectedName.toLowerCase()));
          print("🔍 [ScannerPage] ✅ Estudiante encontrado: ${match.nombre}");
        } catch (_) {
          print("🔍 [ScannerPage] ⚠️ Estudiante no encontrado en BD");
        }
      }

      print("🔍 [ScannerPage] ✅ Análisis completado exitosamente");
      setState(() {
        _isAnalyzing = false;
        _analysisResult = rawResult;
        _calculatedScore = score;
        _questionResults = questionResults;
        _newStudentNameCtrl.text = detectedName;
        _selectedStudent = match;
        _analysisError = null;
      });
    } catch (e) {
      print("❌ [ScannerPage] Error en análisis: $e");
      print("❌ [ScannerPage] Tipo de error: ${e.runtimeType}");
      setState(() {
        _isAnalyzing = false;
        _analysisError = e.toString();
      });
      if (mounted) {
        showSnackBar(context, "Error al analizar: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Prueba")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image Preview
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.grey.shade200),
              child: _image == null 
                  ? const Center(child: Icon(Icons.image, size: 50, color: Colors.grey))
                  : Image.file(_image!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            
            // Buttons
            if (!_isAnalyzing)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PrimaryButton(
                  text: "Cámara", 
                  icon: Icons.camera_alt,
                  onPressed: () => _pickImage(ImageSource.camera)
                ),
                PrimaryButton(
                  text: "Galería", 
                  icon: Icons.photo,
                  onPressed: () => _pickImage(ImageSource.gallery)
                ),
              ],
            ),

            if (_isAnalyzing)
               Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   children: [
                     const CircularProgressIndicator(),
                     const SizedBox(height: 10),
                     Text("Analizando prueba con IA...", style: TextStyle(color: Colors.grey.shade600)),
                   ],
                 ),
               ),

            // Error Section
            if (_analysisError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "❌ Error al analizar",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _analysisError!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "💡 Consejos:\n• Verifica tu conexión a Internet\n• Comprueba que hayas configurado la API Key de Gemini\n• Intenta de nuevo en unos segundos",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Results Section
            if (_analysisResult != null && _analysisError == null) ...[
              const SizedBox(height: 20),
              const Divider(),
              
              // Score Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _calculatedScore >= (_questionResults.length / 2) ? Colors.green.shade50 : Colors.orange.shade50,
                  border: Border.all(
                    color: _calculatedScore >= (_questionResults.length / 2) ? Colors.green : Colors.orange,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      "📊 Calificación",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_calculatedScore.toStringAsFixed(1)} / ${_questionResults.length}",
                      style: kTitleStyle.copyWith(
                        color: _calculatedScore >= (_questionResults.length / 2) ? Colors.green : Colors.orange,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${((_calculatedScore / _questionResults.length) * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Correctas/Incorrectas Summary
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text("✅ Correctas", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${_questionResults.where((q) => q['correcta'] == true).length}",
                            style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text("❌ Incorrectas", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "${_questionResults.where((q) => q['correcta'] == false).length}",
                            style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Desglose de Preguntas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📋 Desglose de Respuestas", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questionResults.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final q = _questionResults[index];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: q['correcta'] ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: q['correcta'] ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "P${q['numero']}. ",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: Text(
                                      q['texto'],
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    q['correcta'] ? "✅" : "❌",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Tu respuesta:",
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          q['respuesta_estudiante'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: q['correcta'] ? Colors.green : Colors.red,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Respuesta correcta:",
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                        Text(
                                          q['respuesta_correcta'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
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
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Student Selection
              const Text("Estudiante:", style: TextStyle(fontWeight: FontWeight.bold)),
              Consumer<AppProvider>(builder: (ctx, prov, _) {
                 return DropdownButton<Estudiante>(
                   isExpanded: true,
                   hint: const Text("Seleccionar Estudiante"),
                   value: _selectedStudent,
                   items: prov.estudiantes.map((e) => DropdownMenuItem(value: e, child: Text(e.nombre))).toList(),
                   onChanged: (val) {
                     setState(() => _selectedStudent = val);
                   },
                 );
              }),
              const Text("O crear nuevo:"),
              CustomInput(label: "Nombre Estudiante", controller: _newStudentNameCtrl),
              
              const SizedBox(height: 20),
              PrimaryButton(
                text: "Guardar Resultado",
                onPressed: _saveResult,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _saveResult() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    int studentId;
    if (_selectedStudent != null) {
      studentId = _selectedStudent!.id!;
    } else if (_newStudentNameCtrl.text.isNotEmpty) {
      // Create new student
      Estudiante newStudent = Estudiante(nombre: _newStudentNameCtrl.text, identificacion: "AUTO-${DateTime.now().millisecondsSinceEpoch}");
      studentId = await DatabaseHelper.instance.createEstudiante(newStudent);
      await provider.loadEstudiantes(); // Refresh
    } else {
      showSnackBar(context, "Debes seleccionar o crear un estudiante.", isError: true);
      return;
    }

    Resultado res = Resultado(
      pruebaId: widget.prueba.id!,
      estudianteId: studentId,
      calificacion: _calculatedScore,
      fechaRealizacion: DateTime.now(),
    );

    await provider.addResultado(res);
    Navigator.pop(context); // Go back to details
    showSnackBar(context, "Resultado guardado correctamente.");
  }
}
