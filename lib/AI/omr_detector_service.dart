import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// 🎯 OMR (Optical Mark Recognition) Detector
/// 
/// Usa Gemini Flash para detectar VISUALMENTE qué círculos están pintados
/// en lugar de intentar hacer OCR del símbolo.
/// 
/// Ventajas:
/// - Detecta relleno vs vacío con visión real
/// - No depende de OCR de caracteres
/// - Muy preciso con imágenes claras
/// - Maneja variaciones de estilos (bolígrafo, marcador, etc)
class OMRDetectorService {
  static const String _modelName = 'gemini-2.5-flash';
  late final GenerativeModel _visionModel;

  OMRDetectorService() {
    final envKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    final dotenvKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final resolvedKey = envKey.isNotEmpty ? envKey : dotenvKey;

    print("🎯 [OMR Init] Buscando GEMINI_API_KEY...");
    print("🎯 [OMR Init] Desde const environment: ${envKey.isEmpty ? 'NO' : 'SÍ'}");
    print("🎯 [OMR Init] Desde .env: ${dotenvKey.isEmpty ? 'NO' : 'SÍ'}");
    print("🎯 [OMR Init] Clave resuelta: ${resolvedKey.isEmpty ? 'VACÍA ❌' : 'VÁLIDA ✅'}");

    if (resolvedKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY no configurada. Agrega tu clave en .env o usa --dart-define="GEMINI_API_KEY=tu_clave"',
      );
    }

    try {
      _visionModel = GenerativeModel(
        model: _modelName,
        apiKey: resolvedKey,
      );
      print("🎯 [OMR Init] ✅ Modelo Gemini inicializado correctamente");
    } catch (e) {
      print("❌ [OMR Init] Error al inicializar Gemini: $e");
      rethrow;
    }
  }

  /// Detecta respuestas usando OMR (detección visual de marcas)
  /// Retorna un Map con estructura: {'answers': [...], 'confidence': 0.0-1.0}
  Future<Map<String, dynamic>> detectAnswers(
    File imageFile,
    int questionCount,
  ) async {
    print("🎯 [OMR] Iniciando detección OMR (Optical Mark Recognition)...");
    print("🎯 [OMR] Modelo: $_modelName");
    print("🎯 [OMR] Buscando: CUADRADOS PINTADOS (no círculos)");
    print("🎯 [OMR] Imagen: ${imageFile.path}");
    print("🎯 [OMR] Preguntas esperadas: $questionCount");

    try {
      // Leer la imagen
      final imageBytes = await imageFile.readAsBytes();

      // Prompt especializado en OMR
      final prompt = '''
Eres un detector de OMR (Optical Mark Recognition) especializado en exámenes con formato de cuadrados.

TAREA CRÍTICA: Analiza esta imagen de un examen y detecta qué CUADRADOS están MARCADOS/PINTADOS/OSCUROS.

FORMATO ESPERADO del examen:
- Cada pregunta tiene 4 opciones
- Cada opción está en el formato: "A) □ texto" o "A) [ ] texto"
- El CUADRADO es el símbolo que está al lado de la letra (A, B, C, D)
- Si el CUADRADO está PINTADO/OSCURO/RELLENO = opción seleccionada
- Si el CUADRADO está VACÍO/BLANCO = opción no seleccionada

INSTRUCCIONES DE ANÁLISIS:
1. Localiza cada pregunta numerada
2. Para cada pregunta, identifica sus 4 opciones (A, B, C, D)
3. Busca VISUALMENTE qué CUADRADO está RELLENO/OSCURO/PINTADO
4. Asocia el CUADRADO relleno con la letra correspondiente (A, B, C o D)

IMPORTANTE:
- Estás buscando CUADRADOS (□ ■), NO círculos
- Un CUADRADO RELLENO/OSCURO (■ o pintado) = respuesta seleccionada
- Un CUADRADO VACÍO/BLANCO (□) = respuesta no seleccionada
- Solo busca VISUALMENTE si está relleno. No uses OCR.
- El CUADRADO relleno debe estar directamente después de la letra (A), B), C), D))
- Ignora completamente el texto de la respuesta, solo importa qué CUADRADO está marcado
- Una pregunta puede tener SOLO UN CUADRADO marcado

FORMATO DE RESPUESTA:
Devuelve SOLO un JSON válido con este estructura exacta, sin texto extra:
{
  "answers": [
    {"q": 1, "val": "B"},
    {"q": 2, "val": "A"},
    {"q": 3, "val": "C"}
  ]
}

ESPECIFICACIONES:
- q = número de pregunta (1-$questionCount)
- val = letra de la opción con CUADRADO RELLENO (A, B, C o D)
- Solo incluye preguntas donde detectes CLARAMENTE un CUADRADO pintado/oscuro
- Si no estás 100% seguro, omite esa pregunta
- El JSON debe ser válido y parseable

BUSCA ESPECÍFICAMENTE CUADRADOS:
1. CUADRADO después de "A)" con relleno/oscuro = respuesta A
2. CUADRADO después de "B)" con relleno/oscuro = respuesta B
3. CUADRADO después de "C)" con relleno/oscuro = respuesta C
4. CUADRADO después de "D)" con relleno/oscuro = respuesta D

EJEMPLOS DE LO QUE BUSCAS:
- Correcto: "A) ■ Respuesta" (CUADRADO lleno/relleno/oscuro = MARCADO)
- Correcto: "B) ■ Respuesta" (CUADRADO lleno/relleno/oscuro = MARCADO)
- Incorrecto: "A) □ Respuesta" (CUADRADO vacío/blanco = NO MARCADO)
- Incorrecto: "C) □ Respuesta" (CUADRADO vacío/blanco = NO MARCADO)

⚠️ ATENCIÓN: NO confundas:
- CUADRADOS con CÍRCULOS
- CUADRADOS VACÍOS (□) con CUADRADOS RELLENOS (■)
- Las letras D y O con los CUADRADOS dibujados

Concéntrate SOLO en detectar CUADRADOS (forma rectangular) que están OSCUROS/RELLENOS.
''';


      print("🎯 [OMR] Enviando a Gemini Vision...");

      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final responseText = response.text ?? '';
      print("🎯 [OMR] Respuesta de Gemini:\n$responseText");

      // Parsear respuesta
      final answers = _parseOMRResponse(responseText, questionCount);

      print("🎯 [OMR] ✅ Detectadas ${answers.length} respuestas");

      return {
        'answers': answers,
        'confidence': _estimateConfidence(answers, questionCount),
        'source': 'omr',
      };
    } catch (e) {
      print("❌ [OMR] Error: $e");
      return {'answers': [], 'confidence': 0.0, 'error': e.toString()};
    }
  }

  /// Parsea la respuesta JSON de Gemini
  List<Map<String, dynamic>> _parseOMRResponse(
    String responseText,
    int questionCount,
  ) {
    List<Map<String, dynamic>> answers = [];

    try {
      // Buscar JSON en la respuesta (puede haber texto extra)
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}');

      if (jsonStart < 0 || jsonEnd < 0) {
        print("⚠️ [OMR] No se encontró JSON en la respuesta");
        return answers;
      }

      final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);
      print("🎯 [OMR] JSON extraído: $jsonStr");

      // Parsear manualmente (sin dependencias)
      // Buscar patrón: "q": N, "val": "X"
      // Más flexible: permite espacios variables
      final pattern = RegExp(r'"q"\s*:\s*(\d+)\s*,\s*"val"\s*:\s*"([A-D])"', multiLine: true);
      final matches = pattern.allMatches(jsonStr);

      if (matches.isEmpty) {
        print("⚠️ [OMR] No se encontraron respuestas en el patrón esperado");
        return answers;
      }

      for (final match in matches) {
        try {
          final questionNum = int.parse(match.group(1)!);
          final answer = match.group(2)!;

          if (questionNum > 0 && questionNum <= questionCount) {
            answers.add({
              'q': questionNum,
              'val': answer,
            });
            print("🎯 [OMR] ✅ P$questionNum: $answer");
          } else {
            print("⚠️ [OMR] Pregunta fuera de rango: P$questionNum (esperadas: 1-$questionCount)");
          }
        } catch (e) {
          print("⚠️ [OMR] Error al parsear match: ${match.group(0)} - Error: $e");
        }
      }

      print("🎯 [OMR] Total de respuestas extraídas: ${answers.length}/$questionCount");
      return answers;
    } catch (e) {
      print("❌ [OMR] Error crítico al parsear respuesta: $e");
      return answers;
    }
  }

  /// Estima el nivel de confianza basado en cobertura
  double _estimateConfidence(
    List<Map<String, dynamic>> answers,
    int questionCount,
  ) {
    if (answers.isEmpty) return 0.0;
    // Gemini 2.5 Flash tiene mejor precisión visual que 1.5 Flash
    // Así que podemos confiar más en los resultados
    final coverage = answers.length / questionCount;
    
    // Si detecta la mayoría de preguntas, alta confianza (0.95)
    // Si detecta al menos 50%, confianza media-alta (0.85)
    // Menos del 50%, confianza media (0.70)
    if (coverage > 0.8) {
      return 0.95;
    } else if (coverage > 0.5) {
      return 0.85;
    } else {
      return 0.70;
    }
  }
}
