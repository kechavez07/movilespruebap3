
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';

import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../logica/services/aiken_parser.dart';
import '../logica/services/pdf_service.dart';
import '../logica/services/excel_service.dart';
import '../whitgest/ux/widgets.dart';
import 'scanner_page.dart';
import 'batch_pdf_scanner_page.dart';
import 'preguntas_page.dart';
import 'resultados_page.dart';
import 'agregar_pregunta_dialog.dart';

class DetallePruebaPage extends StatefulWidget {
  final Prueba prueba;
  final Materia materia;

  const DetallePruebaPage({super.key, required this.prueba, required this.materia});

  @override
  State<DetallePruebaPage> createState() => _DetallePruebaPageState();
}

class _DetallePruebaPageState extends State<DetallePruebaPage> {
  int _selectedTab = 0; // 0: Preguntas, 1: Resultados

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final prov = Provider.of<AppProvider>(context, listen: false);
    prov.loadPreguntas(widget.prueba.id!);
    prov.loadResultados(widget.prueba.id!);
    prov.loadEstudiantes();
  }

  Future<void> _importAiken() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'aiken'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        List<Pregunta> preguntas = AikenParser.parse(content, widget.prueba.id!);
        
        final provider = Provider.of<AppProvider>(context, listen: false);
        for (var pregunta in preguntas) {
          await provider.addPregunta(pregunta);
        }
        
        if (mounted) {
          showSnackBar(
            context,
            "Se importaron ${preguntas.length} preguntas correctamente.",
          );
          provider.loadPreguntas(widget.prueba.id!);
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, "Error al importar: $e", isError: true);
      }
    }
  }

  Future<void> _generatePdf() async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      if (provider.preguntas.isEmpty) {
        showSnackBar(context, "No hay preguntas para generar PDF.", isError: true);
        return;
      }

      final pdfPath = await PdfService.generateExamPdf(
        widget.prueba,
        widget.materia,
        provider.preguntas,
      );

      await OpenFile.open(pdfPath);
      
      if (mounted) {
        showSnackBar(context, "PDF generado correctamente.");
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, "Error al generar PDF: $e", isError: true);
      }
    }
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
                      widget.prueba.nombre,
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
            
            const SizedBox(height: 4),
            
            // Botones superiores sin iconos - fondo blanco
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _selectedTab = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedTab == 0 ? kPrimaryColor : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        "Preguntas",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _selectedTab = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedTab == 1 ? kPrimaryColor : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        "Resultados",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Contenido blanco
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _selectedTab == 0
                    ? _buildPreguntasContent()
                    : _buildResultadosContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreguntasContent() {
    return Column(
      children: [
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
                      color: Colors.grey.shade50,
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
                            provider.deletePregunta(p.id!, widget.prueba.id!);
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
        
        // Botones flotantes en la parte inferior
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add, color: kPrimaryColor, size: 20),
                        label: const Text(
                          "Nueva",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AgregarPreguntaDialog(
                                pruebaId: widget.prueba.id!,
                              ),
                            ),
                          ).then((_) {
                            Provider.of<AppProvider>(context, listen: false)
                                .loadPreguntas(widget.prueba.id!);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.upload_file, color: kPrimaryColor, size: 20),
                        label: const Text(
                          "Aiken",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        onPressed: () async {
                          await _importAiken();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.picture_as_pdf, color: kPrimaryColor, size: 20),
                        label: const Text(
                          "Genera",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                        onPressed: () async {
                          await _generatePdf();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultadosContent() {
    return Column(
      children: [
        // Lista de resultados
        Expanded(
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              if (provider.resultados.isEmpty) {
                return const Center(
                  child: Text("No hay resultados aún."),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.resultados.length,
                itemBuilder: (context, index) {
                  final r = provider.resultados[index];
                  final est = provider.estudiantes.firstWhere(
                    (e) => e.id == r.estudianteId,
                    orElse: () => Estudiante(
                        nombre: "Desconocido", identificacion: "-"),
                  );

                  final isPass =
                      r.calificacion >= (provider.preguntas.length / 2);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPass
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                        width: 1,
                      ),
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
                          backgroundColor:
                              isPass ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          child: Icon(isPass ? Icons.check : Icons.close),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                est.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                r.fechaRealizacion.toString().split(' ')[0],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF95A5A6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPass
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${r.calificacion.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPass
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // Botones flotantes en la parte inferior
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    icon: const Icon(Icons.camera_alt, color: kPrimaryColor),
                    label: const Text(
                      "Escanear",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    onPressed: () {
                      final provider =
                          Provider.of<AppProvider>(context, listen: false);
                      if (provider.preguntas.isEmpty) {
                        showSnackBar(context, "Primero añade preguntas.",
                            isError: true);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScannerPage(prueba: widget.prueba),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    icon: const Icon(Icons.table_view, color: kPrimaryColor),
                    label: const Text(
                      "Excel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
