import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../logica/services/excel_service.dart';
import '../whitgest/ux/widgets.dart';
import 'scanner_page.dart';
import 'batch_pdf_scanner_page.dart';
import 'package:open_file/open_file.dart';

class ResultadosPage extends StatefulWidget {
  final Prueba prueba;
  final Materia materia;

  const ResultadosPage({
    super.key,
    required this.prueba,
    required this.materia,
  });

  @override
  State<ResultadosPage> createState() => _ResultadosPageState();
}

class _ResultadosPageState extends State<ResultadosPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final prov = Provider.of<AppProvider>(context, listen: false);
      prov.loadResultados(widget.prueba.id!);
      prov.loadEstudiantes();
      prov.loadPreguntas(widget.prueba.id!);
    });
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
                      "Resultados",
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
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Escanear"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryColor,
                      foregroundColor: Colors.white,
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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDFs Lote"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
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
                          builder: (_) =>
                              BatchPdfScannerPage(prueba: widget.prueba),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.table_view),
                    label: const Text("Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _exportExcel(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                              backgroundColor: isPass ? Colors.green : Colors.red,
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
                                    r.fechaRealizacion
                                        .toString()
                                        .split(' ')[0],
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
          ],
        ),
      ),
    );
  }

  Future<void> _exportExcel() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.resultados.isEmpty) {
      showSnackBar(context, "No hay resultados para exportar.", isError: true);
      return;
    }
    try {
      String path = await ExcelService.exportResultados(
        widget.prueba,
        widget.materia,
        provider.estudiantes,
        provider.resultados,
      );
      showSnackBar(context, "Exportado a: $path");

      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        showSnackBar(context, "No se pudo abrir el archivo: ${result.message}",
            isError: true);
      }
    } catch (e) {
      showSnackBar(context, "Error exportando: $e", isError: true);
    }
  }
}
