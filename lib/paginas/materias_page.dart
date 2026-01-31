
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../whitgest/ux/widgets.dart';
import '../whitgest/ux/materia_card.dart';
import 'pruebas_page.dart';

class MateriasPage extends StatelessWidget {
  const MateriasPage({super.key});

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
                    const Text(
                      "Materias",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 48), // Espacio para balancear el back button
                  ],
                ),
              ),
            ),
            
            // Grid de materias
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.materias.isEmpty) {
                    return const Center(
                      child: Text("No hay materias creadas."),
                    );
                  }
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.materias.length,
                    itemBuilder: (context, index) {
                      final materia = provider.materias[index];
                      final gradients = [
                        [Colors.blue.shade300, Colors.cyan.shade300],
                        [Colors.purple.shade300, Colors.indigo.shade300],
                        [Colors.green.shade300, Colors.teal.shade300],
                        [Colors.orange.shade300, Colors.pink.shade300],
                      ];
                      final gradient = gradients[index % gradients.length] as List<Color>;
                      
                      return MateriaCard(
                        nombre: materia.nombre,
                        descripcion: materia.descripcion,
                        gradient: gradient,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PruebasPage(materia: materia),
                            ),
                          );
                        },
                        onEdit: () => _showEditDialog(context, provider, materia),
                        onDelete: () => _confirmDelete(context, provider, materia.id!),
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

  void _showEditDialog(BuildContext context, AppProvider provider, Materia materia) {
    final nameCtrl = TextEditingController(text: materia.nombre);
    final descCtrl = TextEditingController(text: materia.descripcion);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar Materia"),
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
                final updatedMateria = Materia(
                  id: materia.id,
                  nombre: nameCtrl.text,
                  descripcion: descCtrl.text,
                );
                provider.updateMateria(updatedMateria);
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
