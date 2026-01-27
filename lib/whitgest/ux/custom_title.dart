import 'package:flutter/material.dart';

/// Título de página personalizado
/// 
/// Widget para mostrar títulos consistentes en toda la aplicación
/// 
/// Ejemplo de uso:
/// ```dart
/// PageTitle(text: 'Estudiantes')
/// ```
class PageTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;

  const PageTitle({
    super.key,
    required this.text,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 32,
            color: color ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Título de sección
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.text,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 22,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Subtítulo o texto descriptivo
class SubtitleText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final Color? color;

  const SubtitleText({
    super.key,
    required this.text,
    this.textAlign,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 16,
        color: color ?? Colors.grey.shade600,
        height: 1.5,
      ),
    );
  }
}

/// Encabezado de lista con contador
class ListHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback? onAdd;

  const ListHeader({
    super.key,
    required this.title,
    required this.count,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: onAdd,
              color: Theme.of(context).primaryColor,
              iconSize: 28,
            ),
        ],
      ),
    );
  }
}

/// Badge o etiqueta informativa
class InfoBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const InfoBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: textColor ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
