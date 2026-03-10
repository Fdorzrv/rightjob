import 'package:flutter/material.dart';
import '../models/vacancy_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class VacancyFormScreen extends StatefulWidget {
  final Vacancy? vacancy; // null = nueva vacante

  const VacancyFormScreen({super.key, this.vacancy});

  @override
  State<VacancyFormScreen> createState() => _VacancyFormScreenState();
}

class _VacancyFormScreenState extends State<VacancyFormScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _cityController = TextEditingController();
  final _skillController = TextEditingController();

  String? _selectedSector;
  String? _selectedSalary;
  String _availability = 'Remoto';
  List<String> _skills = [];
  bool _saving = false;

  bool get _isEditing => widget.vacancy != null;

  final _sectors = ['Tecnología / Software','Finanzas / Fintech','Salud / Medtech',
    'Educación / Edtech','E-commerce / Retail','Logística / Supply Chain',
    'Medios / Entretenimiento','Energía / Cleantech','Turismo / Hospitalidad',
    'Manufactura / Industria','Consultoría','Otro'];

  final _salaries = [
    'MXN \$0 - \$10,000','MXN \$10,000 - \$20,000','MXN \$20,000 - \$30,000',
    'MXN \$30,000 - \$40,000','MXN \$40,000 - \$50,000','MXN \$50,000 - \$60,000',
    'MXN \$60,000 - \$70,000','MXN \$70,000 - \$80,000','MXN \$80,000 - \$90,000',
    'MXN \$90,000 - \$100,000','MXN \$100,000 - \$120,000','MXN \$120,000 - \$140,000',
    'MXN \$140,000 - \$160,000','MXN \$160,000 - \$180,000','MXN \$180,000 - \$200,000',
    'MXN \$200,000+',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final v = widget.vacancy!;
      _titleController.text = v.title;
      _descController.text = v.description;
      _cityController.text = v.city;
      _selectedSector = v.sector.isEmpty ? null : v.sector;
      _selectedSalary = v.salary.isEmpty ? null : v.salary;
      _availability = v.availability;
      _skills = List.from(v.skills);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty &&
      _selectedSector != null &&
      _selectedSalary != null;

  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);

    final vacancy = Vacancy(
      id: widget.vacancy?.id ?? '',
      companyUid: StorageService.getUserRole() == 'company'
          ? (widget.vacancy?.companyUid ?? '')
          : '',
      companyName: StorageService.getName() ?? '',
      title: _titleController.text.trim(),
      sector: _selectedSector!,
      salary: _selectedSalary!,
      city: _cityController.text.trim(),
      description: _descController.text.trim(),
      availability: _availability,
      skills: _skills,
      status: widget.vacancy?.status ?? 'active',
      stats: widget.vacancy?.stats,
    );

    await FirestoreService.saveVacancy(vacancy);
    if (mounted) Navigator.pop(context, true);
  }

  void _addSkill() {
    final s = _skillController.text.trim();
    if (s.isNotEmpty && !_skills.contains(s)) {
      setState(() { _skills.add(s); _skillController.clear(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? "Editar vacante" : "Nueva vacante",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isValid && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Guardar",
                    style: TextStyle(
                        color: _isValid ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel("INFORMACIÓN BÁSICA"),
            _card(Column(children: [
              _field(_titleController, "Título del puesto", Icons.work_outline),
              const SizedBox(height: 14),
              _dropdown("Sector / Industria", Icons.category, _sectors, _selectedSector,
                  (v) => setState(() => _selectedSector = v)),
              const SizedBox(height: 14),
              _dropdown("Salario ofrecido", Icons.monetization_on, _salaries, _selectedSalary,
                  (v) => setState(() => _selectedSalary = v)),
              const SizedBox(height: 14),
              _field(_cityController, "Ciudad / Ubicación", Icons.location_on),
            ])),
            const SizedBox(height: 20),

            _sectionLabel("MODALIDAD"),
            _card(_chips(['Remoto', 'Presencial', 'Híbrido'], _availability,
                (v) => setState(() => _availability = v))),
            const SizedBox(height: 20),

            _sectionLabel("DESCRIPCIÓN"),
            _card(_field(_descController, "Describe el puesto, responsabilidades y requisitos...",
                Icons.edit_note, maxLines: 5)),
            const SizedBox(height: 20),

            _sectionLabel("HABILIDADES REQUERIDAS (opcional)"),
            _card(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: TextField(
                    controller: _skillController,
                    decoration: InputDecoration(
                      hintText: "Ej: Flutter, Python, SQL...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _addSkill(),
                  )),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _addSkill,
                    child: const Text("Agregar"),
                  ),
                ]),
                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _skills.map((s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _skills.remove(s)),
                      backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    )).toList(),
                  ),
                ],
              ],
            )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: Colors.grey[500], letterSpacing: 0.8)),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
    ),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) =>
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.blue, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 2)),
        filled: true, fillColor: const Color(0xFFF5F7FA),
      ),
      onChanged: (_) => setState(() {}),
    );

  Widget _dropdown(String hint, IconData icon, List<String> items, String? value,
      void Function(String?) onChanged) =>
    DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue, width: 2)),
        filled: true, fillColor: const Color(0xFFF5F7FA),
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) { onChanged(v); setState(() {}); },
    );

  Widget _chips(List<String> options, String selected, void Function(String) onSelect) =>
    Wrap(
      spacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return ChoiceChip(
          label: Text(o),
          selected: isSelected,
          onSelected: (_) => onSelect(o),
          selectedColor: const Color(0xFF1565C0),
          labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          backgroundColor: Colors.grey[100],
        );
      }).toList(),
    );
}