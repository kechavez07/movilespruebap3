
import 'dart:convert';
import '../models/app_models.dart';

class AikenParser {
  // Method to parse Aiken format text into a list of Pregunta objects
  // Note: These questions won't have an ID or TestID yet.
  static List<Pregunta> parse(String content, int pruebaId) {
    List<Pregunta> questions = [];
    List<String> lines = LineSplitter.split(content).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String? currentQuestionText;
    Map<String, String> currentOptions = {};
    String? currentAnswer;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      if (line.startsWith('ANSWER:')) {
        currentAnswer = line.substring(7).trim();
        
        // Finalize previous question
        if (currentQuestionText != null && currentOptions.isNotEmpty) {
          questions.add(Pregunta(
            pruebaId: pruebaId,
            texto: currentQuestionText,
            tipo: TipoPregunta.seleccionSimple, // Aiken is usually simple selection
            opciones: jsonEncode(currentOptions),
            respuestaCorrecta: currentAnswer,
            valor: 1.0,
          ));
          
          // Reset
          currentQuestionText = null;
          currentOptions = {};
          currentAnswer = null;
        }
      } else if (RegExp(r'^[A-Z]\)').hasMatch(line) || RegExp(r'^[A-Z]\.').hasMatch(line)) {
        // It's an option
        String key = line.substring(0, 1);
        String value = line.substring(2).trim();
        currentOptions[key] = value;
      } else {
        // It's part of the question text
        if (currentQuestionText == null) {
          currentQuestionText = line;
        } else {
          // Append if multiline question (though Aiken usually implies empty line separator, simple parser logic here)
          // Ideally Aiken questions are single blocks. If we hit a new line that isn't an option or ANSWER, it might be continuation.
          // But strict Aiken usually has the question, then options.
          // If we already have options, this shouldn't happen in valid Aiken.
          if (currentOptions.isEmpty) {
             currentQuestionText = "$currentQuestionText\n$line";
          }
        }
      }
    }
    
    return questions;
  }
}
