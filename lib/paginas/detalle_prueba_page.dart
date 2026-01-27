
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart'; // For sharing/previewing PDF
import 'package:open_file/open_file.dart'; // To open excel

// Imports for our logic
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../logica/services/aiken_parser.dart';
import '../logica/services/pdf_service.dart';
import '../logica/services/excel_service.dart';
import '../whitgest/ux/widgets.dart';
import 'scanner_page.dart';
import 'batch_pdf_scanner_page.dart';

class DetallePruebaPage extends StatefulWidget {
  final Prueba prueba;
  final Materia materia;

  const DetallePruebaPage({super.key, required this.prueba, required this.materia});

  @override
  State<DetallePruebaPage> createState() => _DetallePruebaPageState();
}

class _DetallePruebaPageState extends State<DetallePruebaPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final prov = Provider.of<AppProvider>(context, listen: false);
    prov.loadPreguntas(widget.prueba.id!);
    prov.loadResultados(widget.prueba.id!);
    prov.loadEstudiantes(); // Ensure we have students for mapping names
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prueba.nombre),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Preguntas"),
            Tab(text: "Resultados"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionsTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  // --- Questions Tab ---
  Widget _buildQuestionsTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   ElevatedButton.icon(
                     icon: const Icon(Icons.upload_file),
                     label: const Text("Importar Aiken"),
                     onPressed: _importAiken,
                   ),
                   ElevatedButton.icon(
                     icon: const Icon(Icons.picture_as_pdf),
                     label: const Text("PDF"),
                     onPressed: () => _generatePdf(provider.preguntas),
                   ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.preguntas.length,
                itemBuilder: (context, index) {
                  final p = provider.preguntas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(child: Text("${index + 1}")),
                      title: Text(p.texto),
                      subtitle: Text("Resp: ${p.respuestaCorrecta}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                         onPressed: () {
                           provider.deletePregunta(p.id!, widget.prueba.id!);
                         },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Results Tab ---
  Widget _buildResultsTab() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                   ElevatedButton.icon(
                     icon: const Icon(Icons.camera_alt),
                     label: const Text("Escanear"),
                     style: ElevatedButton.styleFrom(backgroundColor: kSecondaryColor),
                     onPressed: () {
                        if (provider.preguntas.isEmpty) {
                          showSnackBar(context, "Primero añade preguntas.", isError: true);
                          return;
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerPage(prueba: widget.prueba)));
                     },
                   ),
                   ElevatedButton.icon(
                     icon: const Icon(Icons.picture_as_pdf),
                     label: const Text("PDFs Lote"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                     onPressed: () {
                        if (provider.preguntas.isEmpty) {
                          showSnackBar(context, "Primero añade preguntas.", isError: true);
                          return;
                        }
                        Navigator.push(context, MaterialPageRoute(builder: (_) => BatchPdfScannerPage(prueba: widget.prueba)));
                     },
                   ),
                   ElevatedButton.icon(
                     icon: const Icon(Icons.table_view),
                     label: const Text("Excel"),
                     onPressed: () => _exportExcel(provider),
                   ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.resultados.length,
                itemBuilder: (context, index) {
                  final r = provider.resultados[index];
                  final est = provider.estudiantes.firstWhere(
                    (e) => e.id == r.estudianteId,
                    orElse: () => Estudiante(nombre: "Desconocido", identificacion: "-"),
                  );
                  return Card(
                    color: r.calificacion >= (provider.preguntas.length / 2) ? Colors.green.shade50 : Colors.red.shade50,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text(est.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(r.fechaRealizacion.toString()),
                      trailing: Text("${r.calificacion.toStringAsFixed(1)} pts", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Actions ---
  Future<void> _importAiken() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
       type: FileType.custom, allowedExtensions: ['txt']
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
      String path = await PdfService.generateExamPdf(widget.prueba, widget.materia, preguntas);
      await Printing.sharePdf(bytes: File(path).readAsBytesSync(), filename: 'Examen.pdf');
    } catch (e) {
      showSnackBar(context, "Error generando PDF: $e", isError: true);
    }
  }

  Future<void> _exportExcel(AppProvider provider) async {
    if (provider.resultados.isEmpty) {
      showSnackBar(context, "No hay resultados para exportar.", isError: true);
      return;
    }
    try {
      String path = await ExcelService.exportResultados(widget.prueba, widget.materia, provider.estudiantes, provider.resultados);
      showSnackBar(context, "Exportado a: $path");
      
      // Try to open
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        showSnackBar(context, "No se pudo abrir el archivo: ${result.message}", isError: true);
      }
    } catch (e) {
      showSnackBar(context, "Error exportando: $e", isError: true);
    }
  }
}
