import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../models/vacancy_model.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _skillInputController = TextEditingController();

  String? _selectedSalary;
  String? _selectedModality;
  String? _selectedIndustry;
  String? _selectedExperience;
  final List<String> _skills = [];
  double _progress = 0.0;
  bool _published = false;

  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  final List<String> _salaryOptions = [
    'MXN \$0 - \$10,000',
    'MXN \$10,000 - \$20,000',
    'MXN \$20,000 - \$30,000',
    'MXN \$30,000 - \$40,000',
    'MXN \$40,000 - \$50,000',
    'MXN \$50,000 - \$60,000',
    'MXN \$60,000 - \$70,000',
    'MXN \$70,000 - \$80,000',
    'MXN \$80,000 - \$90,000',
    'MXN \$90,000 - \$100,000',
    'MXN \$100,000 - \$110,000',
    'MXN \$110,000 - \$120,000',
    'MXN \$120,000 - \$130,000',
    'MXN \$130,000 - \$140,000',
    'MXN \$140,000 - \$150,000',
    'MXN \$150,000 - \$160,000',
    'MXN \$160,000 - \$170,000',
    'MXN \$170,000 - \$180,000',
    'MXN \$180,000 - \$190,000',
    'MXN \$190,000 - \$200,000',
    'MXN \$200,000+',
  ];

  final List<Map<String, dynamic>> _modalities = [
    {'label': 'Remoto', 'icon': Icons.home_work},
    {'label': 'Presencial', 'icon': Icons.location_city},
    {'label': 'Híbrido', 'icon': Icons.sync_alt},
  ];

  final List<String> _industries = [
    'Tecnología', 'Finanzas', 'Salud', 'Educación',
    'E-commerce', 'Logística', 'Media', 'Energía', 'Otro',
  ];

  final List<String> _experienceOptions = [
    'Sin experiencia', '0 a 2 años', '3 a 5 años', '5 o más años',
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: const Interval(0.3, 1.0)),
    );

    _titleController.addListener(_updateProgress);
    _descController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _skillInputController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    int filled = 0;
    if (_titleController.text.isNotEmpty) filled++;
    if (_selectedSalary != null) filled++;
    if (_selectedModality != null) filled++;
    if (_descController.text.isNotEmpty) filled++;
    if (_selectedIndustry != null) filled++;
    if (_selectedExperience != null) filled++;
    setState(() => _progress = filled / 6);
  }

  void _addSkill(String skill) {
    final s = skill.trim();
    if (s.isNotEmpty && !_skills.contains(s) && _skills.length < 8) {
      setState(() => _skills.add(s));
      _skillInputController.clear();
    }
  }

  Future<void> _publishJob() async {
    setState(() => _published = true);
    _successController.forward();

    // Guardar en Firestore
    final vacancy = Vacancy(
      id: '',
      companyUid: AuthService.currentUser?.uid ?? '',
      companyName: StorageService.getName() ?? '',
      title: _titleController.text.trim(),
      sector: _selectedIndustry ?? '',
      salary: _selectedSalary ?? '',
      city: StorageService.getCity() ?? '',
      description: _descController.text.trim(),
      availability: _selectedModality ?? 'Remoto',
      skills: List.from(_skills),
      status: 'active',
    );
    await FirestoreService.saveVacancy(vacancy);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_published) return _buildSuccessScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // HEADER DEGRADADO
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.rocket_launch, color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Publicar Oferta",
                            style: TextStyle(color: Colors.white, fontSize: 26,
                                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Text("Encuentra al candidato ideal",
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // BARRA DE PROGRESO
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${(_progress * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _progress < 1.0
                        ? "Completa los ${(6 - (_progress * 6).toInt())} campos restantes"
                        : "¡Todo listo para publicar! 🎉",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FORMULARIO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(Icons.work_outline, "Título del Puesto"),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          decoration: _inputDeco(
                            hint: "Ej: Flutter Developer Senior",
                            icon: Icons.edit,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INDUSTRIA + EXPERIENCIA
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(Icons.business, "Industria y Experiencia"),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedIndustry,
                          hint: const Text("Selecciona industria"),
                          decoration: _inputDeco(icon: Icons.domain),
                          items: _industries.map((v) => DropdownMenuItem(
                            value: v, child: Text(v),
                          )).toList(),
                          onChanged: (val) {
                            setState(() => _selectedIndustry = val);
                            _updateProgress();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedExperience,
                          hint: const Text("Experiencia requerida"),
                          decoration: _inputDeco(icon: Icons.timeline),
                          items: _experienceOptions.map((v) => DropdownMenuItem(
                            value: v, child: Text(v),
                          )).toList(),
                          onChanged: (val) {
                            setState(() => _selectedExperience = val);
                            _updateProgress();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // MODALIDAD
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(Icons.place, "Modalidad de Trabajo"),
                        const SizedBox(height: 12),
                        Row(
                          children: _modalities.map((mod) {
                            final isSelected = _selectedModality == mod['label'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedModality = mod['label']);
                                  _updateProgress();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1565C0) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                                        blurRadius: 8, offset: const Offset(0, 4),
                                      ),
                                    ] : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(mod['icon'] as IconData,
                                        color: isSelected ? Colors.white : Colors.grey[600], size: 22),
                                      const SizedBox(height: 6),
                                      Text(mod['label'] as String,
                                        style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SALARIO
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(Icons.payments, "Salario Mensual Ofrecido"),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedSalary,
                          hint: const Text("Selecciona un rango"),
                          decoration: _inputDeco(icon: Icons.attach_money),
                          items: _salaryOptions.map((v) => DropdownMenuItem(
                            value: v, child: Text(v),
                          )).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSalary = val);
                            _updateProgress();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SKILLS
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(Icons.star_outline, "Habilidades Requeridas"),
                        const SizedBox(height: 4),
                        Text("Agrega hasta 8 skills",
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _skillInputController,
                                decoration: _inputDeco(
                                  hint: "Ej: Flutter, Firebase...",
                                  icon: Icons.add,
                                ),
                                onSubmitted: _addSkill,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _addSkill(_skillInputController.text),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        if (_skills.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(skill, style: const TextStyle(
                                    color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(() => _skills.remove(skill)),
                                    child: const Icon(Icons.close, size: 14, color: Color(0xFF1565C0)),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DESCRIPCIÓN
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(Icons.description_outlined, "Descripción y Requisitos"),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Describe el rol, responsabilidades y habilidades requeridas...",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // BOTÓN PUBLICAR
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _progress >= 1.0 ? [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                          blurRadius: 16, offset: const Offset(0, 6),
                        ),
                      ] : [],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _progress >= 1.0
                              ? const Color(0xFF1565C0)
                              : Colors.grey[200],
                          foregroundColor: _progress >= 1.0 ? Colors.white : Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _progress < 1.0 ? null : _publishJob,
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text("PUBLICAR OFERTA",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1565C0), size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono animado con escala elástica
              ScaleTransition(
                scale: _successScale,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                        blurRadius: 24, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 32),

              FadeTransition(
                opacity: _successFade,
                child: Column(
                  children: [
                    const Text("¡Oferta Publicada!",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                          color: Colors.black87, letterSpacing: -0.5)),
                    const SizedBox(height: 12),
                    Text(
                      "Tu oferta ya es visible para los candidatos.\nRegresando al feed...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // Resumen de lo publicado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(Icons.work_outline, _titleController.text),
                          if (_selectedModality != null)
                            _summaryRow(Icons.place, _selectedModality!),
                          if (_selectedSalary != null)
                            _summaryRow(Icons.attach_money, _selectedSalary!),
                          if (_selectedIndustry != null)
                            _summaryRow(Icons.domain, _selectedIndustry!),
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
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}