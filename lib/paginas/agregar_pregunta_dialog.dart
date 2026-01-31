import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../logica/providers/app_provider.dart';
import '../logica/models/app_models.dart';
import '../whitgest/ux/widgets.dart';

class AgregarPreguntaDialog extends StatefulWidget {
  final int pruebaId;

  const AgregarPreguntaDialog({super.key, required this.pruebaId});

  @override
  State<AgregarPreguntaDialog> createState() => _AgregarPreguntaDialogState();
}

class _AgregarPreguntaDialogState extends State<AgregarPreguntaDialog> {
  late TipoPregunta tipoSeleccionado;
  final TextEditingController _textoPreguntaController = TextEditingController();
  final TextEditingController _valorController = TextEditingController(text: '1.0');
  final List<TextEditingController> _opcionesControllers = [];
  int? _respuestaCorrectaIndex;
  List<int>? _respuestasCorrectasMultiples = [];

  @override
  void initState() {
    super.initState();
    tipoSeleccionado = TipoPregunta.seleccionSimple;
    _inicializarOpciones();
  }

  void _inicializarOpciones() {
    _opcionesControllers.clear();
    if (tipoSeleccionado == TipoPregunta.seleccionSimple ||
        tipoSeleccionado == TipoPregunta.seleccionMultiple) {
      for (int i = 0; i < 4; i++) {
        _opcionesControllers.add(TextEditingController());
      }
    } else if (tipoSeleccionado == TipoPregunta.verdaderoFalso) {
      _opcionesControllers.add(TextEditingController(text: 'Verdadero'));
      _opcionesControllers.add(TextEditingController(text: 'Falso'));
    }
  }

  @override
  void dispose() {
    _textoPreguntaController.dispose();
    _valorController.dispose();
    for (var controller in _opcionesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _cambiarTipo(TipoPregunta nuevoTipo) {
    setState(() {
      tipoSeleccionado = nuevoTipo;
      _respuestaCorrectaIndex = null;
      _respuestasCorrectasMultiples = [];
      _inicializarOpciones();
    });
  }

  void _guardarPregunta() {
    if (_textoPreguntaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el texto de la pregunta')),
      );
      return;
    }

    String respuestaCorrecta = '';
    List<String> opciones = [];

    if (tipoSeleccionado == TipoPregunta.seleccionSimple) {
      if (_respuestaCorrectaIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la respuesta correcta')),
        );
        return;
      }
      opciones = _opcionesControllers.map((c) => c.text).toList();
      respuestaCorrecta = opciones[_respuestaCorrectaIndex!];
    } else if (tipoSeleccionado == TipoPregunta.seleccionMultiple) {
      if (_respuestasCorrectasMultiples!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona al menos una respuesta correcta')),
        );
        return;
      }
      opciones = _opcionesControllers.map((c) => c.text).toList();
      respuestaCorrecta =
          jsonEncode(_respuestasCorrectasMultiples!.map((i) => opciones[i]).toList());
    } else if (tipoSeleccionado == TipoPregunta.verdaderoFalso) {
      if (_respuestaCorrectaIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la respuesta correcta')),
        );
        return;
      }
      opciones = ['Verdadero', 'Falso'];
      respuestaCorrecta = opciones[_respuestaCorrectaIndex!];
    } else if (tipoSeleccionado == TipoPregunta.completar) {
      if (_opcionesControllers.isEmpty || _opcionesControllers[0].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa la respuesta')),
        );
        return;
      }
      respuestaCorrecta = _opcionesControllers[0].text;
      opciones = [respuestaCorrecta];
    }

    final pregunta = Pregunta(
      pruebaId: widget.pruebaId,
      texto: _textoPreguntaController.text,
      tipo: tipoSeleccionado,
      opciones: jsonEncode(opciones),
      respuestaCorrecta: respuestaCorrecta,
      valor: double.tryParse(_valorController.text) ?? 1.0,
    );

    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.addPregunta(pregunta);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pregunta añadida exitosamente')),
    );
    Navigator.pop(context);
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
                    const Text(
                      "Nueva Pregunta",
                      style: TextStyle(
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
            // Contenido
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de tipo
                      const Text(
                        "Tipo de Pregunta",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _tipoBoton("Selección", TipoPregunta.seleccionSimple),
                            const SizedBox(width: 8),
                            _tipoBoton("Múltiple", TipoPregunta.seleccionMultiple),
                            const SizedBox(width: 8),
                            _tipoBoton("V/F", TipoPregunta.verdaderoFalso),
                            const SizedBox(width: 8),
                            _tipoBoton("Completar", TipoPregunta.completar),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Texto de la pregunta
                      const Text(
                        "Pregunta",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textoPreguntaController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Ingresa el texto de la pregunta",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Opciones según tipo
                      if (tipoSeleccionado == TipoPregunta.seleccionSimple ||
                          tipoSeleccionado == TipoPregunta.seleccionMultiple)
                        _buildOpcionesMultiples(),

                      if (tipoSeleccionado == TipoPregunta.verdaderoFalso)
                        _buildVerdaderoFalso(),

                      if (tipoSeleccionado == TipoPregunta.completar)
                        _buildCompletar(),

                      const SizedBox(height: 24),

                      // Valor de la pregunta
                      const Text(
                        "Valor (puntos)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _valorController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "1.0",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: kPrimaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancelar",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: kPrimaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _guardarPregunta,
                                child: const Text(
                                  "Guardar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoBoton(String label, TipoPregunta tipo) {
    final isSelected = tipoSeleccionado == tipo;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? kPrimaryColor : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () => _cambiarTipo(tipo),
      child: Text(label),
    );
  }

  Widget _buildOpcionesMultiples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Opciones",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            final letra = String.fromCharCode(65 + index); // A, B, C, D
            final isCorrect = tipoSeleccionado == TipoPregunta.seleccionSimple
                ? _respuestaCorrectaIndex == index
                : _respuestasCorrectasMultiples!.contains(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (tipoSeleccionado == TipoPregunta.seleccionSimple) {
                          _respuestaCorrectaIndex = isCorrect ? null : index;
                        } else {
                          if (isCorrect) {
                            _respuestasCorrectasMultiples!.remove(index);
                          } else {
                            _respuestasCorrectasMultiples!.add(index);
                          }
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect ? kPrimaryColor : Colors.grey.shade200,
                        border: Border.all(
                          color: kPrimaryColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letra,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.white : kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _opcionesControllers[index],
                      decoration: InputDecoration(
                        hintText: "Opción $letra",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isCorrect ? kPrimaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerdaderoFalso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Respuesta Correcta",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _respuestaCorrectaIndex = 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _respuestaCorrectaIndex == 0
                        ? kPrimaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kPrimaryColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "Verdadero",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _respuestaCorrectaIndex == 0
                          ? Colors.white
                          : kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _respuestaCorrectaIndex = 1),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _respuestaCorrectaIndex == 1
                        ? kPrimaryColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kPrimaryColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    "Falso",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _respuestaCorrectaIndex == 1
                          ? Colors.white
                          : kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Respuesta Correcta",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _opcionesControllers.isEmpty
              ? TextEditingController()
              : _opcionesControllers[0],
          decoration: InputDecoration(
            hintText: "Ingresa la respuesta correcta",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: kPrimaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
