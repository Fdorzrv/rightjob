import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../helpers/image_picker_helper.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';
import 'stats_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userProfession;

  const SettingsScreen({
    super.key,
    required this.userName,
    required this.userProfession,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _userRole;
  bool _isEditing = false;
  bool _loadingProfile = true;

  late TextEditingController _nameController;
  late TextEditingController _profController;
  late TextEditingController _bioController;
  late TextEditingController _imageController;
  late TextEditingController _phoneController;
  late TextEditingController _linkedinController;
  late TextEditingController _websiteController;
  late TextEditingController _cityController;
  String? _selectedSalary;
  String? _selectedEducation;
  String? _selectedCareer;
  String? _selectedSector;

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

  final List<String> _salaryOptions = List.generate(20, (index) {
    final value = (index + 1) * 5000;
    return "USD \$${value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},',
    )}";
  });

  @override
  void initState() {
    super.initState();
    _userRole = StorageService.getUserRole() ?? 'candidate';
    _nameController = TextEditingController(text: StorageService.getName() ?? widget.userName);
    _profController = TextEditingController(text: StorageService.getProfession() ?? widget.userProfession);
    _bioController = TextEditingController(text: StorageService.getBio() ?? '');
    _imageController = TextEditingController(text: StorageService.getImageUrl() ?? '');
    _phoneController = TextEditingController(text: StorageService.getPhone() ?? '');
    _linkedinController = TextEditingController(text: StorageService.getLinkedin() ?? '');
    _websiteController = TextEditingController(text: StorageService.getWebsite() ?? '');
    _cityController = TextEditingController(text: StorageService.getCity() ?? '');
    _selectedSalary = StorageService.getSalary();
    final String? savedEducation = StorageService.getEducation();
    if (savedEducation != null) {
      if (savedEducation.contains(' · ')) {
        final parts = savedEducation.split(' · ');
        _selectedEducation = parts[0];
        _selectedCareer = parts[1];
      } else {
        _selectedEducation = savedEducation;
      }
    }

    // Recargar desde Firestore para asegurar datos más recientes
    _loadProfileFromFirestore();
  }

  Future<void> _loadProfileFromFirestore() async {
    await AuthService.loadProfileToStorage();
    if (!mounted) return;
    setState(() {
      _nameController.text = StorageService.getName() ?? widget.userName;
      _profController.text = StorageService.getProfession() ?? widget.userProfession;
      _bioController.text = StorageService.getBio() ?? '';
      _imageController.text = StorageService.getImageUrl() ?? '';
      _phoneController.text = StorageService.getPhone() ?? '';
      _linkedinController.text = StorageService.getLinkedin() ?? '';
      _websiteController.text = StorageService.getWebsite() ?? '';
      _cityController.text = StorageService.getCity() ?? '';
      _selectedSalary = StorageService.getSalary();
      final String? edu = StorageService.getEducation();
      if (edu != null) {
        if (edu.contains(' · ')) {
          final parts = edu.split(' · ');
          _selectedEducation = parts[0];
          _selectedCareer = parts[1];
        } else {
          _selectedEducation = edu;
        }
      }
      _loadingProfile = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _profController.dispose();
    _bioController.dispose();
    _imageController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _websiteController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    String? educationText;
    if (_selectedEducation != null) {
      educationText = _selectedEducation == 'Licenciatura+' && _selectedCareer != null
          ? 'Licenciatura+ · $_selectedCareer'
          : _selectedEducation;
    }
    StorageService.saveFullProfile(
      name: _nameController.text,
      profession: _profController.text,
      role: _userRole,
      bio: _bioController.text,
      salary: _userRole == 'candidate' ? _selectedSalary : null,
      imageUrl: _imageController.text.isNotEmpty ? _imageController.text : null,
      education: _userRole == 'candidate' ? educationText : null,
    );

    // Sincronizar con Firestore
    if (_phoneController.text.trim().isNotEmpty) StorageService.savePhone(_phoneController.text.trim());
    if (_linkedinController.text.trim().isNotEmpty) StorageService.saveLinkedin(_linkedinController.text.trim());
    if (_websiteController.text.trim().isNotEmpty) StorageService.saveWebsite(_websiteController.text.trim());
    if (_cityController.text.trim().isNotEmpty) StorageService.saveCity(_cityController.text.trim());

    AuthService.saveFullProfileToFirestore(
      name: _nameController.text,
      role: _userRole,
      bio: _bioController.text,
      salary: _selectedSalary,
      imageUrl: _imageController.text.isNotEmpty ? _imageController.text : null,
      education: _userRole == 'candidate' ? educationText : null,
      profession: _profController.text,
      extra: {
        if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
        if (_linkedinController.text.trim().isNotEmpty) 'linkedin': _linkedinController.text.trim(),
        if (_websiteController.text.trim().isNotEmpty) 'website': _websiteController.text.trim(),
        if (_cityController.text.trim().isNotEmpty) 'city': _cityController.text.trim(),
        if (_selectedSector != null) 'sector': _selectedSector,
      },
    );
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white),
          SizedBox(width: 10),
          Text("Perfil actualizado correctamente"),
        ]),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro que quieres cerrar sesión?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              StorageService.clearAll();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompany = _userRole == 'company';
    final String imageUrl = _imageController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // HEADER CON DEGRADADO
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
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    children: [
                      // Top row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Text(
                            _isEditing ? "Editar Perfil" : "Ajustes",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => _isEditing ? _saveProfile() : setState(() => _isEditing = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isEditing ? "Guardar" : "Editar",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // AVATAR
                      ImagePickerHelper.buildAvatarPicker(
                        imageData: _imageController.text.isNotEmpty ? _imageController.text : null,
                        isCompany: isCompany,
                        radius: 48,
                        showEditBadge: true,
                        onTap: () async {
                          final picked = await ImagePickerHelper.showPickerSheet(
                            context,
                            currentImage: _imageController.text.isNotEmpty ? _imageController.text : null,
                            isCompany: isCompany,
                          );
                          if (picked != null) {
                            setState(() => _imageController.text = picked);
                            // Guardar inmediatamente sin esperar al botón Guardar
                            StorageService.saveImageUrl(picked);
                            // Persistir por UID para sobrevivir cierre de sesión
                            final uid = AuthService.currentUser?.uid;
                            if (uid != null) StorageService.saveImageForUid(uid, picked);
                            AuthService.saveFullProfileToFirestore(
                              name: _nameController.text,
                              role: _userRole,
                              imageUrl: picked,
                              bio: _bioController.text,
                              salary: _selectedSalary,
                              profession: _profController.text,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _loadingProfile
                          ? Container(
                              width: 140, height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            )
                          : Text(
                              _nameController.text.isNotEmpty ? _nameController.text : "Sin nombre",
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                      const SizedBox(height: 4),
                      Text(
                        _profController.text.isNotEmpty ? _profController.text : "",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCompany ? "Empresa" : "Candidato",
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  if (_isEditing) ...[
                    _sectionLabel("INFORMACIÓN"),
                    _buildCard(
                      child: Column(
                        children: [
                          _buildTextField(controller: _nameController, label: isCompany ? "Nombre de la Empresa" : "Nombre Completo", icon: isCompany ? Icons.business : Icons.person),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _phoneController, label: "Teléfono de contacto", icon: Icons.phone),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _cityController, label: "País / Ciudad", icon: Icons.location_on),
                          const SizedBox(height: 14),
                          if (!isCompany) ...[
                            _buildTextField(controller: _profController, label: "Profesión", icon: Icons.work_outline),
                            const SizedBox(height: 14),
                          ],
                          _buildTextField(controller: _bioController, label: isCompany ? "Descripción de la Empresa" : "Bio / Sobre ti", icon: Icons.edit_note, maxLines: 3),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _linkedinController, label: isCompany ? "LinkedIn de la empresa" : "LinkedIn (URL)", icon: Icons.link),
                          if (isCompany) ...[
                            const SizedBox(height: 14),
                            _buildTextField(controller: _websiteController, label: "Sitio web", icon: Icons.language),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _selectedSector,
                              hint: const Text("Sector / Industria"),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.category, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                              ),
                              items: ['Tecnología / Software','Finanzas / Fintech','Salud / Medtech','Educación / Edtech','E-commerce / Retail','Logística / Supply Chain','Medios / Entretenimiento','Energía / Cleantech','Turismo / Hospitalidad','Manufactura / Industria','Consultoría','Otro']
                                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) => setState(() => _selectedSector = val),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _selectedSalary,
                              hint: const Text("Rango Salarial Ofrecido"),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.monetization_on, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                              ),
                              items: _salaryOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) => setState(() => _selectedSalary = val),
                            ),
                          ],
                          if (!isCompany) ...[
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _selectedSalary,
                              hint: const Text("Expectativa Salarial"),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.monetization_on, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                              ),
                              items: _salaryOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (val) => setState(() => _selectedSalary = val),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _selectedEducation,
                              hint: const Text("Escolaridad"),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.school, color: Colors.blue),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                              ),
                              items: _educationLevels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (val) => setState(() {
                                _selectedEducation = val;
                                if (val != 'Licenciatura+') _selectedCareer = null;
                              }),
                            ),
                            if (_selectedEducation == 'Licenciatura+') ...[
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                value: _selectedCareer,
                                hint: const Text("Selecciona tu carrera"),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.menu_book, color: Colors.blue),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                                ),
                                items: _careerOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) => setState(() => _selectedCareer = val),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.check),
                        label: const Text("Guardar Cambios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ] else ...[
                    _sectionLabel("MI PERFIL"),
                    _buildCard(
                      child: Column(
                        children: [
                          _infoTile(icon: isCompany ? Icons.business : Icons.person, title: isCompany ? "Nombre de la Empresa" : "Nombre Completo", value: _nameController.text.isNotEmpty ? _nameController.text : "—"),
                          _divider(),
                          _infoTile(icon: Icons.phone, title: "Teléfono", value: _phoneController.text.isNotEmpty ? _phoneController.text : "—"),
                          _divider(),
                          _infoTile(icon: Icons.location_on, title: "País / Ciudad", value: _cityController.text.isNotEmpty ? _cityController.text : "—"),
                          _divider(),
                          _infoTile(icon: Icons.work_outline, title: isCompany ? "Industria / Sector" : "Profesión", value: _profController.text.isNotEmpty ? _profController.text : "—"),
                          _divider(),
                          _infoTile(icon: Icons.edit_note, title: isCompany ? "Descripción" : "Bio", value: _bioController.text.isNotEmpty ? _bioController.text : "—"),
                          _divider(),
                          _infoTile(icon: Icons.link, title: "LinkedIn", value: _linkedinController.text.isNotEmpty ? _linkedinController.text : "—"),
                          if (isCompany) ...[
                            _divider(),
                            _infoTile(icon: Icons.language, title: "Sitio web", value: _websiteController.text.isNotEmpty ? _websiteController.text : "—"),
                            _divider(),
                            _infoTile(icon: Icons.monetization_on, title: "Rango Salarial", value: _selectedSalary ?? "—"),
                          ],
                          if (!isCompany) ...[
                            _divider(),
                            _infoTile(icon: Icons.monetization_on, title: "Expectativa Salarial", value: _selectedSalary ?? "—"),
                            _divider(),
                            _infoTile(
                              icon: Icons.school,
                              title: "Escolaridad",
                              value: _selectedEducation == null
                                  ? "—"
                                  : _selectedEducation == 'Licenciatura+' && _selectedCareer != null
                                      ? 'Licenciatura+ · $_selectedCareer'
                                      : _selectedEducation!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel("ESTADÍSTICAS"),
                    _buildCard(
                      child: _actionTile(
                        icon: Icons.bar_chart_rounded,
                        title: "Ver mis estadísticas",
                        subtitle: "Matches, swipes, tasa de match y más",
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const StatsScreen())),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel("LEGAL"),
                    _buildCard(
                      child: Column(
                        children: [
                          _actionTile(icon: Icons.security, title: "Aviso de Privacidad", onTap: () => _showPrivacyNotice(context)),
                          _divider(),
                          _actionTile(icon: Icons.gavel, title: "Términos y Condiciones", onTap: () => _showTerms(context)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // CERRAR SESIÓN
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text("CERRAR SESIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100);

  Widget _infoTile({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.blue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ],
            )),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return TextField(
      controller: controller, maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
      ),
    );
  }

  void _showPrivacyNotice(BuildContext context) {
    _showLegalDialog(
      context: context,
      title: "Aviso de Privacidad",
      icon: Icons.security,
      content: "En RightJob nos comprometemos a proteger tu información personal.\n\n"
          "• Recopilamos solo los datos necesarios para conectar candidatos con empresas.\n\n"
          "• Tu información nunca es vendida a terceros.\n\n"
          "• Puedes solicitar la eliminación de tus datos en cualquier momento desde Ajustes > Cerrar Sesión.\n\n"
          "• Los datos se almacenan con cifrado y estándares de seguridad internacionales.\n\n"
          "Para más información escríbenos a privacidad@rightjob.mx",
    );
  }

  void _showTerms(BuildContext context) {
    _showLegalDialog(
      context: context,
      title: "Términos y Condiciones",
      icon: Icons.gavel,
      content: "Al usar RightJob aceptas los siguientes términos:\n\n"
          "1. USO DE LA PLATAFORMA\n"
          "RightJob es una plataforma de conexión laboral. El uso indebido puede resultar en la suspensión de tu cuenta.\n\n"
          "2. VERACIDAD DE LA INFORMACIÓN\n"
          "Eres responsable de que la información en tu perfil sea verídica y actualizada.\n\n"
          "3. PROPIEDAD INTELECTUAL\n"
          "El contenido, diseño y marca de RightJob son propiedad exclusiva de sus creadores.\n\n"
          "4. LIMITACIÓN DE RESPONSABILIDAD\n"
          "RightJob actúa como intermediario y no garantiza la contratación ni la veracidad de las ofertas publicadas.\n\n"
          "5. MODIFICACIONES\n"
          "Nos reservamos el derecho de modificar estos términos con previo aviso.",
    );
  }

  void _showLegalDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Contenido scrolleable
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                ),
              ),
            ),
            // Botón
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Entendido", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}