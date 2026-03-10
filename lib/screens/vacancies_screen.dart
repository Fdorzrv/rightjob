import 'package:flutter/material.dart';
import '../models/vacancy_model.dart';
import '../services/firestore_service.dart';
import 'post_job_screen.dart';
import 'vacancy_detail_screen.dart';

class VacanciesScreen extends StatefulWidget {
  const VacanciesScreen({super.key});

  @override
  State<VacanciesScreen> createState() => _VacanciesScreenState();
}

class _VacanciesScreenState extends State<VacanciesScreen> {
  String _filter = 'all'; // all | active | closed

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
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text("Mis Vacantes",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const PostJobScreen()));
                              if (result == true && mounted) setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text("Nueva", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Filtros
                      Row(
                        children: [
                          _filterChip('Todas', 'all'),
                          const SizedBox(width: 8),
                          _filterChip('Activas', 'active'),
                          const SizedBox(width: 8),
                          _filterChip('Cerradas', 'closed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // LISTA
          StreamBuilder<List<Vacancy>>(
            stream: FirestoreService.watchMyVacancies(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final all = snap.data ?? [];
              final vacancies = _filter == 'all'
                  ? all
                  : all.where((v) => v.status == _filter).toList();

              if (vacancies.isEmpty) {
                return SliverFillRemaining(child: _buildEmpty());
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildVacancyCard(vacancies[i]),
                    ),
                    childCount: vacancies.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? const Color(0xFF1565C0) : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            )),
      ),
    );
  }

  Widget _buildVacancyCard(Vacancy v) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => VacancyDetailScreen(vacancy: v))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la tarjeta
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: v.isActive
                    ? const Color(0xFF1565C0).withValues(alpha: 0.05)
                    : Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text("${v.sector} • ${v.city}",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: v.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      v.isActive ? "Activa" : "Cerrada",
                      style: TextStyle(
                        color: v.isActive ? Colors.green : Colors.grey,
                        fontSize: 11, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats rápidas
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _quickStat(Icons.visibility_outlined, v.stats.views.toString(), "Vistas", Colors.blue),
                  _dividerV(),
                  _quickStat(Icons.thumb_up_alt_outlined, v.stats.swipes.toString(), "Swipes", Colors.teal),
                  _dividerV(),
                  _quickStat(Icons.handshake_outlined, v.stats.matches.toString(), "Matches", Colors.green),
                  _dividerV(),
                  _quickStat(Icons.people_outline, v.stats.inProcess.toString(), "En proceso", Colors.orange),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.monetization_on_outlined, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(v.salary, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const Spacer(),
                  Text("Ver detalle →",
                      style: TextStyle(color: const Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _dividerV() => Container(width: 1, height: 40, color: Colors.grey[200]);

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(_filter == 'all' ? "Aún no has publicado vacantes" : "No hay vacantes $_filter",
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            const SizedBox(height: 8),
            Text("Toca '+ Nueva' para publicar tu primera vacante",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}