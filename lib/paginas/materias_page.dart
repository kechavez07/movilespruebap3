
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../whitgest/ux/widgets.dart';
import 'pruebas_page.dart';

class MateriasPage extends StatelessWidget {
  const MateriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Materias")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.materias.isEmpty) {
            return const Center(child: Text("No hay materias creadas."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.materias.length,
            itemBuilder: (context, index) {
              final materia = provider.materias[index];
              return CustomCard(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PruebasPage(materia: materia)));
                },
                child: ListTile(
                  title: Text(materia.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(materia.descripcion),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, provider, materia.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nueva Materia"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomInput(label: "Nombre", controller: nameCtrl),
            const SizedBox(height: 10),
            CustomInput(label: "Descripción", controller: descCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                final materia = Materia(nombre: nameCtrl.text, descripcion: descCtrl.text);
                Provider.of<AppProvider>(context, listen: false).addMateria(materia);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text("¿Estás seguro? Se borrarán las pruebas asociadas."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
             onPressed: () {
               provider.deleteMateria(id);
               Navigator.pop(ctx);
             }, 
             child: const Text("Eliminar", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
