class JobMatch {
  final String name;
  final String imageUrl;
  final String subtitle;
  final String? bio;
  final String? salary;
  final List<String> skills;
  String lastMessage;
  String time;
  int unreadCount;
  bool hasNewMatch;

  // Datos de contacto — visibles solo tras match
  final String? phone;
  final String? linkedin;
  final String? website;
  bool procesoCerrado;
  bool rated;

  JobMatch({
    required this.name,
    required this.imageUrl,
    required this.subtitle,
    this.bio,
    this.salary,
    this.skills = const [],
    this.lastMessage = "¡Hola! Me gustaría conectar contigo...",
    this.time = "Ahora",
    this.unreadCount = 0,
    this.hasNewMatch = true,
    this.phone,
    this.linkedin,
    this.website,
    this.procesoCerrado = false,
    this.rated = false,
  });
}