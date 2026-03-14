import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/job_card.dart';
import '../models/match_model.dart';
import 'matches_screen.dart';
import 'settings_screen.dart';
import 'post_job_screen.dart';
import 'job_detail_screen.dart';
import 'notifications_screen.dart';
import 'vacancies_screen.dart';
import '../widgets/job_card_skeleton.dart';
import '../services/location_service.dart';

// Feed 100% conectado a Firestore — sin perfiles de prueba

class FeedScreen extends StatefulWidget {
  final String name;
  final String profession;
  final String? role;
  const FeedScreen({super.key, required this.name, required this.profession, this.role});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<JobMatch> userMatches = [];
  String? _profileImageUrl;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  AppNotification? _activeBanner;
  int _unreadMessages = 0;
  late String userRole;
  List<Map<String, dynamic>> allProfiles = [];
  List<Map<String, dynamic>> filteredProfiles = [];
  String selectedModality = 'Todos';
  String? _filterMinSalary;
  String? _filterMaxSalary;
  String? _filterIndustry;
  String? _filterEducation;
  String? _filterCity;
  // Filtros exclusivos para empresa
  String? _filterExperience;
  String? _filterAvailability;

  final List<String> _industries = [
    'Software', 'Diseño', 'Finanzas', 'Salud', 'Educación',
    'Logística', 'Medios', 'Energía', 'E-commerce', 'Turismo',
  ];

  final List<String> _educationLevels = [
    'Secundaria', 'Preparatoria / Bachillerato', 'Carrera Técnica', 'Licenciatura+',
  ];

  final List<String> _salaryRanges = [
    'MXN \$0 - \$10,000', 'MXN \$10,000 - \$20,000', 'MXN \$20,000 - \$30,000',
    'MXN \$30,000 - \$40,000', 'MXN \$40,000 - \$50,000', 'MXN \$50,000 - \$60,000',
    'MXN \$60,000 - \$70,000', 'MXN \$70,000 - \$80,000', 'MXN \$80,000 - \$90,000',
    'MXN \$90,000 - \$100,000', 'MXN \$100,000 - \$110,000', 'MXN \$110,000 - \$120,000',
    'MXN \$120,000 - \$130,000', 'MXN \$130,000 - \$140,000', 'MXN \$140,000 - \$150,000',
    'MXN \$150,000 - \$160,000', 'MXN \$160,000 - \$170,000', 'MXN \$170,000 - \$180,000',
    'MXN \$180,000 - \$190,000', 'MXN \$190,000 - \$200,000', 'MXN \$200,000+',
  ];
  bool _isLoading = true;
  bool _locationRequested = false;
  double _swipeProgress = 0.0;
  int _frontCardIndex = 0;
  bool _cardsFinished = false;
  int _filterKey = 0;

  @override
  void initState() {
    super.initState();
    userRole = widget.role ?? StorageService.getUserRole() ?? 'candidate';
    debugPrint('🎯 FeedScreen initState: userRole=$userRole (param=${widget.role}, storage=${StorageService.getUserRole()})');
    _profileImageUrl = StorageService.getImageUrl();

    _loadMatches();
    _loadNotifications();
    _requestLocationThenLoad();
  }

  void _loadNotifications() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    FirestoreService.watchNotifications(uid).listen((list) {
      if (mounted) setState(() {
        _notifications = list.map((m) => AppNotification.fromMap(m)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      });
    });
  }

  Future<void> _requestLocationThenLoad() async {
    // Solo pedir ubicación si el usuario no tiene ciudad guardada
    final savedCity = StorageService.getCity() ?? '';
    if (savedCity.isEmpty && !_locationRequested) {
      setState(() => _locationRequested = true);
      final result = await LocationService.requestLocation();
      if (result != null && result.displayCity.isNotEmpty) {
        StorageService.saveCity(result.displayCity);
        // Actualizar en Firestore para que otros puedan encontrarlo
        try {
          await FirestoreService.updateCity(result.displayCity);
        } catch (_) {}
      }
    }
    _loadFirestoreProfiles();
  }

  Future<void> _loadFirestoreProfiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final myCity = StorageService.getCity() ?? '';
    final targetRole = userRole == 'candidate' ? 'company' : 'candidate';
    final results = await FirestoreService.searchProfiles(
      targetRole: targetRole,
      city: _filterCity,
      sector: _filterIndustry,
      availability: _filterAvailability,
      experience: _filterExperience,
      minSalary: _filterMinSalary,
      maxSalary: _filterMaxSalary,
    );

    // Lógica de geolocalización por ciudad:
    // - Remotos → aparecen para todos
    // - Presenciales e híbridos → solo si coincide la ciudad del usuario
    final filtered = results.where((p) {
      final avail = (p['availability'] ?? '').toString().toLowerCase();
      final isRemote = avail.contains('remoto');
      if (isRemote) return true; // remotos siempre visibles
      if (myCity.isEmpty) return true; // si el usuario no tiene ciudad, mostrar todos
      final profileCity = (p['city'] ?? '').toString().toLowerCase();
      return profileCity.contains(myCity.toLowerCase()) ||
             myCity.toLowerCase().contains(profileCity);
    }).map((u) => {
      'uid': u['uid'],
      'name': u['name'],
      'subtitle': '${u['sector'].isNotEmpty ? u['sector'] : u['profession']} • ${u['availability']}',
      'bio': u['bio'],
      'salary': u['salary'],
      'imageUrl': u['imageUrl'],
      'skills': u['skills'] ?? <String>[],
      'city': u['city'],
      'availability': u['availability'],
      'experience': u['experience'],
      'phone': u['phone'],
      'linkedin': u['linkedin'],
      'website': u['website'],
      'education': u['education'] ?? '',
    }).toList();

    if (mounted) setState(() {
      allProfiles = filtered;
      filteredProfiles = List.from(filtered);
      _isLoading = false;
      _cardsFinished = filtered.isEmpty;
    });
  }

  void _loadMatches() {
    FirestoreService.watchMatches().listen((matches) {
      if (mounted) setState(() {
        userMatches = matches;
        _isLoading = false;
        _profileImageUrl = StorageService.getImageUrl();
        _unreadMessages = matches.fold(0, (sum, m) => sum + m.unreadCount);
      });
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _searchFirestoreProfiles() async {
    final targetRole = userRole == 'candidate' ? 'company' : 'candidate';
    final firestoreResults = await FirestoreService.searchProfiles(
      targetRole: targetRole,
      city: _filterCity,
      sector: _filterIndustry,
      availability: _filterAvailability,
      experience: _filterExperience,
      minSalary: _filterMinSalary,
      maxSalary: _filterMaxSalary,
    );

    // Convertir resultados de Firestore al formato de tarjetas
    final converted = firestoreResults.map((u) => {
      'name': u['name'],
      'subtitle': '${u['sector']} • ${u['city']}',
      'bio': u['bio'],
      'salary': u['salary'],
      'imageUrl': u['imageUrl'],
      'skills': <String>[],
      'city': u['city'],
      'availability': u['availability'],
      'experience': u['experience'],
    }).toList();

    if (mounted) setState(() {
      allProfiles = converted;
      _applyFilters();
    });
  }

  void _addNotification(AppNotification notif) {
    setState(() {
      _notifications.insert(0, notif);
      _unreadCount++;
      _activeBanner = notif;
    });
    // Persistir en Firestore
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      FirestoreService.saveNotification(uid, notif.toMap());
    }
  }

  void _handleMatch(Map<String, dynamic> profile) {
    final match = JobMatch(
      name: profile["name"],
      imageUrl: profile["imageUrl"],
      subtitle: profile["subtitle"],
      bio: profile["bio"] as String?,
      salary: profile["salary"] as String?,
      skills: List<String>.from(profile["skills"] ?? []),
      unreadCount: 1,
      hasNewMatch: true,
    );
    FirestoreService.saveMatch(match);
    FirestoreService.incrementSwipesReceived(profile["name"]);
    setState(() { userMatches.add(match); });
    _addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.match,
      title: "¡Nuevo Match con ${profile["name"]}!",
      subtitle: "Ambos se han conectado. Ya puedes iniciar una conversación.",
      imageUrl: profile["imageUrl"],
      time: DateTime.now(),
    ));
    _showMatchDialog(profile);
  }

  void _showMatchDialog(Map<String, dynamic> profile) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      barrierLabel: 'match',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) => _MatchDialog(
        profile: profile,
        onViewMatches: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MatchesScreen(
              matches: userMatches,
              onMessageSent: (name, imageUrl, type) {
                final subtitle = type == 'image'
                    ? "Enviaste una imagen 📷"
                    : type == 'pdf'
                        ? "Enviaste un documento PDF 📄"
                        : "Enviaste un mensaje nuevo";
                setState(() {});
                _addNotification(AppNotification(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: NotificationType.message,
                  title: "Mensaje enviado a $name",
                  subtitle: subtitle,
                  imageUrl: imageUrl,
                  time: DateTime.now(),
                ));
              },
            )),
          );
        },
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: const Interval(0.0, 0.4)),
            ),
            child: child,
          ),
        );
      },
    );
  }


  void _applyFilters() {
    filteredProfiles = allProfiles.where((p) {
      // Filtro de ciudad aplica para ambos roles
      if (_filterCity != null && _filterCity!.isNotEmpty) {
        final city = p['city']?.toString().toLowerCase() ?? '';
        if (!city.contains(_filterCity!.toLowerCase())) return false;
      }
      if (userRole == 'candidate') {
        // FILTROS PARA CANDIDATO
        if (selectedModality != 'Todos' && !p['subtitle'].toString().contains(selectedModality)) return false;
        if (_filterIndustry != null && !p['subtitle'].toString().contains(_filterIndustry!)) return false;
        if (_filterMinSalary != null) {
          final int minVal = int.tryParse(_filterMinSalary!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final int profileSal = int.tryParse(p['salary'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (profileSal < minVal) return false;
        }
        if (_filterMaxSalary != null) {
          final int maxVal = int.tryParse(_filterMaxSalary!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999999;
          final int profileSal = int.tryParse(p['salary'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (profileSal > maxVal) return false;
        }
      } else {
        // FILTROS PARA EMPRESA
        if (_filterAvailability != null && p['availability']?.toString() != _filterAvailability) return false;
        if (_filterExperience != null && p['experience']?.toString() != _filterExperience) return false;
        if (_filterEducation != null) {
          final String edu = p['education']?.toString() ?? '';
          if (!edu.contains(_filterEducation!)) return false;
        }
        if (_filterMinSalary != null) {
          final int minVal = int.tryParse(_filterMinSalary!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final int profileSal = int.tryParse(p['salary'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (profileSal < minVal) return false;
        }
        if (_filterMaxSalary != null) {
          final int maxVal = int.tryParse(_filterMaxSalary!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999999;
          final int profileSal = int.tryParse(p['salary'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (profileSal > maxVal) return false;
        }
      }
      return true;
    }).toList();
    _frontCardIndex = 0;
    _cardsFinished = false;
    _swipeProgress = 0.0;
    _filterKey++;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterCity != null && _filterCity!.isNotEmpty) count++;
    if (userRole == 'candidate') {
      if (selectedModality != 'Todos') count++;
      if (_filterIndustry != null) count++;
    } else {
      if (_filterAvailability != null) count++;
      if (_filterExperience != null) count++;
      if (_filterEducation != null) count++;
    }
    if (_filterMinSalary != null) count++;
    if (_filterMaxSalary != null) count++;
    return count;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void applyAndRefresh() {
            setModalState(() {});
            // No aplicamos en tiempo real — se aplica al cerrar
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                    child: Row(
                      children: [
                        const Text("Filtros", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_activeFilterCount > 0)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                selectedModality = 'Todos';
                                _filterMinSalary = null;
                                _filterMaxSalary = null;
                                _filterIndustry = null;
                                _filterEducation = null;
                                _filterCity = null;
                                _filterAvailability = null;
                                _filterExperience = null;
                              });
                              setState(() {
                                filteredProfiles = List.from(allProfiles);
                                _filterKey++;
                                _frontCardIndex = 0;
                                _cardsFinished = false;
                              });
                            },
                            child: const Text("Limpiar todo", style: TextStyle(color: Colors.red)),
                          ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (userRole == 'candidate') ...[

                          // CANDIDATO: Modalidad
                          _filterSection("Modalidad de Trabajo", Icons.place,
                            child: _filterChips(['Todos', 'Remoto', 'Presencial', 'Híbrido'],
                              selected: selectedModality,
                              onSelect: (v) { setModalState(() => selectedModality = v); },
                            ),
                          ),

                          // CANDIDATO: Rango Salarial ofrecido
                          _filterSection("Salario Ofrecido", Icons.monetization_on,
                            child: _salaryRangeRow(setModalState, applyAndRefresh),
                          ),

                          // CANDIDATO: Industria
                          _filterSection("Industria / Sector", Icons.business,
                            child: _filterChips(_industries,
                              selected: _filterIndustry ?? '',
                              onSelect: (v) { setModalState(() => _filterIndustry = _filterIndustry == v ? null : v); },
                            ),
                          ),

                          // CANDIDATO: Ciudad
                          _filterSection("Ciudad / Ubicación", Icons.location_city,
                            child: _citySearchField(setModalState),
                          ),

                        ] else ...[

                          // EMPRESA: Disponibilidad
                          _filterSection("Disponibilidad del Candidato", Icons.place,
                            child: _filterChips(['Remoto', 'Presencial', 'Híbrido'],
                              selected: _filterAvailability ?? '',
                              onSelect: (v) { setModalState(() => _filterAvailability = _filterAvailability == v ? null : v); },
                            ),
                          ),

                          // EMPRESA: Ciudad
                          _filterSection("Ciudad / Ubicación", Icons.location_city,
                            child: _citySearchField(setModalState),
                          ),

                          // EMPRESA: Experiencia
                          _filterSection("Años de Experiencia", Icons.work_history,
                            child: _filterChips(['0 a 2 años', '3 a 5 años', '5 o más años'],
                              selected: _filterExperience ?? '',
                              onSelect: (v) { setModalState(() => _filterExperience = _filterExperience == v ? null : v); },
                            ),
                          ),

                          // EMPRESA: Expectativa salarial
                          _filterSection("Expectativa Salarial", Icons.monetization_on,
                            child: _salaryRangeRow(setModalState, applyAndRefresh),
                          ),

                          // EMPRESA: Escolaridad
                          _filterSection("Nivel de Escolaridad", Icons.school,
                            child: _filterChips(_educationLevels,
                              selected: _filterEducation ?? '',
                              onSelect: (v) { setModalState(() => _filterEducation = _filterEducation == v ? null : v); },
                            ),
                          ),

                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Botón aplicar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _searchFirestoreProfiles();
                        },
                        child: Text(
                          _activeFilterCount > 0 ? "Ver resultados ($_activeFilterCount filtros)" : "Ver resultados",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filterChips(List<String> options, {required String selected, List<String>? multiSelected, required Function(String) onSelect}) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final bool sel = multiSelected != null ? multiSelected.contains(opt) : selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? Colors.blue : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? Colors.blue : Colors.grey.shade300),
            ),
            child: Text(opt, style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _salaryRangeRow(StateSetter setModalState, VoidCallback applyAndRefresh) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _filterMinSalary,
            hint: const Text("Mínimo", style: TextStyle(fontSize: 13)),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            isExpanded: true,
            items: _salaryRanges.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) { setModalState(() => _filterMinSalary = val); applyAndRefresh(); },
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("—", style: TextStyle(color: Colors.grey))),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _filterMaxSalary,
            hint: const Text("Máximo", style: TextStyle(fontSize: 13)),
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            isExpanded: true,
            items: _salaryRanges.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) { setModalState(() => _filterMaxSalary = val); applyAndRefresh(); },
          ),
        ),
      ],
    );
  }

  Widget _filterSection(String title, IconData icon, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _citySearchField(StateSetter setModalState) {
    return TextFormField(
      initialValue: _filterCity ?? '',
      decoration: InputDecoration(
        hintText: "Ej: Guadalajara, Ciudad de México...",
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.blue),
        suffixIcon: (_filterCity != null && _filterCity!.isNotEmpty)
            ? IconButton(
                icon: Icon(Icons.clear, size: 16, color: Colors.grey[400]),
                onPressed: () {
                  setModalState(() => _filterCity = null);
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onChanged: (v) => _filterCity = v.isEmpty ? null : v,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth > 500 ? 450 : screenWidth * 0.9;

    // Texto del feed según rol
    String feedTitle = userRole == 'candidate' ? 'Empresas para ti' : 'Candidatos destacados';
    bool isCompany = userRole == 'company';

    return Stack(
      children: [
        Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      // Botón flotante visible SOLO para empresas en desktop
      floatingActionButton: isCompany && screenWidth > 500
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostJobScreen()),
              ),
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Publicar Oferta",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
          // HEADER VISUAL — ancho completo
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),

            ),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Avatar + saludo
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => SettingsScreen(userName: widget.name, userProfession: widget.profession)));
                            if (mounted) setState(() => _profileImageUrl = StorageService.getImageUrl());
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _buildHeaderAvatar(userRole),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                                  ),
                                  Text(
                                    widget.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Acciones
                        Builder(builder: (context) {
                          final isSmallScreen = MediaQuery.of(context).size.width < 400;
                          final gap = isSmallScreen ? 4.0 : 8.0;
                          return Row(
                          children: [
                            if (isCompany) ...[
                              _headerBtn(Icons.work_outline, () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => const VacanciesScreen()));
                              }),
                              SizedBox(width: gap),
                            ],
                            Stack(
                              children: [
                                _headerBtn(Icons.tune, _showFilterModal),
                                if (_activeFilterCount > 0)
                                  Positioned(
                                    top: 0, right: 0,
                                    child: Container(
                                      width: 16, height: 16,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          '$_activeFilterCount',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: gap),
                            Stack(
                              children: [
                                _headerBtn(Icons.chat_bubble_outline, () {
                                  setState(() => _unreadMessages = 0);
                                  Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => MatchesScreen(
                                    matches: userMatches,
                                    onMessageSent: (name, imageUrl, type) {
                                      final subtitle = type == 'image'
                                          ? "Enviaste una imagen 📷"
                                          : type == 'pdf'
                                              ? "Enviaste un documento PDF 📄"
                                              : "Tu mensaje fue entregado. Espera su respuesta.";
                                      setState(() {});
                                      _addNotification(AppNotification(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        type: NotificationType.message,
                                        title: "Mensaje enviado a $name",
                                        subtitle: subtitle,
                                        imageUrl: imageUrl,
                                        time: DateTime.now(),
                                      ));
                                    },
                                  )));
                                }),
                                if (_unreadMessages > 0)
                                  Positioned(
                                    right: 0, top: 0,
                                    child: Container(
                                      width: 16, height: 16,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          '$_unreadMessages',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: gap),
                            Stack(
                              children: [
                                _headerBtn(Icons.notifications, () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => NotificationsScreen(
                                      notifications: _notifications,
                                      onMarkAllRead: () {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) setState(() => _unreadCount = 0);
                                        });
                                      },
                                    ),
                                  ));
                                }),
                                if (_unreadCount > 0)
                                  Positioned(
                                    right: 0, top: 0,
                                    child: Container(
                                      width: 16, height: 16,
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          '$_unreadCount',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: gap),
                            _headerBtn(Icons.more_vert, () async {
                              await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => SettingsScreen(
                                  userName: widget.name, userProfession: widget.profession)));
                              if (mounted) setState(() => _profileImageUrl = StorageService.getImageUrl());
                            }),
                          ],
                        );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Título del feed + botón publicar en móvil
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.explore, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              feedTitle,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        // Botón publicar oferta en móvil (solo empresa)
                        if (isCompany && screenWidth <= 500)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PostJobScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.add, color: Color(0xFF1565C0), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "Publicar",
                                    style: TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          // FIN HEADER — resto del contenido con maxWidth
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _isLoading
                            ? JobCardSkeleton()
                            : filteredProfiles.isEmpty
                                ? _buildNoResultsFeed()
                                : _cardsFinished
                                    ? _buildEmptyFeed()
                                    : CardSwiper(
                          controller: controller,
                          cardsCount: filteredProfiles.length,
                          isLoop: false,
                          key: ValueKey(_filterKey),
                          onSwipe: (prev, curr, dir) {
                            if (dir == CardSwiperDirection.right) {
                              _handleMatch(filteredProfiles[prev]);
                            }
                            setState(() {
                              _swipeProgress = 0.0;
                              _frontCardIndex = curr ?? _frontCardIndex + 1;
                              if (curr == null) _cardsFinished = true;
                            });
                            return true;
                          },
                          onSwipeDirectionChange: (horizontal, vertical) {
                            setState(() {
                              if (horizontal == CardSwiperDirection.right) {
                                _swipeProgress = 0.6;
                              } else if (horizontal == CardSwiperDirection.left) {
                                _swipeProgress = -0.6;
                              } else {
                                _swipeProgress = 0.0;
                              }
                            });
                          },
                          cardBuilder: (context, index, percentX, percentY) => GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(
                                  profile: filteredProfiles[index],
                                  onApply: () => _handleMatch(filteredProfiles[index]),
                                ),
                              ),
                            ),
                            child: JobCard(
                              name: filteredProfiles[index]["name"],
                              subtitle: filteredProfiles[index]["subtitle"],
                              bio: filteredProfiles[index]["bio"],
                              imageUrl: filteredProfiles[index]["imageUrl"],
                              salary: filteredProfiles[index]["salary"],
                              skills: List<String>.from(filteredProfiles[index]["skills"] ?? []),
                              swipeProgress: index == _frontCardIndex ? _swipeProgress : 0.0,
                              cardIndex: index,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleBtn(Icons.close, Colors.red, () async {
                          setState(() => _swipeProgress = -0.6);
                          await Future.delayed(const Duration(milliseconds: 300));
                          controller.swipe(CardSwiperDirection.left);
                        }),
                        const SizedBox(width: 40),
                        _circleBtn(Icons.handshake, Colors.teal, () async {
                          setState(() => _swipeProgress = 0.6);
                          await Future.delayed(const Duration(milliseconds: 300));
                          controller.swipe(CardSwiperDirection.right);
                        }),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ], // cierre Column body
      ), // cierre Scaffold body
    ), // cierre Scaffold
    // BANNER FLOTANTE
    if (_activeBanner != null)
      Positioned(
        top: 0, left: 0, right: 0,
        child: NotificationBanner(
          notification: _activeBanner!,
          onDismiss: () => setState(() => _activeBanner = null),
        ),
      ),
    ], // cierre Stack.children
  ); // cierre Stack
  }

  Widget _buildNoResultsFeed() {
    final bool hasFilters = _filterCity != null || _filterIndustry != null ||
        _filterMinSalary != null || _filterAvailability != null || _filterExperience != null;
    final myCity = StorageService.getCity() ?? '';
    final bool isLocationEmpty = allProfiles.isEmpty && myCity.isNotEmpty && !hasFilters;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isLocationEmpty
                  ? Colors.blue.withValues(alpha: 0.08)
                  : Colors.orange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocationEmpty ? Icons.location_city_rounded : Icons.search_off_rounded,
              size: 64,
              color: isLocationEmpty ? const Color(0xFF1565C0) : Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isLocationEmpty
                ? "Pronto habrá más perfiles cerca de ti"
                : hasFilters
                    ? "Sin resultados"
                    : "Pronto habrá más perfiles",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            isLocationEmpty
                ? "Aún no hay ${userRole == 'candidate' ? 'empresas' : 'candidatos'} registrados en $myCity.\nLos empleos remotos aparecerán aquí en cuanto se publiquen."
                : hasFilters
                    ? "Ningún perfil coincide con los filtros aplicados."
                    : "Aún no hay ${userRole == 'candidate' ? 'empresas' : 'candidatos'} registrados.\nVuelve pronto, la comunidad está creciendo.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 28),
          if (hasFilters) ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                selectedModality = 'Todos';
                _filterMinSalary = null;
                _filterMaxSalary = null;
                _filterIndustry = null;
                _filterEducation = null;
                _filterAvailability = null;
                _filterExperience = null;
                _filterCity = null;
                filteredProfiles = List.from(allProfiles);
                _frontCardIndex = 0;
                _cardsFinished = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Limpiar filtros", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (!hasFilters) OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(color: Color(0xFF1565C0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _loadFirestoreProfiles,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Actualizar", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    final int matchCount = userMatches.length;
    final int totalSeen = allProfiles.length;

    return _AnimatedEmptyFeed(
      matchCount: matchCount,
      totalSeen: totalSeen,
      onRefresh: () {
        setState(() {
          filteredProfiles = List.from(allProfiles);
          selectedModality = 'Todos';
          _frontCardIndex = 0;
          _cardsFinished = false;
        });
      },
      onViewMatches: matchCount > 0 ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchesScreen(
            matches: userMatches,
            onMessageSent: (name, imageUrl, type) {
              final subtitle = type == 'image'
                  ? "Enviaste una imagen 📷"
                  : type == 'pdf'
                      ? "Enviaste un documento PDF 📄"
                      : "Enviaste un mensaje nuevo";
              setState(() {});
              _addNotification(AppNotification(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: NotificationType.message,
                title: "Mensaje enviado a $name",
                subtitle: subtitle,
                imageUrl: imageUrl,
                time: DateTime.now(),
              ));
            },
          )),
        );
      } : null,
    );
  }

  Widget _buildHeaderAvatar(String role) {
    final imageData = _profileImageUrl;
    ImageProvider? imageProvider;

    if (imageData != null && imageData.isNotEmpty) {
      if (imageData.startsWith('data:')) {
        try {
          imageProvider = MemoryImage(base64Decode(imageData.split(',').last));
        } catch (_) {}
      } else if (imageData.startsWith('http')) {
        imageProvider = NetworkImage(imageData);
      }
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(role == 'company' ? Icons.business : Icons.person,
              color: Colors.white, size: 22)
          : null,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "¡Buenos días!";
    if (hour < 18) return "¡Buenas tardes!";
    return "¡Buenas noches!";
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final padding = isSmall ? 6.0 : 8.0;
    final iconSize = isSmall ? 17.0 : 20.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}


// ─────────────────────────────────────────────
// WIDGET ANIMADO DE MATCH
// ─────────────────────────────────────────────
class _MatchDialog extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback? onViewMatches;
  const _MatchDialog({required this.profile, this.onViewMatches});

  @override
  State<_MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _avatarController;
  late AnimationController _textController;
  late AnimationController _confettiController;

  late Animation<double> _cardScale;
  late Animation<double> _avatarScale;
  late Animation<double> _avatarBounce;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _btnFade;
  late Animation<double> _confettiAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _avatarController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.elasticOut));
    _avatarBounce = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeInOut));
    _glowAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeInOut));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _btnFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Secuencia de animaciones
    _cardController.forward().then((_) {
      _avatarController.forward().then((_) {
        _textController.forward();
      });
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _avatarController.dispose();
    _textController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedBuilder(
        animation: Listenable.merge([_cardController, _avatarController, _textController, _confettiController]),
        builder: (_, __) => ScaleTransition(
          scale: _cardScale,
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: _glowAnim.value),
                  blurRadius: 50,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // CONFETI
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: CustomPaint(
                      painter: _ConfettiPainter(_confettiController.value),
                    ),
                  ),
                ),

                // CONTENIDO
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ÍCONO HANDSHAKE CON PULSO
                      Transform.scale(
                        scale: _avatarBounce.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: const Icon(Icons.handshake, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TÍTULO con fade + slide
                      Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: const Text(
                            "¡Es un Match!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: _textFade.value,
                        child: Text(
                          "Ambos están interesados en conectar",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // AVATAR con entrada elástica
                      Transform.scale(
                        scale: _avatarScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anillo exterior pulsante
                            Transform.scale(
                              scale: _avatarBounce.value * 1.05,
                              child: Container(
                                width: 124,
                                height: 124,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundImage: NetworkImage(widget.profile['imageUrl']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NOMBRE
                      Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Text(
                            widget.profile['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Opacity(
                        opacity: _textFade.value,
                        child: Text(
                          widget.profile['subtitle'],
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // BOTONES
                      Opacity(
                        opacity: _btnFade.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1565C0),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onViewMatches?.call();
                                },
                                child: const Text("Ver mis conexiones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "Seguir explorando",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CONFETI PAINTER
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static const _colors = [Colors.yellow, Colors.pink, Colors.greenAccent, Colors.orange, Colors.white, Colors.lightBlueAccent];

  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final t = (progress + i / 30) % 1.0;
      final x = rng.nextDouble() * size.width;
      final y = t * (size.height + 20) - 10;
      final color = _colors[i % _colors.length];
      final paint = Paint()..color = color.withValues(alpha: (1 - t) * 0.7);
      final w = 6.0 + rng.nextDouble() * 6;
      final h = 4.0 + rng.nextDouble() * 4;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 4 + i);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────
// PANTALLA VACÍA ANIMADA
// ─────────────────────────────────────────────────────────────
class _AnimatedEmptyFeed extends StatefulWidget {
  final int matchCount;
  final int totalSeen;
  final VoidCallback onRefresh;
  final VoidCallback? onViewMatches;

  const _AnimatedEmptyFeed({
    required this.matchCount,
    required this.totalSeen,
    required this.onRefresh,
    this.onViewMatches,
  });

  @override
  State<_AnimatedEmptyFeed> createState() => _AnimatedEmptyFeedState();
}

class _AnimatedEmptyFeedState extends State<_AnimatedEmptyFeed>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _iconScale;
  late Animation<double> _iconFade;
  late Animation<double> _contentSlide;
  late Animation<double> _contentFade;
  late Animation<double> _statsScale;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController,
          curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
    );
    _statsScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack)),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMatches = widget.matchCount > 0;
    final double matchRate = widget.totalSeen > 0
        ? (widget.matchCount / widget.totalSeen * 100)
        : 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ÍCONO ANIMADO CON PULSO
            AnimatedBuilder(
              animation: Listenable.merge([_mainController, _pulseController]),
              builder: (_, __) => Opacity(
                opacity: _iconFade.value,
                child: Transform.scale(
                  scale: _iconScale.value * _pulse.value,
                  child: Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.done_all, color: Colors.white, size: 60),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // TÍTULO Y DESCRIPCIÓN
            AnimatedBuilder(
              animation: _mainController,
              builder: (_, child) => Opacity(
                opacity: _contentFade.value,
                child: Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: child,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    "¡Lo viste todo!",
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: Colors.black87, letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasMatches
                        ? "Revisaste todos los perfiles disponibles.\n¡Tienes conexiones esperándote!"
                        : "Revisaste todos los perfiles disponibles.\nVuelve pronto o ajusta tus filtros.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ESTADÍSTICAS DE SESIÓN
            AnimatedBuilder(
              animation: _mainController,
              builder: (_, child) => Transform.scale(
                scale: _statsScale.value,
                child: Opacity(opacity: _contentFade.value, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _statItem(
                      icon: Icons.remove_red_eye_outlined,
                      value: "${widget.totalSeen}",
                      label: "Vistos",
                      color: Colors.blue,
                    ),
                    _statDivider(),
                    _statItem(
                      icon: Icons.handshake,
                      value: "${widget.matchCount}",
                      label: "Matches",
                      color: Colors.green,
                    ),
                    _statDivider(),
                    _statItem(
                      icon: Icons.percent,
                      value: "${matchRate.toStringAsFixed(0)}%",
                      label: "Tasa",
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // BOTONES
            AnimatedBuilder(
              animation: _mainController,
              builder: (_, child) => Opacity(
                opacity: _contentFade.value,
                child: Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: child,
                ),
              ),
              child: Column(
                children: [
                  // Ver Matches (si los hay)
                  if (hasMatches)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: widget.onViewMatches,
                        icon: const Icon(Icons.handshake, size: 18),
                        label: Text(
                          "Ver mis ${widget.matchCount} conexión${widget.matchCount > 1 ? 'es' : ''}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  if (hasMatches) const SizedBox(height: 12),

                  // Volver a ver
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Ver perfiles de nuevo",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1, height: 50,
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}