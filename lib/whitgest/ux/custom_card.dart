import 'package:flutter/material.dart';

/// Tarjeta personalizada con sombra y bordes redondeados
/// 
/// Widget base para mostrar contenido en tarjetas consistentes
/// 
/// Ejemplo de uso:
/// ```dart
/// CustomCard(
///   child: Text('Contenido'),
///   onTap: () => print('Tarjeta presionada'),
/// )
/// ```
class CustomCard extends StatelessWidget {
  /// Contenido de la tarjeta
  final Widget child;
  
  /// Función que se ejecuta al tocar la tarjeta
  final VoidCallback? onTap;
  
  /// Color de fondo de la tarjeta
  final Color? backgroundColor;
  
  /// Elevación de la sombra
  final double elevation;
  
  /// Margen externo
  final EdgeInsetsGeometry? margin;
  
  /// Padding interno
  final EdgeInsetsGeometry? padding;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.elevation = 2,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Tarjeta para mostrar información de estudiante
class StudentCard extends StatelessWidget {
  final String name;
  final String studentId;
  final String? email;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StudentCard({
    super.key,
    required this.name,
    required this.studentId,
    this.email,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar circular
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Información del estudiante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $studentId',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Botones de acción
          if (onEdit != null || onDelete != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                    color: Colors.blue,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    color: Colors.red,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Tarjeta para mostrar información de materia
class SubjectCard extends StatelessWidget {
  final String name;
  final String code;
  final String? teacherName;
  final int? questionCount;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubjectCard({
    super.key,
    required this.name,
    required this.code,
    this.teacherName,
    this.questionCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono de materia
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.book,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Información de la materia
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Código: $code',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botones de acción
              if (onEdit != null || onDelete != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        color: Colors.blue,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: onDelete,
                        color: Colors.red,
                      ),
                  ],
                ),
            ],
          ),
          
          // Información adicional
          if (teacherName != null || questionCount != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (teacherName != null) ...[
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    teacherName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (teacherName != null && questionCount != null)
                  const SizedBox(width: 16),
                if (questionCount != null) ...[
                  Icon(Icons.quiz, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$questionCount preguntas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta para mostrar resultado de prueba
class ResultCard extends StatelessWidget {
  final String studentName;
  final String testName;
  final double score;
  final double maxScore;
  final DateTime date;
  final VoidCallback? onTap;

  const ResultCard({
    super.key,
    required this.studentName,
    required this.testName,
    required this.score,
    required this.maxScore,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / maxScore * 100).toStringAsFixed(1);
    final isPassing = (score / maxScore) >= 0.6; // 60% para aprobar
    
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          // Indicador de calificación
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isPassing ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Información del resultado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  testName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          
          // Icono de flecha
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
