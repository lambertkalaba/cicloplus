/// Representa a la persona que inició sesión en CicloPlus.
///
/// Por ahora esto se guarda localmente (fase "sin Firebase todavía"). Cuando
/// conectemos Firebase Authentication, el campo `id` pasará a ser el UID
/// real de Firebase y `createdAt` vendrá del servidor — el resto de la app
/// (pantallas, lógica de prueba gratis) no necesita cambiar porque ya
/// trabaja contra este mismo modelo.
class AppUser {
  final String id;
  final String email;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
