import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../logica/services/aiken_parser.dart';
import '../logica/services/pdf_service.dart';
import '../whitgest/ux/widgets.dart';

class PreguntasPage extends StatefulWidget {
  final Prueba prueba;
  final Materia materia;

  const PreguntasPage({
    super.key,
    required this.prueba,
    required this.materia,
  });

  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AppProvider>(context, listen: false)
            .loadPreguntas(widget.prueba.id!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Preguntas",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            
            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Importar Aiken"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _importAiken(),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final provider =
                          Provider.of<AppProvider>(context, listen: false);
                      _generatePdf(provider.preguntas);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de preguntas
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.preguntas.isEmpty) {
                    return const Center(
                      child: Text("No hay preguntas. Importa un archivo Aiken."),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.preguntas.length,
                    itemBuilder: (context, index) {
                      final p = provider.preguntas[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              child: Text("${index + 1}"),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.texto,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Resp: ${p.respuestaCorrecta}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                provider.deletePregunta(
                                    p.id!, widget.prueba.id!);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importAiken() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();

      List<Pregunta> imported = AikenParser.parse(content, widget.prueba.id!);

      if (mounted) {
        final prov = Provider.of<AppProvider>(context, listen: false);
        for (var p in imported) {
          await prov.addPregunta(p);
        }
        showSnackBar(context, "${imported.length} preguntas importadas.");
      }
    }
  }

  Future<void> _generatePdf(List<Pregunta> preguntas) async {
    if (preguntas.isEmpty) {
      showSnackBar(context, "No hay preguntas para generar PDF.", isError: true);
      return;
    }
    try {
      String path = await PdfService.generateExamPdf(
          widget.prueba, widget.materia, preguntas);
      await Printing.sharePdf(
          bytes: File(path).readAsBytesSync(), filename: 'Examen.pdf');
    } catch (e) {
      showSnackBar(context, "Error generando PDF: $e", isError: true);
    }
  }
}
