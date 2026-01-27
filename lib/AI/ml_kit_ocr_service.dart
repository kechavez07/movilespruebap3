import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitOcrService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Analiza una imagen usando Google ML Kit OCR
  /// Retorna un Map con nombre del estudiante y respuestas
  Future<Map<String, dynamic>> analyzeImage(File imageFile, int questionCount) async {
    print("📱 [MLKit] Iniciando análisis OCR...");
    print("📱 [MLKit] Archivo: ${imageFile.path}");
    print("📱 [MLKit] Preguntas esperadas: $questionCount");

    try {
      final inputImage = InputImage.fromFile(imageFile);
      print("📱 [MLKit] Procesando imagen con ML Kit...");
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;
      
      print("📱 [MLKit] ✅ Texto extraído (${fullText.length} caracteres)");
      print("📱 [MLKit] Texto completo:\n$fullText");
      
      // Analizar el texto para extraer nombre y respuestas
      String studentName = _extractStudentName(fullText);
      List<Map<String, dynamic>> answers = _extractAnswers(fullText, questionCount);
      
      print("📱 [MLKit] Nombre detectado: '$studentName'");
      print("📱 [MLKit] Respuestas encontradas: ${answers.length}");
      
      return {
        'studentName': studentName,
        'answers': answers,
      };
      
    } catch (e) {
      print("❌ [MLKit] Error: $e");
      rethrow;
    } finally {
      await textRecognizer.close();
    }
  }

  /// Extrae el nombre del estudiante del texto
  String _extractStudentName(String text) {
    print("📱 [MLKit] Buscando nombre del estudiante...");
    
    // Buscar líneas que contengan "Nombre:", "Estudiante:", etc.
    final lines = text.split('\n');
    
    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Patrones comunes para nombre
      if (lowerLine.contains('nombre:') || 
          lowerLine.contains('estudiante:') ||
          lowerLine.contains('alumno:')) {
        // Extraer el texto después de los dos puntos
        final parts = line.split(':');
        if (parts.length > 1) {
          String name = parts[1].trim();
          print("📱 [MLKit] ✅ Nombre encontrado: '$name'");
          return name;
        }
      }
    }
    
    // Si no se encuentra, buscar un nombre típico (dos palabras capitalizadas)
    final nameRegex = RegExp(r'\b([A-Z][a-z]+ [A-Z][a-z]+)\b');
    final match = nameRegex.firstMatch(text);
    if (match != null) {
      String name = match.group(1) ?? "";
      print("📱 [MLKit] ✅ Nombre detectado por patrón: '$name'");
      return name;
    }
    
    print("📱 [MLKit] ⚠️ No se encontró nombre");
    return "";
  }

  /// Extrae las respuestas del texto
  List<Map<String, dynamic>> _extractAnswers(String text, int questionCount) {
    print("📱 [MLKit] Extrayendo respuestas...");
    
    List<Map<String, dynamic>> answers = [];
    final lines = text.split('\n');
    
    // Buscar patrones como:
    // 1. A    1) A    1.- A    1: A
    // También buscar secuencias de letras A B C D
    
    final answerPattern = RegExp(r'(\d+)[.):\-\s]+([A-Da-d])');
    
    for (var line in lines) {
      final matches = answerPattern.allMatches(line);
      
      for (var match in matches) {
        int questionNum = int.tryParse(match.group(1) ?? "0") ?? 0;
        String answer = (match.group(2) ?? "").toUpperCase();
        
        if (questionNum > 0 && questionNum <= questionCount && answer.isNotEmpty) {
          print("📱 [MLKit] Respuesta encontrada: P$questionNum = $answer");
          answers.add({
            'q': questionNum,
            'val': answer,
          });
        }
      }
    }
    
    // Si no se encontraron respuestas con números, buscar secuencia de letras
    if (answers.isEmpty) {
      print("📱 [MLKit] ⚠️ No se encontraron respuestas con números, buscando secuencia...");
      
      final letterPattern = RegExp(r'\b([A-Da-d])\b');
      final letterMatches = letterPattern.allMatches(text);
      
      int questionNum = 1;
      for (var match in letterMatches) {
        if (questionNum > questionCount) break;
        
        String answer = (match.group(1) ?? "").toUpperCase();
        print("📱 [MLKit] Respuesta secuencial: P$questionNum = $answer");
        
        answers.add({
          'q': questionNum,
          'val': answer,
        });
        questionNum++;
      }
    }
    
    print("📱 [MLKit] Total de respuestas extraídas: ${answers.length}");
    return answers;
  }
}
