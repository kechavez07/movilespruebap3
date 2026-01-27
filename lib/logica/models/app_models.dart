
class Materia {
  final int? id;
  final String nombre;
  final String descripcion;

  Materia({this.id, required this.nombre, required this.descripcion});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
    );
  }
}

class Estudiante {
  final int? id;
  final String nombre;
  final String identificacion; // Cedula o ID

  Estudiante({this.id, required this.nombre, required this.identificacion});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'identificacion': identificacion,
    };
  }

  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      id: map['id'],
      nombre: map['nombre'],
      identificacion: map['identificacion'],
    );
  }
}

class Prueba {
  final int? id;
  final int materiaId;
  final String nombre;
  final String nombreDocente;
  final String introduccion; // Instrucciones
  final DateTime fechaCreacion;

  Prueba({
    this.id,
    required this.materiaId,
    required this.nombre,
    required this.nombreDocente,
    required this.introduccion,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materiaId': materiaId,
      'nombre': nombre,
      'nombreDocente': nombreDocente,
      'introduccion': introduccion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Prueba.fromMap(Map<String, dynamic> map) {
    return Prueba(
      id: map['id'],
      materiaId: map['materiaId'],
      nombre: map['nombre'],
      nombreDocente: map['nombreDocente'],
      introduccion: map['introduccion'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
    );
  }
}

enum TipoPregunta {
  seleccionMultiple,
  verdaderoFalso,
  completar,
  seleccionSimple,
}

class Pregunta {
  final int? id;
  final int pruebaId;
  final String texto;
  final TipoPregunta tipo;
  final String opciones; // JSON string para opciones
  final String respuestaCorrecta;
  final double valor;

  Pregunta({
    this.id,
    required this.pruebaId,
    required this.texto,
    required this.tipo,
    required this.opciones,
    required this.respuestaCorrecta,
    this.valor = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pruebaId': pruebaId,
      'texto': texto,
      'tipo': tipo.index,
      'opciones': opciones,
      'respuestaCorrecta': respuestaCorrecta,
      'valor': valor,
    };
  }

  factory Pregunta.fromMap(Map<String, dynamic> map) {
    return Pregunta(
      id: map['id'],
      pruebaId: map['pruebaId'],
      texto: map['texto'],
      tipo: TipoPregunta.values[map['tipo']],
      opciones: map['opciones'],
      respuestaCorrecta: map['respuestaCorrecta'],
      valor: map['valor'],
    );
  }
}

class Resultado {
  final int? id;
  final int pruebaId;
  final int estudianteId;
  final double calificacion;
  final DateTime fechaRealizacion;
  
  Resultado({
    this.id,
    required this.pruebaId,
    required this.estudianteId,
    required this.calificacion,
    required this.fechaRealizacion,
  });

   Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pruebaId': pruebaId,
      'estudianteId': estudianteId,
      'calificacion': calificacion,
      'fechaRealizacion': fechaRealizacion.toIso8601String(),
    };
  }

  factory Resultado.fromMap(Map<String, dynamic> map) {
    return Resultado(
      id: map['id'],
      pruebaId: map['pruebaId'],
      estudianteId: map['estudianteId'],
      calificacion: map['calificacion'],
      fechaRealizacion: DateTime.parse(map['fechaRealizacion']),
    );
  }
}
