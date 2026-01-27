
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logica/providers/app_provider.dart';
import '../whitgest/ux/widgets.dart';
import 'materias_page.dart';
import 'installation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() => 
      Provider.of<AppProvider>(context, listen: false).loadMaterias()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evaluador Inteligente")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Bienvenido", style: kTitleStyle),
              const SizedBox(height: 5),
              const Text("Selecciona una opción para empezar."),
              const SizedBox(height: 20),
              
              CustomCard(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const MateriasPage()));
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.class_, color: Colors.blue, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Gestionar Materias", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Crea materias, pruebas y estudiantes."),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),

              CustomCard(
                onTap: () {
                    // Navigate to Help/Manual
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallationPage()));
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.help, color: Colors.green, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Manual de Instalación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Requerimientos y configuración."),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
