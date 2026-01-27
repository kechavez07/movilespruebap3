import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class BubbleDetectorService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Analiza una imagen detectando círculos/burbujas rellenas
  Future<Map<String, dynamic>> analyzeImage(File imageFile, int questionCount) async {
    print("⚫ [BubbleDetector] Iniciando análisis...");
    print("⚫ [BubbleDetector] Archivo: ${imageFile.path}");
    print("⚫ [BubbleDetector] Preguntas esperadas: $questionCount");

    try {
      // 1. Primero extraer el nombre con OCR
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String fullText = recognizedText.text;
      String studentName = _extractStudentName(fullText);
      
      print("⚫ [BubbleDetector] Nombre detectado: '$studentName'");
      print("⚫ [BubbleDetector] Texto completo extraído:\n$fullText");

      // 2. Detectar burbujas rellenas
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception("No se pudo decodificar la imagen");
      }

      print("⚫ [BubbleDetector] Imagen cargada: ${image.width}x${image.height}");

      // 3. Buscar patrones de respuestas (1. A B C D, 2. A B C D, etc.)
      List<Map<String, dynamic>> answers = await _detectBubbles(image, recognizedText, questionCount);
      
      print("⚫ [BubbleDetector] ✅ Análisis completado");
      print("⚫ [BubbleDetector] Respuestas detectadas: ${answers.length}");

      await textRecognizer.close();

      return {
        'studentName': studentName,
        'answers': answers,
      };

    } catch (e) {
      print("❌ [BubbleDetector] Error: $e");
      await textRecognizer.close();
      rethrow;
    }
  }

  /// Detecta respuestas marcadas buscando letras resaltadas o con símbolos
  Future<List<Map<String, dynamic>>> _detectBubbles(
    img.Image image, 
    RecognizedText recognizedText, 
    int questionCount
  ) async {
    print("⚫ [BubbleDetector] Detectando respuestas marcadas...");
    
    List<Map<String, dynamic>> answers = [];
    List<TextLine> allLines = [];
    
    // Recolectar todas las líneas en orden
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        allLines.add(line);
      }
    }
    
    print("⚫ [BubbleDetector] Total de líneas: ${allLines.length}");
    print("⚫ [BubbleDetector] ========== DUMPING ALL LINES ==========");
    for (int idx = 0; idx < allLines.length; idx++) {
      print("⚫ [BubbleDetector] LINE[$idx]: '${allLines[idx].text.trim()}'");
    }
    print("⚫ [BubbleDetector] ========== END DUMP ==========\n");
    
    // Buscar números de pregunta
    for (int i = 0; i < allLines.length; i++) {
      String lineText = allLines[i].text.trim();
      
      // Buscar patrón: número de pregunta
      final questionMatch = RegExp(r'^(\d+)[.):\-\s]+').firstMatch(lineText);
      
      if (questionMatch != null) {
        int questionNum = int.parse(questionMatch.group(1)!);
        
        if (questionNum > 0 && questionNum <= questionCount) {
          print("\n⚫ [BubbleDetector] ========== QUESTION $questionNum ==========");
          print("⚫ [BubbleDetector] Found at line $i: '$lineText'");
          
          // Buscar las opciones A, B, C, D en las siguientes 10 líneas
          String? selectedOption;
          
          for (int j = i + 1; j < allLines.length && j < i + 11; j++) {
            String optionLine = allLines[j].text.trim();
            
            print("⚫ [BubbleDetector]   LINE[$j]: '$optionLine'");
            
            // Si la línea comienza con un número, es la siguiente pregunta -> DETENER
            if (RegExp(r'^\d+[.):\-\s]+').hasMatch(optionLine)) {
              print("⚫ [BubbleDetector]     🛑 Hit next question at line $j, stopping search for Q$questionNum");
              break;
            }
            
            // IMPORTANTE: OCR lee 'O' para círculos VACÍOS y '•' para círculos RELLENOS
            // Solo buscar símbolos que indican MARCA, ignorar 'O'
            
            // ESTRATEGIA 1: Buscar bullet • (el más común para marcas)
            final bulletPattern = RegExp(r'•\s*([A-D])\s*\)');
            final bulletMatch = bulletPattern.firstMatch(optionLine);
            
            if (bulletMatch != null) {
              selectedOption = bulletMatch.group(1)!;
              print("⚫ [BubbleDetector]     ✅ FOUND: bullet • with option '$selectedOption'");
              break;
            }
            
            // Buscar otros símbolos rellenos
            // IMPORTANTE: Eliminada la 'X' y checkbox para evitar falsos positivos con álgebra
            final filledPatterns = [
              RegExp(r'[●⚫⬤◉■▪◆⬛]\s*([A-D])\s*\)'),
              RegExp(r'([A-D])\s*\)\s*[●⚫⬤◉■▪◆⬛•]'),
            ];
            
            bool found = false;
            for (int pIdx = 0; pIdx < filledPatterns.length; pIdx++) {
              final match = filledPatterns[pIdx].firstMatch(optionLine);
              if (match != null) {
                selectedOption = match.group(1)!;
                print("⚫ [BubbleDetector]     ✅ FOUND: pattern[$pIdx] with option '$selectedOption'");
                found = true;
                break;
              }
            }
            
            if (found) break;
            
            // ESTRATEGIA 2: Buscar letra sola sin paréntesis (cuando está pintada/marcada)
            // Ejemplo: "B 31" en lugar de "B) 31"
            final paintedPattern = RegExp(r'^([A-D])\s+\d+');
            final paintedMatch = paintedPattern.firstMatch(optionLine);
            
            if (paintedMatch != null) {
              selectedOption = paintedMatch.group(1)!;
              print("⚫ [BubbleDetector]     ✅ FOUND: painted letter '$selectedOption'");
              break;
            }
          }
          
          if (selectedOption != null) {
            answers.add({
              'q': questionNum,
              'val': selectedOption,
            });
            print("⚫ [BubbleDetector] ✅ Q$questionNum: ANSWER = '$selectedOption'");
          } else {
            // ESTRATEGIA DE EXCLUSIÓN (Heurística)
            print("⚫ [BubbleDetector] ⚠️ Q$questionNum: No direct mark found. Trying exclusion...");
            
            List<String> emptyOptions = [];
            List<String> unknownOptions = [];
            
            for (int j = i + 1; j < allLines.length && j < i + 11; j++) {
              String optionLine = allLines[j].text.trim();
              if (RegExp(r'^\d+[.):\-\s]+').hasMatch(optionLine)) break;
              
              final optMatch = RegExp(r'([A-D])\s*\)').firstMatch(optionLine);
              if (optMatch != null) {
                String letter = optMatch.group(1)!;
                final emptyPattern = RegExp(r'(?:^|\s)[Oo0cC]\s*' + letter);
                
                if (emptyPattern.hasMatch(optionLine)) {
                  emptyOptions.add(letter);
                  print("⚫ [BubbleDetector]     [Exclusion] detected EMPTY option: $letter");
                } else {
                  unknownOptions.add(letter);
                  print("⚫ [BubbleDetector]     [Exclusion] detected UNKNOWN option: $letter");
                }
              }
            }
            
            if (emptyOptions.length == 3 && unknownOptions.length == 1) {
              String inferred = unknownOptions.first;
              print("⚫ [BubbleDetector] ✅ Q$questionNum: INFERRED ANSWER (Exclusion) = '$inferred'");
              answers.add({'q': questionNum, 'val': inferred});
            } else {
              print("⚫ [BubbleDetector] ⚠️ Q$questionNum: NO ANSWER DETECTED (Exclusion failed)");
            }
          }
          print("⚫ [BubbleDetector] ========== END Q$questionNum ==========\n");
        }
      }
    }
    
    return answers;
  }
  /// Extrae el nombre del estudiante del texto
  String _extractStudentName(String text) {
    print("⚫ [BubbleDetector] Buscando nombre...");
    
    final lines = text.split('\n');
    
    for (var line in lines) {
      final lowerLine = line.toLowerCase();
      
      if (lowerLine.contains('nombre:') || 
          lowerLine.contains('estudiante:') ||
          lowerLine.contains('alumno:')) {
        final parts = line.split(':');
        if (parts.length > 1) {
          String name = parts[1].trim();
          print("⚫ [BubbleDetector] ✅ Nombre: '$name'");
          return name;
        }
      }
    }
    
    // Buscar patrón de nombre (dos o más palabras capitalizadas)
    final nameRegex = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b');
    final match = nameRegex.firstMatch(text);
    if (match != null) {
      String name = match.group(1) ?? "";
      print("⚫ [BubbleDetector] ✅ Nombre por patrón: '$name'");
      return name;
    }
    
    print("⚫ [BubbleDetector] ⚠️ No se encontró nombre");
    return "";
  }
}
