import 'package:flutter/material.dart';

/// Card cuadrada para mostrar una materia
/// 
/// Ejemplo:
/// ```dart
/// MateriaCard(
///   nombre: "Matemáticas",
///   descripcion: "Cálculo y álgebra",
///   gradient: [Colors.blue.shade300, Colors.cyan.shade300],
///   onTap: () => Navigator.push(...),
///   onDelete: () => showDialog(...),
/// )
/// ```
class MateriaCard extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final List<Color> gradient;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MateriaCard({
    super.key,
    required this.nombre,
    required this.descripcion,
    required this.gradient,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Contenido principal
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono con gradiente
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre de la materia
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Descripción
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        descripcion,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF95A5A6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Botones en la esquina superior derecha
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    // Botón editar
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
                        onPressed: onEdit,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    // Botón eliminar
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 24),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
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
