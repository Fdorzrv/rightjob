import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../helpers/image_picker_helper.dart';
import 'feed_screen.dart';

class ProfileFormScreen extends StatefulWidget {
  final String role;
  const ProfileFormScreen({super.key, required this.role});

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _profController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();
  final _cityController = TextEditingController();

  String? _selectedSalary;
  String? _selectedImage;
  String? _selectedEducation;
  String? _selectedCareer;
  String? _selectedSector;
  String? _selectedCompanySize;
  double _progress = 0.0;
  bool _submitted = false;

  bool get _isCompany => widget.role == 'company';

  // ── OPCIONES ──────────────────────────────────────────────────────────────
  final List<String> _educationLevels = [
    'Secundaria', 'Preparatoria / Bachillerato', 'Carrera Técnica', 'Licenciatura+',
  ];

  final List<String> _careerOptions = [
    'Ingeniería en Sistemas / Software', 'Ingeniería Industrial', 'Ingeniería Civil',
    'Ingeniería Mecánica', 'Ingeniería Electrónica', 'Administración de Empresas',
    'Contabilidad / Finanzas', 'Mercadotecnia / Marketing', 'Diseño Gráfico / Digital',
    'Diseño UX/UI', 'Psicología', 'Derecho', 'Medicina', 'Arquitectura',
    'Comunicación / Periodismo', 'Relaciones Internacionales', 'Economía',
    'Recursos Humanos', 'Ciencias de Datos', 'Inteligencia Artificial', 'Otra',
  ];

  final List<String> _sectorOptions = [
    'Tecnología / Software', 'Finanzas / Fintech', 'Salud / Medtech',
    'Educación / Edtech', 'E-commerce / Retail', 'Logística / Supply Chain',
    'Medios / Entretenimiento', 'Energía / Cleantech', 'Turismo / Hospitalidad',
    'Manufactura / Industria', 'Consultoría', 'Otro',
  ];

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

  // ── LABELS ────────────────────────────────────────────────────────────────
  String get _nameLabel => _isCompany ? 'Nombre de la Empresa *' : 'Nombre Completo *';
  String get _bioLabel => _isCompany ? 'Descripción de la Empresa *' : 'Sobre ti (Bio) *';
  String get _salaryLabel => _isCompany ? 'Rango Salarial Ofrecido *' : 'Expectativa Salarial *';

  // ── PROGRESO ──────────────────────────────────────────────────────────────
  void _updateProgress() {
    int filled = 0;
    int total = _isCompany ? 6 : 7;

    if (_nameController.text.trim().isNotEmpty) filled++;
    if (_bioController.text.trim().length >= 20) filled++;
    if (_selectedSalary != null) filled++;
    if (_phoneController.text.trim().length >= 8) filled++;
    if (_selectedImage != null) filled++;

    if (_isCompany) {
      if (_cityController.text.trim().isNotEmpty) filled++;
    } else {
      if (_profController.text.trim().isNotEmpty) filled++;
      if (_selectedEducation != null &&
          (_selectedEducation != 'Licenciatura+' || _selectedCareer != null)) filled++;
    }

    setState(() => _progress = filled / total);
  }

  // ── VALIDADORES ───────────────────────────────────────────────────────────
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return _isCompany ? 'El nombre de la empresa es obligatorio' : 'El nombre es obligatorio';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  String? _validateBio(String? v) {
    if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
    if (v.trim().length < 20) return 'Mínimo 20 caracteres';
    if (v.trim().length > 300) return 'Máximo 300 caracteres';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'El teléfono es obligatorio';
    if (v.trim().length < 8) return 'Ingresa un teléfono válido';
    return null;
  }

  String? _validateCity(String? v) {
    if (v == null || v.trim().isEmpty) return 'País / Ciudad es obligatorio';
    return null;
  }

  String? _validateLinkedin(String? v) {
    if (v == null || v.trim().isEmpty) return null; // Opcional
    if (!v.trim().contains('linkedin.com')) return 'Ingresa un URL de LinkedIn válido';
    return null;
  }

  String? _validateWebsite(String? v) {
    if (v == null || v.trim().isEmpty) return null; // Opcional
    if (!v.trim().startsWith('http')) return 'Ingresa un URL válido (https://...)';
    return null;
  }

  // ── SUBMIT ────────────────────────────────────────────────────────────────
  void _handleSubmit() {
    setState(() => _submitted = true);

    final bool formValid = _formKey.currentState?.validate() ?? false;
    final bool salaryValid = _selectedSalary != null;
    final bool photoValid = _selectedImage != null;
    final bool educationValid = _isCompany || (_selectedEducation != null &&
        (_selectedEducation != 'Licenciatura+' || _selectedCareer != null));

    if (!formValid || !salaryValid || !photoValid || !educationValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 10),
          Expanded(child: Text("Por favor completa todos los campos obligatorios")),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    String? educationText;
    if (_selectedEducation != null) {
      educationText = _selectedEducation == 'Licenciatura+' && _selectedCareer != null
          ? 'Licenciatura+ · $_selectedCareer'
          : _selectedEducation;
    }

    final profession = _isCompany
        ? (_selectedSector ?? _profController.text.trim())
        : _profController.text.trim();

    // Guardar extra fields en storage
    if (_phoneController.text.trim().isNotEmpty) {
      StorageService.savePhone(_phoneController.text.trim());
    }
    if (_linkedinController.text.trim().isNotEmpty) {
      StorageService.saveLinkedin(_linkedinController.text.trim());
    }
    if (_isCompany && _websiteController.text.trim().isNotEmpty) {
      StorageService.saveWebsite(_websiteController.text.trim());
    }
    if (_isCompany && _cityController.text.trim().isNotEmpty) {
      StorageService.saveCity(_cityController.text.trim());
    }

    StorageService.saveFullProfile(
      name: _nameController.text.trim(),
      profession: profession,
      role: widget.role,
      bio: _bioController.text.trim(),
      salary: _selectedSalary,
      education: educationText,
      imageUrl: _selectedImage,
    );

    // Persistir imagen por UID para sobrevivir cierre de sesión
    if (_selectedImage != null) {
      final uid = AuthService.currentUser?.uid;
      if (uid != null) StorageService.saveImageForUid(uid, _selectedImage!);
    }

    AuthService.saveFullProfileToFirestore(
      name: _nameController.text.trim(),
      role: widget.role,
      bio: _bioController.text.trim(),
      salary: _selectedSalary,
      education: educationText,
      imageUrl: _selectedImage,
      profession: profession,
      extra: {
        'phone': _phoneController.text.trim(),
        if (_linkedinController.text.trim().isNotEmpty) 'linkedin': _linkedinController.text.trim(),
        if (_isCompany && _websiteController.text.trim().isNotEmpty) 'website': _websiteController.text.trim(),
        if (_isCompany && _cityController.text.trim().isNotEmpty) 'city': _cityController.text.trim(),
        if (_isCompany && _selectedSector != null) 'sector': _selectedSector,
      },
    );

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => FeedScreen(
        name: _nameController.text.trim(),
        profession: profession,
        role: widget.role,
      ),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      Row(
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
                          const Spacer(),
                          Text(
                            _isCompany ? "Perfil de Empresa" : "Perfil de Candidato",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const SizedBox(width: 36),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _progress >= 1.0
                            ? "¡Todo listo para continuar! 🎉"
                            : "${((_progress) * 100).toInt()}% completado",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // FORMULARIO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // FOTO / LOGO (obligatorio)
                    _sectionLabel(
                      _isCompany ? "Logo de la empresa *" : "Foto de perfil *",
                      _isCompany ? Icons.business : Icons.person,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ImagePickerHelper.buildAvatarPicker(
                        imageData: _selectedImage,
                        isCompany: _isCompany,
                        radius: 52,
                        showEditBadge: true,
                        onTap: () async {
                          final picked = await ImagePickerHelper.showPickerSheet(
                            context,
                            currentImage: _selectedImage,
                            isCompany: _isCompany,
                          );
                          if (picked != null) {
                            setState(() => _selectedImage = picked);
                            _updateProgress();
                          }
                        },
                      ),
                    ),
                    if (_submitted && _selectedImage == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            _isCompany ? "El logo es obligatorio" : "La foto es obligatoria",
                            style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // NOMBRE
                    _sectionLabel(_nameLabel, _isCompany ? Icons.business_center : Icons.badge),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      hint: _isCompany ? 'Ej: Acme Corp S.A.' : 'Ej: Fernando Razo',
                      icon: _isCompany ? Icons.business : Icons.person,
                      validator: _validateName,
                      onChanged: (_) => _updateProgress(),
                    ),
                    const SizedBox(height: 24),

                    // TELÉFONO (obligatorio para ambos)
                    _sectionLabel("Teléfono de contacto *", Icons.phone),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Ej: +52 55 1234 5678',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      onChanged: (_) => _updateProgress(),
                    ),
                    const SizedBox(height: 24),

                    // PAÍS / CIUDAD (obligatorio para empresa, opcional candidato)
                    _sectionLabel(
                      _isCompany ? "País / Ciudad *" : "País / Ciudad",
                      Icons.location_on,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _cityController,
                      hint: 'Ej: Ciudad de México, México',
                      icon: Icons.location_on,
                      validator: _isCompany ? _validateCity : null,
                      onChanged: (_) => _updateProgress(),
                    ),
                    const SizedBox(height: 24),

                    // CAMPOS ESPECÍFICOS POR ROL
                    if (!_isCompany) ...[
                      // PROFESIÓN
                      _sectionLabel("Tu Profesión *", Icons.work),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _profController,
                        hint: 'Ej: Flutter Developer',
                        icon: Icons.work,
                        validator: (v) => v == null || v.trim().isEmpty ? 'La profesión es obligatoria' : null,
                        onChanged: (_) => _updateProgress(),
                      ),
                      const SizedBox(height: 24),

                      // ESCOLARIDAD
                      _sectionLabel("Escolaridad *", Icons.school),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: _selectedEducation,
                        hint: 'Selecciona tu nivel',
                        icon: Icons.school,
                        items: _educationLevels,
                        errorText: _submitted && _selectedEducation == null ? 'Selecciona tu escolaridad' : null,
                        onChanged: (val) {
                          setState(() {
                            _selectedEducation = val;
                            if (val != 'Licenciatura+') _selectedCareer = null;
                          });
                          _updateProgress();
                        },
                      ),
                      if (_selectedEducation == 'Licenciatura+') ...[
                        const SizedBox(height: 16),
                        _buildDropdown(
                          value: _selectedCareer,
                          hint: 'Selecciona tu carrera',
                          icon: Icons.menu_book,
                          items: _careerOptions,
                          errorText: _submitted && _selectedCareer == null ? 'Selecciona tu carrera' : null,
                          onChanged: (val) {
                            setState(() => _selectedCareer = val);
                            _updateProgress();
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // LINKEDIN (opcional candidato)
                      _sectionLabel("LinkedIn (opcional)", Icons.link),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _linkedinController,
                        hint: 'https://linkedin.com/in/tu-perfil',
                        icon: Icons.link,
                        keyboardType: TextInputType.url,
                        validator: _validateLinkedin,
                        onChanged: (_) => _updateProgress(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_isCompany) ...[
                      // SECTOR (opcional empresa)
                      _sectionLabel("Sector / Industria (opcional)", Icons.category),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        value: _selectedSector,
                        hint: 'Selecciona el sector',
                        icon: Icons.category,
                        items: _sectorOptions,
                        onChanged: (val) => setState(() => _selectedSector = val),
                      ),
                      const SizedBox(height: 24),

                      // SITIO WEB (opcional empresa)
                      _sectionLabel("Sitio web (opcional)", Icons.language),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _websiteController,
                        hint: 'https://tuempresa.com',
                        icon: Icons.language,
                        keyboardType: TextInputType.url,
                        validator: _validateWebsite,
                        onChanged: (_) => _updateProgress(),
                      ),
                      const SizedBox(height: 24),

                      // LINKEDIN EMPRESA (opcional)
                      _sectionLabel("LinkedIn de la empresa (opcional)", Icons.link),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _linkedinController,
                        hint: 'https://linkedin.com/company/tu-empresa',
                        icon: Icons.link,
                        keyboardType: TextInputType.url,
                        validator: _validateLinkedin,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 24),
                    ],

                    // SALARIO (ambos)
                    _sectionLabel(_salaryLabel, Icons.monetization_on),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _selectedSalary,
                      hint: _isCompany ? 'Rango salarial ofrecido' : 'Expectativa salarial mensual',
                      icon: Icons.monetization_on,
                      items: _salaryOptions,
                      errorText: _submitted && _selectedSalary == null ? 'Selecciona una opción' : null,
                      onChanged: (val) {
                        setState(() => _selectedSalary = val);
                        _updateProgress();
                      },
                    ),
                    const SizedBox(height: 24),

                    // BIO
                    _sectionLabel(_bioLabel, Icons.edit_note),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      onChanged: (_) => _updateProgress(),
                      validator: _validateBio,
                      maxLines: 4,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: _isCompany
                            ? 'Describe tu empresa, cultura y lo que ofrecen...'
                            : 'Cuéntanos sobre ti, tu experiencia y objetivos...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.edit_note, color: Colors.blue),
                        ),
                        helperText: "Mínimo 20 caracteres",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // BOTÓN
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _progress >= 1.0 ? const Color(0xFF1565C0) : Colors.grey[300],
                          foregroundColor: _progress >= 1.0 ? Colors.white : Colors.grey[500],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _handleSubmit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _progress >= 1.0 ? "¡COMENZAR!" : "FINALIZAR REGISTRO",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "* Campos obligatorios",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGETS HELPERS ───────────────────────────────────────────────────────
  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? errorText,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
      ),
      hint: Text(hint),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}