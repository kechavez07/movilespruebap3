
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../whitgest/ux/widgets.dart';
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
      appBar: AppBar(title: Text(widget.materia.nombre)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Text("Pruebas de ${widget.materia.nombre}", style: const TextStyle(fontSize: 18, color: Colors.grey)),
           ),
           Expanded(
             child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.pruebas.isEmpty) {
                    return const Center(child: Text("No hay pruebas creadas."));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.pruebas.length,
                    itemBuilder: (context, index) {
                      final prueba = provider.pruebas[index];
                      return CustomCard(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => DetallePruebaPage(prueba: prueba, materia: widget.materia)));
                        },
                        child: ListTile(
                          leading: const Icon(Icons.description, color: kPrimaryColor),
                          title: Text(prueba.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Prof: ${prueba.nombreDocente} - ${prueba.fechaCreacion.toString().split(' ')[0]}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  );
                },
              ),
           ),
        ],
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
