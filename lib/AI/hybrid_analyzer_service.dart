import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'omr_detector_service.dart';

/// Servicio híbrido que combina Gemini Vision + ML Kit OCR
/// para máxima precisión en detección de respuestas
class HybridAnalyzerService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final RegExp _questionPrefixPattern = RegExp(r'^(\d+)[.):\-\s]+');

  HybridAnalyzerService() {
    // El detector de Gemini se crea en analyzeImage
  }

  /// Analiza imagen usando OMR (Gemini Vision) + OCR como respaldo
  Future<Map<String, dynamic>> analyzeImage(File imageFile, int questionCount) async {
    print("🔵⚫ [HybridAnalyzer] Iniciando análisis híbrido...");
    print("🔵⚫ [HybridAnalyzer] Archivo: ${imageFile.path}");
    print("🔵⚫ [HybridAnalyzer] Preguntas esperadas: $questionCount");
    
    // Verificación preliminar del archivo
    if (!imageFile.existsSync()) {
      print("❌ [HybridAnalyzer] Archivo de imagen NO existe: ${imageFile.path}");
      throw Exception("Archivo de imagen no encontrado");
    }
    
    final fileSize = await imageFile.length();
    print("🔵⚫ [HybridAnalyzer] Tamaño de archivo: $fileSize bytes");
    
    if (fileSize == 0) {
      print("❌ [HybridAnalyzer] El archivo de imagen está VACÍO");
      throw Exception("Archivo de imagen vacío");
    }
    
    try {
      // PASO 1: Intentar con OMR (Gemini Vision - detección visual)
      print("🔵⚫ [HybridAnalyzer] PASO 1: Usando OMR (Optical Mark Recognition)...");
      
      OMRDetectorService omrDetector = OMRDetectorService();
      final omrResult = await omrDetector.detectAnswers(imageFile, questionCount);
      
      final omrAnswers = omrResult['answers'] as List? ?? [];
      final omrConfidence = omrResult['confidence'] as double? ?? 0.0;
      
      print("🎯 [HybridAnalyzer] OMR detectó ${omrAnswers.length} respuestas");
      print("🎯 [HybridAnalyzer] 📊 Confianza: ${(omrConfidence * 100).toStringAsFixed(1)}%");
      
      // Si OMR tiene buena cobertura, usarlo
      if (omrAnswers.length >= questionCount * 0.85) {
        print("🎯 [HybridAnalyzer] ✅ Cobertura excelente, usando resultado de OMR");
        
        // Obtener nombre con OCR
        final ocrData = await _analyzeWithOCR(imageFile, questionCount);
        await textRecognizer.close();
        
        return {
          'studentName': ocrData['studentName'],
          'answers': omrAnswers,
          'stats': {'omr': omrAnswers.length, 'ocr': 0},
        };
      }
      
      // PASO 2: Complementar con OCR si OMR no tiene suficiente cobertura
      print("🔵⚫ [HybridAnalyzer] PASO 2: Complementando con OCR...");
      print("⚫ [HybridAnalyzer] Cobertura OMR: ${(omrAnswers.length / questionCount * 100).toStringAsFixed(1)}%");
      
      final ocrResult = await _analyzeWithOCR(imageFile, questionCount);
      final ocrAnswers = ocrResult['answers'] as List? ?? [];
      
      print("⚫ [HybridAnalyzer] OCR detectó ${ocrAnswers.length} respuestas");
      
      // Mergear resultados (OMR tiene prioridad)
      final mergedResult = _mergeOMRAndOCR(omrResult, ocrResult, questionCount);
      
      print("🔵⚫ [HybridAnalyzer] ✅ Resultado final: ${(mergedResult['answers'] as List).length} respuestas");
      
      await textRecognizer.close();
      return mergedResult;
      
    } catch (e) {
      print("❌ [HybridAnalyzer] Error: $e");
      print("❌ [HybridAnalyzer] Stack trace: ${StackTrace.current}");
      
      // Respaldo: intentar solo OCR
      print("🔄 [HybridAnalyzer] Intentando respaldo: OCR únicamente...");
      final ocrResult = await _analyzeWithOCR(imageFile, questionCount);
      await textRecognizer.close();
      return ocrResult;
    }
  }

  /// Combina resultados de OMR (prioritario) + OCR (complementario)
  Map<String, dynamic> _mergeOMRAndOCR(
    Map<String, dynamic> omrResult,
    Map<String, dynamic> ocrResult,
    int questionCount
  ) {
    print("🔵⚫ [Merge] Combinando resultados de OMR + OCR...");
    
    String studentName = ocrResult['studentName']?.toString().trim() ?? "";
    
    // Map para evitar duplicados
    Map<int, String> answersMap = {};
    
    // 1. Agregar respuestas de OMR (prioridad máxima)
    final omrAnswers = omrResult['answers'] as List? ?? [];
    for (var answer in omrAnswers) {
      try {
        int q = answer['q'] as int;
        String val = answer['val'].toString().toUpperCase();
        answersMap[q] = val;
        print("🎯 [Merge] P$q: $val (OMR)");
      } catch (e) {
        print("⚠️ [Merge] Error al procesar respuesta OMR: $answer");
      }
    }
    
    // 2. Completar con respuestas de OCR (solo faltantes)
    final ocrAnswers = ocrResult['answers'] as List? ?? [];
    for (var answer in ocrAnswers) {
      try {
        int q = answer['q'] as int;
        
        if (!answersMap.containsKey(q)) {
          String val = answer['val'].toString().toUpperCase();
          answersMap[q] = val;
          print("⚫ [Merge] P$q: $val (OCR - complementario)");
        }
      } catch (e) {
        print("⚠️ [Merge] Error al procesar respuesta OCR: $answer");
      }
    }
    
    // Convertir a lista ordenada
    List<Map<String, dynamic>> finalAnswers = answersMap.entries
        .map((e) => {'q': e.key, 'val': e.value})
        .toList()
      ..sort((a, b) => (a['q'] as int).compareTo(b['q'] as int));
    
    print("🔵⚫ [Merge] ✅ Total final: ${finalAnswers.length} respuestas");
    
    return {
      'studentName': studentName,
      'answers': finalAnswers,
      'stats': {'omr': omrAnswers.length, 'ocr': ocrAnswers.length},
    };
  }

  /// Analiza con ML Kit OCR (detecta texto y patrones)
  Future<Map<String, dynamic>> _analyzeWithOCR(File imageFile, int questionCount) async {
    print("⚫ [OCR] ========== INICIANDO ANÁLISIS OCR ==========");
    print("⚫ [OCR] Archivo: ${imageFile.path}");
    print("⚫ [OCR] Existe: ${imageFile.existsSync()}");
    print("⚫ [OCR] Tamaño: ${await imageFile.length()} bytes");
    
    print("⚫ [OCR] Creando InputImage desde archivo...");
    final inputImage = InputImage.fromFile(imageFile);
    print("⚫ [OCR] ✅ InputImage creado correctamente");
    
    print("⚫ [OCR] Enviando a TextRecognizer.processImage()...");
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    print("⚫ [OCR] ✅ processImage() completado");
    
    print("⚫ [OCR] ========== ANÁLISIS DE RESULTADO ==========");
    print("⚫ [OCR] Texto bruto reconocido: '${recognizedText.text}'");
    print("⚫ [OCR] Longitud de texto: ${recognizedText.text.length} caracteres");
    print("⚫ [OCR] Bloques de texto detectados: ${recognizedText.blocks.length}");
    
    if (recognizedText.blocks.isEmpty) {
      print("⚠️  [OCR] ⚠️  PROBLEMA: No se detectaron bloques de texto");
      print("⚠️  [OCR] Esto significa que ML Kit no pudo encontrar ningún texto en la imagen");
      print("⚠️  [OCR] Posibles causas:");
      print("⚠️  [OCR]   1. El PDF es una imagen escaneada (sin texto embebido)");
      print("⚠️  [OCR]   2. El texto está en un idioma no-latino");
      print("⚠️  [OCR]   3. La calidad de la imagen es muy baja");
      print("⚠️  [OCR]   4. El contraste es muy bajo para leer");
    } else {
      print("⚫ [OCR] ✅ Se encontraron bloques de texto:");
      for (int i = 0; i < recognizedText.blocks.length; i++) {
        final block = recognizedText.blocks[i];
        print("⚫ [OCR]   BLOQUE[$i]: ${block.lines.length} líneas");
        print("⚫ [OCR]     Texto: '${block.text}'");
        
        for (int j = 0; j < block.lines.length; j++) {
          final line = block.lines[j];
          print("⚫ [OCR]     Línea[$j]: '${line.text}'");
          print("⚫ [OCR]       Elementos: ${line.elements.length}");
        }
      }
    }
    
    String studentName = _extractStudentName(recognizedText.text);
    List<Map<String, dynamic>> answers = _detectAnswersFromOCR(recognizedText, questionCount);
    
    print("⚫ [OCR] ========== RESULTADO FINAL ==========");
    print("⚫ [OCR] Nombre extraído: '$studentName'");
    print("⚫ [OCR] Respuestas detectadas: ${answers.length}");
    print("⚫ [OCR] =====================================\n");
    
    return {
      'studentName': studentName,
      'answers': answers,
    };
  }

  /// Detecta respuestas desde OCR
  /// FORMATO REAL: Círculos y opciones en LÍNEAS SEPARADAS
  /// Los círculos pueden tener líneas de ruido entre ellos
  /// Mapeo: círculo[i] ↔ opción[i]
  List<Map<String, dynamic>> _detectAnswersFromOCR(RecognizedText recognizedText, int questionCount) {
    print("⚫ [OCRParser] ========== INICIANDO PARSER ==========");
    List<Map<String, dynamic>> answers = [];
    List<TextLine> allLines = [];
    final circleOnlyPattern = RegExp(r'^[O•●◉⚫⬤o0]{1,3}$');
    final inlineCircleOptionPattern = RegExp(r'^\s*([O0o•●◉⚫⬤]{1,3})\s*([A-D])\)');
    final filledPattern = RegExp(r'[•●◉⚫⬤]');
    
    print("⚫ [OCRParser] Extrayendo líneas de ${recognizedText.blocks.length} bloques...");
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        allLines.add(line);
      }
    }
    
    print("⚫ [OCRParser] Total de líneas extraídas: ${allLines.length}");
    print("⚫ [OCRParser] ========== DUMP DE TODAS LAS LÍNEAS ==========");
    
    if (allLines.isEmpty) {
      print("⚫ [OCRParser] ❌ NO HAY LÍNEAS PARA ANALIZAR");
    } else {
      for (int idx = 0; idx < allLines.length; idx++) {
        final line = allLines[idx];
        print("⚫ [OCRParser] LÍNEA[$idx]");
        print("⚫ [OCRParser]   Texto: '${line.text}'");
        print("⚫ [OCRParser]   Confianza: ${line.confidence}");
        print("⚫ [OCRParser]   Elementos: ${line.elements.length}");
      }
    }
    
    print("⚫ [OCRParser] ========== BUSCANDO PREGUNTAS ==========");
    
    // Para cada pregunta encontrada
    for (int i = 0; i < allLines.length; i++) {
      String lineText = allLines[i].text.trim();
      
      // Buscar número de pregunta: "1. ¿...", "2) ¿...", etc.
      final questionMatch = _questionPrefixPattern.firstMatch(lineText);
      
      if (questionMatch != null) {
        int questionNum = int.parse(questionMatch.group(1)!);
        
        if (questionNum > 0 && questionNum <= questionCount) {
          print("⚫ [OCRParser] ✅ Pregunta $questionNum encontrada en línea $i");
          print("⚫ [OCRParser]    Texto: '$lineText'");
          
          // PASO 1: Recolectar todos los círculos hasta la siguiente pregunta (o fin)
          List<int> circleLineIndices = [];
          int j = i + 1;
          int nextQuestionLine = -1;
          
          while (j < allLines.length) {
            String checkLine = allLines[j].text.trim();
            
            // Detectar siguiente pregunta
            final nextQMatch = _questionPrefixPattern.firstMatch(checkLine);
            if (nextQMatch != null && int.parse(nextQMatch.group(1)!) > questionNum) {
              nextQuestionLine = j;
              print("⚫ [OCRParser]    Siguiente pregunta en línea $j");
              break;
            }
            
            // Detectar línea que SOLO contiene círculo(s)
            if (circleOnlyPattern.hasMatch(checkLine)) {
              circleLineIndices.add(j);
              print("⚫ [OCRParser]    Círculo encontrado en línea $j: '$checkLine'");
            }
            
            j++;
          }
          
          print("⚫ [OCRParser]    Total círculos: ${circleLineIndices.length}");
          
          // PASO 2: Recolectar TODAS las opciones después de la pregunta
          List<String> options = [];
          j = i + 1;
          int optionSearchEnd = (nextQuestionLine >= 0) ? nextQuestionLine + 6 : allLines.length;
          if (optionSearchEnd > allLines.length) {
            optionSearchEnd = allLines.length;
          }
          List<Map<String, dynamic>> inlineOptions = [];
          
          print("⚫ [OCRParser]    Buscando opciones desde línea ${i+1} hasta $optionSearchEnd");
          
          while (j < optionSearchEnd && options.length < 4) {
            String checkLine = allLines[j].text.trim();
            
            // Buscar opción A), B), C), D)
            final optMatch = RegExp(r'([A-D])\)').firstMatch(checkLine);
            if (optMatch != null) {
              String letter = optMatch.group(1)!;
              if (!options.contains(letter)) {
                options.add(letter);
                print("⚫ [OCRParser]    Opción encontrada en línea $j: '$letter'");
                final inlineMatch = inlineCircleOptionPattern.firstMatch(checkLine);
                bool hasInlineCircle = false;
                bool inlineFilled = false;
                if (inlineMatch != null) {
                  final circleGroup = inlineMatch.group(1)?.trim() ?? '';
                  if (circleGroup.isNotEmpty) {
                    hasInlineCircle = true;
                    inlineFilled = filledPattern.hasMatch(circleGroup);
                  }
                }
                inlineOptions.add({
                  'letter': letter,
                  'hasCircle': hasInlineCircle,
                  'isFilled': inlineFilled,
                  'line': j,
                  'raw': checkLine,
                });
              }
            }
            
            j++;
          }
          
          print("⚫ [OCR] Found ${options.length} options: $options");
          
          // NUEVA LÓGICA: Detectar cuadrados dibujados que OCR interpreta como D/O
          // Si una línea de opción NO tiene D/O al inicio = cuadrado marcado = respuesta correcta
          String? selectedOption;
          
          for (var inlineOpt in inlineOptions) {
            final letter = inlineOpt['letter'] as String;
            final raw = inlineOpt['raw'] as String;
            
            // Si la línea comienza con D, O, O (mayúscula o minúscula), quiere decir que:
            // - El OCR interpretó el cuadrado dibujado como D/O
            // - El cuadrado NO está pintado (está vacío)
            // Si NO comienza con D/O, entonces el cuadrado SÍ está pintado (respuesta marcada)
            
            bool startsWithDrawnSquare = raw.startsWith('D') || raw.startsWith('O') || raw.startsWith('o');
            
            if (!startsWithDrawnSquare) {
              // Esta opción NO tiene el prefijo D/O, así que el cuadrado ESTÁ PINTADO
              selectedOption = letter;
              print("⚫ [OCR] ✅ Q$questionNum Option '$letter': CUADRADO PINTADO (sin prefijo D/O) :: '$raw'");
            } else {
              // Esta opción tiene prefijo D/O, el cuadrado está vacío
              print("⚫ [OCR] ⚪ Q$questionNum Option '$letter': CUADRADO VACÍO (prefijo D/O detectado) :: '$raw'");
            }
          }
          
          if (selectedOption != null) {
            answers.add({'q': questionNum, 'val': selectedOption});
            print("⚫ [OCR] ✅ Q$questionNum: RESPUESTA MARCADA = '$selectedOption'");
          } else {
            print("⚫ [OCR] ⚠️ Q$questionNum: NO SE ENCONTRÓ CUADRADO MARCADO");
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
