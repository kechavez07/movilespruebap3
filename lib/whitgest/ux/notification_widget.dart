import 'package:flutter/material.dart';

/// Muestra un SnackBar con mensaje de éxito, error o información
/// 
/// Ejemplo de uso:
/// ```dart
/// showNotification(
///   context,
///   'Estudiante guardado correctamente',
///   type: NotificationType.success,
/// );
/// ```
enum NotificationType {
  success,
  error,
  warning,
  info,
}

void showNotification(
  BuildContext context,
  String message, {
  NotificationType type = NotificationType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  Color backgroundColor;
  IconData icon;

  switch (type) {
    case NotificationType.success:
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
      break;
    case NotificationType.error:
      backgroundColor = Colors.red;
      icon = Icons.error;
      break;
    case NotificationType.warning:
      backgroundColor = Colors.orange;
      icon = Icons.warning;
      break;
    case NotificationType.info:
      backgroundColor = Colors.blue;
      icon = Icons.info;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

/// Banner de notificación persistente en la parte superior
class NotificationBanner extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onDismiss;

  const NotificationBanner({
    super.key,
    required this.message,
    this.type = NotificationType.info,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case NotificationType.success:
        backgroundColor = Colors.green.shade100;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red.shade100;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = Colors.orange.shade100;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue.shade100;
        icon = Icons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              color: Colors.black54,
            ),
        ],
      ),
    );
  }
}

/// Toast personalizado (alternativa ligera al SnackBar)
class ToastNotification {
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _ToastWidget(message: message, type: type),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remover después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final NotificationType type;

  const _ToastWidget({
    required this.message,
    required this.type,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    switch (widget.type) {
      case NotificationType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
