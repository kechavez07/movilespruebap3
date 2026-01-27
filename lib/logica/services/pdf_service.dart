
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/app_models.dart';

class PdfService {
  static Future<String> generateExamPdf(Prueba prueba, Materia materia, List<Pregunta> preguntas) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(prueba, materia),
            pw.SizedBox(height: 20),
            _buildInstructions(prueba),
            pw.Divider(),
            pw.SizedBox(height: 20),
            ...preguntas.map((p) => _buildQuestionItem(p, preguntas.indexOf(p) + 1)),
          ];
        },
      ),
    );

    Directory? directory = await getApplicationDocumentsDirectory();
    String safeName = prueba.nombre.replaceAll(RegExp(r'[^\w\s]+'), '');
    String path = "${directory.path}/Examen_$safeName.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  static pw.Widget _buildHeader(Prueba prueba, Materia materia) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(materia.nombre.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Text("Docente: ${prueba.nombreDocente}"),
        pw.Text("Prueba: ${prueba.nombre}"),
        pw.Text("Fecha: ${prueba.fechaCreacion.toIso8601String().split(' ')[0]}"),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          pw.Text("Nombre Estudiante: _________________________________________________"),
        ]),
      ],
    );
  }

  static pw.Widget _buildInstructions(Prueba prueba) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Text("Instrucciones: ${prueba.introduccion}"),
    );
  }

  static pw.Widget _buildQuestionItem(Pregunta p, int index) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$index. ${p.texto} (${p.valor} ptos)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          _buildOptions(p),
        ],
      ),
    );
  }

  static pw.Widget _buildOptions(Pregunta p) {
    if (p.tipo == TipoPregunta.seleccionSimple || p.tipo == TipoPregunta.seleccionMultiple) {
      Map<String, dynamic> opts = jsonDecode(p.opciones);
      return pw.Column(
        children: opts.entries.map((e) {
          return pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(width: 0.5)),
              ),
              pw.SizedBox(width: 15), // Aumentado espacio para evitar que OCR una 'O' con la letra (OA, OB)
              pw.Text("${e.key}) ${e.value}"),
            ],
          );
        }).toList(),
      );
    } else if (p.tipo == TipoPregunta.verdaderoFalso) {
       return pw.Row(
         children: [
           pw.Text("V [ ]   F [ ]"),
         ]
       );
    } else if (p.tipo == TipoPregunta.completar) {
      return pw.Text("Respuesta: _________________________");
    }
    return pw.Container();
  }
}
