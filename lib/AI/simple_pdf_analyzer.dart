import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Simple PDF Analyzer - Uses OCR only to extract answers from PDF
class SimplePdfAnalyzer {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final RegExp _questionPrefixPattern = RegExp(r'^(\d+)[.):\-\s]+');

  /// Analyzes a PDF file using OCR only (no Gemini)
  Future<Map<String, dynamic>> analyzePdfWithQuestions(
    File pdfFile,
    List<String> questions,
  ) async {
    try {
      print("📄 [SimplePdfAnalyzer] Analizando PDF: ${pdfFile.path}");
      print("📄 [SimplePdfAnalyzer] Preguntas: ${questions.length}");

      // Usar OCR para extraer texto del PDF
      final inputImage = InputImage.fromFile(pdfFile);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      // Extraer nombre del estudiante
      String studentName = _extractStudentName(recognizedText.text);

      // Detectar respuestas usando OCR
      List<Map<String, dynamic>> answers =
          _detectAnswersFromOCR(recognizedText, questions.length);

      print("📄 [SimplePdfAnalyzer] ✅ Nombre: '$studentName'");
      print("📄 [SimplePdfAnalyzer] ✅ Respuestas detectadas: ${answers.length}");

      await textRecognizer.close();

      return {
        'success': true,
        'message': 'Análisis simple completado',
        'answers': answers, // ← AQUÍ DEBE SER UNA LIST
        'studentName': studentName,
        'confidence': answers.length / questions.length,
      };
    } catch (e) {
      print("❌ [SimplePdfAnalyzer] Error: $e");
      await textRecognizer.close();
      return {
        'success': false,
        'message': 'Error analizando PDF: $e',
        'answers': [], // ← AQUÍ TAMBIÉN UNA LIST VACÍA
        'studentName': 'Unknown',
        'confidence': 0.0,
      };
    }
  }

  /// Extrae respuestas del texto OCR
  List<Map<String, dynamic>> _detectAnswersFromOCR(
    RecognizedText recognizedText,
    int questionCount,
  ) {
    List<Map<String, dynamic>> answers = [];
    List<TextLine> allLines = [];

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        allLines.add(line);
      }
    }

    print("📄 [SimplePdfAnalyzer] Analizando ${allLines.length} líneas...");

    // Para cada pregunta encontrada
    for (int i = 0; i < allLines.length; i++) {
      String lineText = allLines[i].text.trim();

      // Buscar número de pregunta
      final questionMatch = _questionPrefixPattern.firstMatch(lineText);

      if (questionMatch != null) {
        int questionNum = int.parse(questionMatch.group(1)!);

        if (questionNum > 0 && questionNum <= questionCount) {
          print("\n📄 [SimplePdfAnalyzer] Pregunta $questionNum");

          // Recolectar las 4 opciones después de la pregunta
          List<Map<String, dynamic>> inlineOptions = [];
          int j = i + 1;
          int nextQuestionLine = -1;

          // Buscar siguiente pregunta
          while (j < allLines.length && inlineOptions.length < 4) {
            String checkLine = allLines[j].text.trim();

            // Detectar siguiente pregunta
            final nextQMatch = _questionPrefixPattern.firstMatch(checkLine);
            if (nextQMatch != null &&
                int.parse(nextQMatch.group(1)!) > questionNum) {
              nextQuestionLine = j;
              break;
            }

            // Buscar opción A), B), C), D)
            final optMatch = RegExp(r'([A-D])\)').firstMatch(checkLine);
            if (optMatch != null) {
              String letter = optMatch.group(1)!;
              if (!inlineOptions.any((opt) => opt['letter'] == letter)) {
                inlineOptions.add({
                  'letter': letter,
                  'raw': checkLine,
                });
                print("📄 [SimplePdfAnalyzer]   Opción $letter: '$checkLine'");
              }
            }

            j++;
          }

          // NUEVA LÓGICA: Detectar cuadrados dibujados que OCR interpreta como D/O
          String? selectedOption;

          for (var inlineOpt in inlineOptions) {
            final letter = inlineOpt['letter'] as String;
            final raw = inlineOpt['raw'] as String;

            // Si comienza con D, O, o → cuadrado vacío
            // Si NO comienza → cuadrado pintado (respuesta)
            bool startsWithDrawnSquare =
                raw.startsWith('D') || raw.startsWith('O') || raw.startsWith('o');

            if (!startsWithDrawnSquare) {
              selectedOption = letter;
              print(
                  "📄 [SimplePdfAnalyzer] ✅ Q$questionNum Opción '$letter': CUADRADO PINTADO");
            } else {
              print(
                  "📄 [SimplePdfAnalyzer] ⚪ Q$questionNum Opción '$letter': CUADRADO VACÍO");
            }
          }

          if (selectedOption != null) {
            answers.add({'q': questionNum, 'val': selectedOption});
            print("📄 [SimplePdfAnalyzer] ✅ Q$questionNum: RESPUESTA = '$selectedOption'");
          } else {
            print("📄 [SimplePdfAnalyzer] ⚠️ Q$questionNum: SIN RESPUESTA");
          }
        }
      }
    }

    return answers;
  }

  /// Extrae nombre del estudiante
  String _extractStudentName(String text) {
    final lines = text.split('\n');

    for (var line in lines) {
      final lowerLine = line.toLowerCase();

      if (lowerLine.contains('nombre:') ||
          lowerLine.contains('estudiante:') ||
          lowerLine.contains('alumno:')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }
    }

    // Patrón de nombre
    final nameRegex = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b');
    final match = nameRegex.firstMatch(text);
    if (match != null) {
      return match.group(1) ?? "";
    }

    return "";
  }
}
