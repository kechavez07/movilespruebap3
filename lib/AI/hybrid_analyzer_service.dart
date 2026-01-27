import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'gemini_config.dart';

/// Servicio híbrido que combina Gemini Vision + ML Kit OCR
/// para máxima precisión en detección de respuestas
class HybridAnalyzerService {
  late final GenerativeModel _model;
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  HybridAnalyzerService() {
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
    );
  }

  /// Analiza imagen usando Gemini Vision + ML Kit OCR como respaldo
  Future<Map<String, dynamic>> analyzeImage(File imageFile, int questionCount) async {
    print("🔵⚫ [HybridAnalyzer] Iniciando análisis híbrido...");
    print("🔵⚫ [HybridAnalyzer] Archivo: ${imageFile.path}");
    
    try {
      // PASO 1: Intentar con Gemini Vision (primero)
      print("🔵 [HybridAnalyzer] PASO 1: Usando Gemini Vision...");
      final geminiResult = await _analyzeWithGemini(imageFile, questionCount);
      
      if (geminiResult != null && geminiResult['answers'] != null) {
        final answers = geminiResult['answers'] as List;
        print("🔵 [HybridAnalyzer] ✅ Gemini detectó ${answers.length} respuestas");
        
        // Si Gemini encontró todas las respuestas, usarlo
        if (answers.length == questionCount) {
          print("🔵 [HybridAnalyzer] ✅ Gemini encontró TODAS las respuestas, usando resultado");
          await textRecognizer.close();
          return geminiResult;
        }
        
        // Si Gemini encontró ALGUNAS respuestas, complementar con OCR
        print("⚠️ [HybridAnalyzer] Gemini solo encontró ${answers.length}/$questionCount");
        print("🔵 [HybridAnalyzer] PASO 2: Complementando con ML Kit OCR...");
        
        final ocrResult = await _analyzeWithOCR(imageFile, questionCount);
        final mergedResult = _mergeResults(geminiResult, ocrResult, questionCount);
        
        print("🔵 [HybridAnalyzer] ✅ Resultado híbrido: ${mergedResult['answers'].length} respuestas");
        await textRecognizer.close();
        return mergedResult;
      }
      
      // Si Gemini falló completamente, usar solo OCR
      print("⚠️ [HybridAnalyzer] Gemini falló, usando solo ML Kit OCR");
      final ocrResult = await _analyzeWithOCR(imageFile, questionCount);
      await textRecognizer.close();
      return ocrResult;
      
    } catch (e) {
      print("❌ [HybridAnalyzer] Error: $e");
      print("🔵 [HybridAnalyzer] Intentando con ML Kit OCR como respaldo...");
      
      final ocrResult = await _analyzeWithOCR(imageFile, questionCount);
      await textRecognizer.close();
      return ocrResult;
    }
  }

  /// Analiza con Gemini Vision (detecta círculos rellenos visualmente)
  Future<Map<String, dynamic>?> _analyzeWithGemini(File imageFile, int questionCount) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = TextPart("""
Analiza esta imagen de una prueba/examen de opción múltiple.

INSTRUCCIONES PRECISAS:
1. El estudiante debe pintar/rellenar/marcar la letra (A, B, C o D) de su respuesta
2. Busca las letras que están MARCADAS, PINTADAS, RELLENADAS o con un CÍRCULO NEGRO (●)
3. Extrae el nombre del estudiante del campo "Nombre:" o "Estudiante:"
4. Hay $questionCount preguntas numeradas del 1 al $questionCount

FORMATO DE RESPUESTA (SOLO JSON, sin markdown):
{
  "studentName": "Nombre del Estudiante",
  "answers": [
    {"q": 1, "val": "A"},
    {"q": 2, "val": "B"},
    {"q": 3, "val": "C"}
  ]
}

IMPORTANTE:
- Solo incluye las preguntas donde DETECTES una marca CLARA
- Si una pregunta NO tiene marca visible, NO la incluyas en answers
- Las letras pueden estar: pintadas con marcador, con círculo negro (●), resaltadas, o subrayadas
- "val" debe ser solo UNA letra: A, B, C o D
""");

      final imagePart = DataPart('image/jpeg', imageBytes);
      
      print("🔵 [Gemini] Enviando a modelo: ${GeminiConfig.modelName}");
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      String? text = response.text;
      if (text == null) {
        print("❌ [Gemini] response.text es null");
        return null;
      }

      print("🔵 [Gemini] Respuesta recibida:\n$text");
      
      // Limpiar markdown
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final result = jsonDecode(text) as Map<String, dynamic>;
      print("🔵 [Gemini] ✅ JSON parseado exitosamente");
      
      return result;
      
    } catch (e) {
      print("❌ [Gemini] Error: $e");
      return null;
    }
  }

  /// Analiza con ML Kit OCR (detecta texto y patrones)
  Future<Map<String, dynamic>> _analyzeWithOCR(File imageFile, int questionCount) async {
    print("⚫ [OCR] Analizando con ML Kit...");
    
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    
    String studentName = _extractStudentName(recognizedText.text);
    List<Map<String, dynamic>> answers = _detectAnswersFromOCR(recognizedText, questionCount);
    
    print("⚫ [OCR] Nombre: '$studentName'");
    print("⚫ [OCR] Respuestas detectadas: ${answers.length}");
    
    return {
      'studentName': studentName,
      'answers': answers,
    };
  }

  /// Combina resultados de Gemini + OCR (Gemini tiene prioridad)
  Map<String, dynamic> _mergeResults(
    Map<String, dynamic> geminiResult,
    Map<String, dynamic> ocrResult,
    int questionCount
  ) {
    print("🔵⚫ [Merge] Combinando resultados...");
    
    // Usar nombre de Gemini primero
    String studentName = geminiResult['studentName'] ?? ocrResult['studentName'] ?? "";
    
    // Crear mapa de respuestas por pregunta
    Map<int, String> answersMap = {};
    
    // 1. Agregar respuestas de Gemini (prioridad)
    for (var answer in geminiResult['answers'] as List) {
      int q = answer['q'];
      String val = answer['val'];
      answersMap[q] = val;
      print("🔵 [Merge] P$q: $val (de Gemini)");
    }
    
    // 2. Completar con respuestas de OCR (solo las que faltan)
    for (var answer in ocrResult['answers'] as List) {
      int q = answer['q'];
      String val = answer['val'];
      
      if (!answersMap.containsKey(q)) {
        answersMap[q] = val;
        print("⚫ [Merge] P$q: $val (de OCR)");
      }
    }
    
    // Convertir a lista
    List<Map<String, dynamic>> finalAnswers = answersMap.entries
        .map((e) => {'q': e.key, 'val': e.value})
        .toList()
      ..sort((a, b) => (a['q'] as int).compareTo(b['q'] as int));
    
    print("🔵⚫ [Merge] Total final: ${finalAnswers.length} respuestas");
    
    return {
      'studentName': studentName,
      'answers': finalAnswers,
    };
  }

  /// Detecta respuestas desde OCR
  List<Map<String, dynamic>> _detectAnswersFromOCR(RecognizedText recognizedText, int questionCount) {
    List<Map<String, dynamic>> answers = [];
    List<TextLine> allLines = [];
    
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        allLines.add(line);
      }
    }
    
    print("⚫ [OCR] Analizando ${allLines.length} líneas...");
    print("⚫ [OCR] ========== DUMPING ALL LINES ==========");
    for (int idx = 0; idx < allLines.length; idx++) {
      print("⚫ [OCR] LINE[$idx]: '${allLines[idx].text.trim()}'");
    }
    print("⚫ [OCR] ========== END DUMP ==========\n");
    
    for (int i = 0; i < allLines.length; i++) {
      String lineText = allLines[i].text.trim();
      
      // Buscar número de pregunta
      final questionMatch = RegExp(r'^(\d+)[.):\-\s]+').firstMatch(lineText);
      
      if (questionMatch != null) {
        int questionNum = int.parse(questionMatch.group(1)!);
        
        if (questionNum > 0 && questionNum <= questionCount) {
          print("\n⚫ [OCR] ========== QUESTION $questionNum ==========");
          print("⚫ [OCR] Found at line $i: '$lineText'");
          
          // Buscar opciones marcadas en las siguientes líneas
          String? selectedOption;
          
          for (int j = i + 1; j < allLines.length && j < i + 11; j++) {
            String optionLine = allLines[j].text.trim();
            
            print("⚫ [OCR]   LINE[$j]: '$optionLine'");
            
            // Si la línea comienza con un número, es la siguiente pregunta -> DETENER
            if (RegExp(r'^\d+[.):\-\s]+').hasMatch(optionLine)) {
              print("⚫ [OCR]     🛑 Hit next question at line $j, stopping search for Q$questionNum");
              break;
            }
            
            // IMPORTANTE: OCR lee 'O' para círculos VACÍOS y '•' para círculos RELLENOS
            // Solo buscar el bullet • que indica marca
            final bulletPattern = RegExp(r'•\s*([A-D])\s*\)');
            final bulletMatch = bulletPattern.firstMatch(optionLine);
            
            if (bulletMatch != null) {
              selectedOption = bulletMatch.group(1)!;
              print("⚫ [OCR]     ✅ FOUND: bullet • with option '$selectedOption'");
              break;
            }
            
            // Buscar otros símbolos rellenos (NO incluir O ni 0, ni X para evitar variables)
            // Solo buscar símbolos sólidos claros o marcas muy específicas
            final patterns = [
              // Círculos/cuadros rellenos antes de la letra: ● A)
              RegExp(r'[●⚫⬤◉■▪◆⬛]\s*([A-D])\s*\)'),
              
              // Letra seguida de paréntesis y luego marca: A) ●
              RegExp(r'([A-D])\s*\)\s*[●⚫⬤◉■▪◆⬛]'),
              
              // Letra marcada manualmente (sin paréntesis, ej: "A" pintada)
              // Requiere que esté al inicio de línea y seguida de espacio
              RegExp(r'^([A-D])\s+'), 
            ];
            
            bool found = false;
            for (int pIdx = 0; pIdx < patterns.length; pIdx++) {
              final match = patterns[pIdx].firstMatch(optionLine);
              if (match != null) {
                selectedOption = match.group(1)!;
                print("⚫ [OCR]     ✅ FOUND: pattern[$pIdx] with option '$selectedOption'");
                found = true;
                break;
              }
            }
            
            if (found) break;
            
            if (selectedOption != null) break;
          }
          
          if (selectedOption != null) {
            answers.add({'q': questionNum, 'val': selectedOption});
            print("⚫ [OCR] ✅ Q$questionNum: ANSWER = '$selectedOption'");
          } else {
            // ESTRATEGIA DE EXCLUSIÓN (Heurística)
            // Si no se detectó marca directa, buscar por exclusión:
            // Si hay 3 opciones con "O" (vacío) y 1 sin nada (o con basura), esa es la respuesta.
            print("⚫ [OCR] ⚠️ Q$questionNum: No direct mark found. Trying exclusion...");
            
            List<String> emptyOptions = [];
            List<String> unknownOptions = [];
            
            // Re-escanear las líneas de esta pregunta
            for (int j = i + 1; j < allLines.length && j < i + 11; j++) {
              String optionLine = allLines[j].text.trim();
              if (RegExp(r'^\d+[.):\-\s]+').hasMatch(optionLine)) break; // Stop at next question
              
              // Buscar patrón de opción: Letra + )
              final optMatch = RegExp(r'([A-D])\s*\)').firstMatch(optionLine);
              if (optMatch != null) {
                String letter = optMatch.group(1)!;
                
                // Chequear si tiene "O" o "o" o "0" antes
                 // pattern: (start or space) [Oo0] optional-space Letter
                final emptyPattern = RegExp(r'(?:^|\s)[Oo0cC]\s*' + letter);
                
                if (emptyPattern.hasMatch(optionLine)) {
                  emptyOptions.add(letter);
                  print("⚫ [OCR]     [Exclusion] detected EMPTY option: $letter");
                } else {
                  unknownOptions.add(letter);
                  print("⚫ [OCR]     [Exclusion] detected UNKNOWN/POTENTIAL option: $letter");
                }
              }
            }
            
            // Si hay exactamente 3 vacías y 1 desconocida, asumir la desconocida es la rellena (que OCR no leyó)
            if (emptyOptions.length == 3 && unknownOptions.length == 1) {
              String inferred = unknownOptions.first;
              print("⚫ [OCR] ✅ Q$questionNum: INFERRED ANSWER (Exclusion) = '$inferred'");
              answers.add({'q': questionNum, 'val': inferred});
            } else {
              print("⚫ [OCR] ⚠️ Q$questionNum: NO ANSWER DETECTED (Exclusion failed: Empty=${emptyOptions.length}, Unknown=${unknownOptions.length})");
            }
          }
          print("⚫ [OCR] ========== END Q$questionNum ==========\n");
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
