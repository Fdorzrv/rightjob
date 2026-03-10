import 'package:flutter/material.dart';
import '../models/vacancy_model.dart';
import '../services/firestore_service.dart';
import 'vacancy_form_screen.dart';

class VacancyDetailScreen extends StatefulWidget {
  final Vacancy vacancy;

  const VacancyDetailScreen({super.key, required this.vacancy});

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  late Vacancy _vacancy;
  List<Map<String, dynamic>> _candidates = [];
  bool _loadingCandidates = true;

  @override
  void initState() {
    super.initState();
    _vacancy = widget.vacancy;
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    final candidates = await FirestoreService.getVacancyCandidates(_vacancy.id);
    if (mounted) setState(() { _candidates = candidates; _loadingCandidates = false; });
  }

  Future<void> _toggleStatus() async {
    final isActive = _vacancy.isActive;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isActive ? "Cerrar vacante" : "Reabrir vacante",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isActive
            ? "¿Confirmas que deseas cerrar esta vacante? Dejará de aparecer en el feed."
            : "¿Deseas reactivar esta vacante para que aparezca en el feed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (isActive) {
                await FirestoreService.closeVacancy(_vacancy.id);
              } else {
                await FirestoreService.reopenVacancy(_vacancy.id);
              }
              if (mounted) setState(() {
                _vacancy = Vacancy(
                  id: _vacancy.id, companyUid: _vacancy.companyUid,
                  companyName: _vacancy.companyName, title: _vacancy.title,
                  sector: _vacancy.sector, salary: _vacancy.salary,
                  city: _vacancy.city, description: _vacancy.description,
                  availability: _vacancy.availability, skills: _vacancy.skills,
                  status: isActive ? 'closed' : 'active',
                  stats: _vacancy.stats,
                );
              });
            },
            child: Text(isActive ? "Cerrar" : "Reabrir"),
          ),
        ],
      ),
    );
  }

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
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_vacancy.title,
                                style: const TextStyle(color: Colors.white, fontSize: 16,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                          ),
                          // Editar
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                            onPressed: () async {
                              final result = await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => VacancyFormScreen(vacancy: _vacancy)));
                              if (result == true && mounted) Navigator.pop(context, true);
                            },
                          ),
                          // Cerrar/Reabrir
                          GestureDetector(
                            onTap: _toggleStatus,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _vacancy.isActive
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _vacancy.isActive ? Colors.red : Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _vacancy.isActive ? "Cerrar" : "Reabrir",
                                style: TextStyle(
                                  color: _vacancy.isActive ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold, fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _infoBadge(Icons.category_outlined, _vacancy.sector),
                          const SizedBox(width: 8),
                          _infoBadge(Icons.location_on_outlined, _vacancy.city.isEmpty ? 'Sin ciudad' : _vacancy.city),
                          const SizedBox(width: 8),
                          _infoBadge(Icons.wifi_outlined, _vacancy.availability),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ESTADÍSTICAS
                _sectionTitle(Icons.bar_chart_rounded, "Estadísticas"),
                const SizedBox(height: 12),
                _statsGrid(),
                const SizedBox(height: 24),

                // DESCRIPCIÓN
                _sectionTitle(Icons.description_outlined, "Descripción"),
                const SizedBox(height: 12),
                _card(Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_vacancy.description,
                      style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87)),
                )),
                const SizedBox(height: 24),

                // SALARIO
                _sectionTitle(Icons.monetization_on_outlined, "Salario ofrecido"),
                const SizedBox(height: 12),
                _card(Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_vacancy.salary,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                          color: Color(0xFF1565C0))),
                )),

                // SKILLS
                if (_vacancy.skills.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _sectionTitle(Icons.code_outlined, "Habilidades requeridas"),
                  const SizedBox(height: 12),
                  _card(Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _vacancy.skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 12,
                            color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
                      )).toList(),
                    ),
                  )),
                ],

                // CANDIDATOS
                const SizedBox(height: 24),
                _sectionTitle(Icons.people_outline, "Candidatos con match"),
                const SizedBox(height: 12),
                _buildCandidates(),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final s = _vacancy.stats;
    return Column(
      children: [
        Row(children: [
          Expanded(child: _statCard(Icons.visibility_outlined, s.views.toString(), "Vistas", Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.thumb_up_alt_outlined, s.swipes.toString(), "Swipes", Colors.teal)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard(Icons.handshake_outlined, s.matches.toString(), "Matches", Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.people_outline, s.inProcess.toString(), "En proceso", Colors.orange)),
        ]),
        const SizedBox(height: 12),
        _statCard(Icons.check_circle_outline, s.hired.toString(), "Contratados", Colors.purple, full: true),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color, {bool full = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandidates() {
    if (_loadingCandidates) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_candidates.isEmpty) {
      return _card(Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Icon(Icons.people_outline, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text("Aún no hay candidatos con match",
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ]),
      ));
    }
    return Column(
      children: _candidates.map((c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _card(Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['name'] ?? 'Candidato',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(c['status'] ?? 'Match', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (status) async {
                  await FirestoreService.updateCandidateStatus(_vacancy.id, c['uid'], status);
                  _loadCandidates();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'inProcess',
                      child: Row(children: [Icon(Icons.sync, color: Colors.orange, size: 18), SizedBox(width: 8), Text("En proceso")])),
                  const PopupMenuItem(value: 'hired',
                      child: Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 8), Text("Contratado")])),
                  const PopupMenuItem(value: 'rejected',
                      child: Row(children: [Icon(Icons.cancel, color: Colors.red, size: 18), SizedBox(width: 8), Text("Rechazado")])),
                ],
              ),
            ],
          ),
        )),
      )).toList(),
    );
  }

  Widget _infoBadge(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 12),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    ]),
  );

  Widget _sectionTitle(IconData icon, String title) => Row(children: [
    Icon(icon, size: 18, color: const Color(0xFF1565C0)),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  ]);

  Widget _card(Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
    ),
    child: child,
  );
}