import 'dart:io';

/// Analizador simple de PDF sin IA (alternativa a Gemini)
/// Usa el nombre del archivo como identificador del estudiante
class SimplePdfAnalyzer {
  
  /// Analiza un PDF y extrae respuestas basándose en patrones simples
  Future<Map<String, dynamic>> analyzePdfWithQuestions(
    File pdfFile,
    List<String> questions,
  ) async {
    try {
      // Obtener el nombre del archivo como nombre del estudiante
      final fileName = pdfFile.path.split('/').last.replaceAll('.pdf', '').replaceAll('\\', '/').split('/').last;
      
      // Para análisis simple, pediremos que el PDF tenga formato específico:
      // Cada línea con formato: "1. A", "2. B", etc.
      // O que use el nombre del archivo para detectar respuestas
      
      // Por ahora, retornamos un formato que el usuario puede completar manualmente
      // O podemos intentar leer el contenido del PDF de otra manera
      
      print("⚠️ Análisis simple: Usando nombre de archivo como base");
      
      // Generar respuestas vacías que el usuario puede revisar
      final answers = _generateEmptyAnswers(questions.length);
      
      return {
        'studentName': fileName,
        'answers': answers,
      };
    } catch (e) {
      print("❌ Error al procesar PDF: $e");
      rethrow;
    }
  }

  /// Genera respuestas vacías para revisión manual
  List<Map<String, dynamic>> _generateEmptyAnswers(int questionCount) {
    List<Map<String, dynamic>> answers = [];
    
    for (int i = 1; i <= questionCount; i++) {
      answers.add({
        'q': i,
        'val': 'null', // Sin respuesta detectada
      });
    }

    return answers;
  }
}
