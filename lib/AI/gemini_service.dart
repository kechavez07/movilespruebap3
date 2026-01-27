
import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'gemini_config.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
    );
  }

  Future<Map<String, dynamic>> analyzeImage(File imageFile, int questionCount) async {
    print("🔵 [GeminiService] Iniciando análisis de imagen...");
    print("🔵 [GeminiService] Archivo: ${imageFile.path}");
    print("🔵 [GeminiService] Cantidad de preguntas: $questionCount");
    
    try {
      print("🔵 [GeminiService] Leyendo bytes de la imagen...");
      final imageBytes = await imageFile.readAsBytes();
      print("🔵 [GeminiService] ✅ Bytes leídos: ${imageBytes.length} bytes");
      
      print("🔵 [GeminiService] Preparando prompt para Gemini...");
      final prompt = TextPart("""
        Analiza esta imagen de una prueba / examen.
        1. Extrae el nombre del estudiante si está escrito (campo 'studentName').
        2. Para las preguntas enumeradas del 1 al $questionCount, identifica qué respuesta marcó el estudiante.
        
        Devuelve SOLO un JSON con este formato (sin markdown):
        {
          "studentName": "Nombre Detectado",
          "answers": [
            {"q": 1, "val": "A"}, 
            {"q": 2, "val": "V"},
            {"q": 3, "val": "Texto escrito"}
          ]
        }
        
        Si no detectas respuesta para una pregunta, pon "null".
        Para selección múltiple, usa una cadena como "A,B".
      """);

      print("🔵 [GeminiService] Creando DataPart con imagen...");
      final imagePart = DataPart('image/jpeg', imageBytes);

      print("🔵 [GeminiService] Enviando solicitud a Gemini API...");
      print("🔵 [GeminiService] Modelo: ${GeminiConfig.modelName}");
      print("🔵 [GeminiService] API Key: ${GeminiConfig.apiKey.substring(0, 10)}...");
      
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      print("🔵 [GeminiService] ✅ Respuesta recibida de Gemini");
      
      String? text = response.text;
      if (text == null) {
        print("❌ [GeminiService] Error: response.text es null");
        throw Exception("No response from AI");
      }

      print("🔵 [GeminiService] Respuesta cruda de Gemini:");
      print("🔵 [GeminiService] $text");
      
      // Clean markdown if present
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      print("🔵 [GeminiService] Texto limpio:");
      print("🔵 [GeminiService] $text");
      
      print("🔵 [GeminiService] Parseando JSON...");
      final result = jsonDecode(text);
      print("🔵 [GeminiService] ✅ JSON parseado exitosamente");
      print("🔵 [GeminiService] Resultado: $result");
      
      return result;
    } on SocketException catch (e) {
      print("❌ [GeminiService] Error de conexión: $e");
      print("💡 [GeminiService] Verifica: 1) Conexión a Internet activa, 2) Firewall, 3) VPN");
      rethrow;
    } on FormatException catch (e) {
      print("❌ [GeminiService] Error parsing JSON: $e");
      rethrow;
    } catch (e) {
      print("❌ [GeminiService] Error general: $e");
      print("❌ [GeminiService] Tipo de error: ${e.runtimeType}");
      rethrow;
    }
  }
}
