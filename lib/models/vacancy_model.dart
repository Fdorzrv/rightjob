class VacancyStats {
  final int views;
  final int swipes;
  final int matches;
  final int inProcess;
  final int hired;

  const VacancyStats({
    this.views = 0,
    this.swipes = 0,
    this.matches = 0,
    this.inProcess = 0,
    this.hired = 0,
  });

  factory VacancyStats.fromMap(Map<String, dynamic> m) => VacancyStats(
    views: (m['views'] as num?)?.toInt() ?? 0,
    swipes: (m['swipes'] as num?)?.toInt() ?? 0,
    matches: (m['matches'] as num?)?.toInt() ?? 0,
    inProcess: (m['inProcess'] as num?)?.toInt() ?? 0,
    hired: (m['hired'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'views': views, 'swipes': swipes, 'matches': matches,
    'inProcess': inProcess, 'hired': hired,
  };
}

class Vacancy {
  final String id;
  final String companyUid;
  final String companyName;
  final String title;
  final String sector;
  final String salary;
  final String city;
  final String description;
  final String availability; // Remoto / Presencial / Híbrido
  final List<String> skills;
  final String status; // active | closed
  final VacancyStats stats;
  final DateTime createdAt;

  Vacancy({
    required this.id,
    required this.companyUid,
    required this.companyName,
    required this.title,
    required this.sector,
    required this.salary,
    required this.city,
    required this.description,
    this.availability = 'Remoto',
    this.skills = const [],
    this.status = 'active',
    VacancyStats? stats,
    DateTime? createdAt,
  })  : stats = stats ?? const VacancyStats(),
        createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == 'active';

  factory Vacancy.fromMap(String id, Map<String, dynamic> m) => Vacancy(
    id: id,
    companyUid: m['companyUid'] ?? '',
    companyName: m['companyName'] ?? '',
    title: m['title'] ?? '',
    sector: m['sector'] ?? '',
    salary: m['salary'] ?? '',
    city: m['city'] ?? '',
    description: m['description'] ?? '',
    availability: m['availability'] ?? 'Remoto',
    skills: List<String>.from(m['skills'] ?? []),
    status: m['status'] ?? 'active',
    stats: VacancyStats.fromMap(Map<String, dynamic>.from(m['stats'] ?? {})),
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'companyUid': companyUid,
    'companyName': companyName,
    'title': title,
    'sector': sector,
    'salary': salary,
    'city': city,
    'description': description,
    'availability': availability,
    'skills': skills,
    'status': status,
    'stats': stats.toMap(),
  };
}