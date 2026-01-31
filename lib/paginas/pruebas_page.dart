
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../whitgest/ux/widgets.dart';
import '../whitgest/ux/prueba_card.dart';
import 'detalle_prueba_page.dart';

class PruebasPage extends StatefulWidget {
  final Materia materia;
  const PruebasPage({super.key, required this.materia});

  @override
  State<PruebasPage> createState() => _PruebasPageState();
}

class _PruebasPageState extends State<PruebasPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<AppProvider>(context, listen: false).loadPruebas(widget.materia.id!)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
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
                      "Pruebas de ${widget.materia.nombre}",
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
            
            const SizedBox(height: 16),
            
            // Lista de pruebas
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.pruebas.isEmpty) {
                    return const Center(
                      child: Text("No hay pruebas creadas."),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.pruebas.length,
                    itemBuilder: (context, index) {
                      final prueba = provider.pruebas[index];
                      final fecha = prueba.fechaCreacion.toString().split(' ')[0];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PruebaCard(
                          nombre: prueba.nombre,
                          docente: prueba.nombreDocente,
                          fecha: fecha,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetallePruebaPage(
                                  prueba: prueba,
                                  materia: widget.materia,
                                ),
                              ),
                            );
                          },
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

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final introCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Prueba"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomInput(label: "Nombre Prueba", controller: nameCtrl),
              const SizedBox(height: 10),
              CustomInput(label: "Nombre Docente", controller: teacherCtrl),
              const SizedBox(height: 10),
              CustomInput(label: "Introducción/Instrucciones", controller: introCtrl, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && teacherCtrl.text.isNotEmpty) {
                final prueba = Prueba(
                  materiaId: widget.materia.id!, 
                  nombre: nameCtrl.text, 
                  nombreDocente: teacherCtrl.text, 
                  introduccion: introCtrl.text, 
                  fechaCreacion: DateTime.now()
                );
                Provider.of<AppProvider>(context, listen: false).addPrueba(prueba);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
