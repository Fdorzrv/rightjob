import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await FirestoreService.getMyStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = StorageService.getUserRole() == 'company';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                          const SizedBox(width: 16),
                          const Text("Mis Estadísticas",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isCompany ? "Rendimiento de tu empresa" : "Tu actividad en RightJob",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),

                  // Tarjetas principales
                  _buildPrimaryGrid(),
                  const SizedBox(height: 24),

                  // Sección tasa de match
                  _buildMatchRateCard(),
                  const SizedBox(height: 24),

                  // Actividad reciente
                  _buildActivityCard(),
                  const SizedBox(height: 30),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryGrid() {
    final matches = _stats['totalMatches'] as int? ?? 0;
    final swipesReceived = _stats['swipesReceived'] as int? ?? 0;

    return Row(
      children: [
        Expanded(child: _statCard(
          icon: Icons.handshake_rounded,
          label: "Matches totales",
          value: matches.toString(),
          color: Colors.teal,
          subtitle: "conexiones logradas",
        )),
        const SizedBox(width: 14),
        Expanded(child: _statCard(
          icon: Icons.thumb_up_alt_rounded,
          label: "Swipes recibidos",
          value: swipesReceived.toString(),
          color: const Color(0xFF1565C0),
          subtitle: "interesados en ti",
        )),
      ],
    );
  }

  Widget _buildMatchRateCard() {
    final matches = _stats['totalMatches'] as int? ?? 0;
    final swipesReceived = _stats['swipesReceived'] as int? ?? 0;
    final rate = swipesReceived > 0 ? (matches / swipesReceived * 100) : 0.0;
    final rateStr = rate.toStringAsFixed(1);

    Color rateColor = rate >= 50 ? Colors.green : rate >= 25 ? Colors.orange : Colors.red;
    String rateLabel = rate >= 50 ? "¡Excelente!" : rate >= 25 ? "Buen ritmo" : "Sigue intentando";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: rateColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.percent_rounded, color: rateColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text("Tasa de match",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(rateLabel,
                  style: TextStyle(color: rateColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$rateStr%",
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: rateColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (rate / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(rateColor),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("$matches matches de $swipesReceived swipes recibidos",
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final sentMessages = _stats['messagesSent'] as int? ?? 0;
    final receivedMessages = _stats['messagesReceived'] as int? ?? 0;
    final rating = (_stats['myRating'] as num?)?.toDouble();
    final ratingCount = _stats['myRatingCount'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 10),
            const Text("Actividad general",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 18),
          _activityRow(Icons.send_rounded, "Mensajes enviados", sentMessages.toString(), Colors.blue),
          const Divider(height: 20),
          _activityRow(Icons.inbox_rounded, "Mensajes recibidos", receivedMessages.toString(), Colors.teal),
          if (rating != null) ...[
            const Divider(height: 20),
            _activityRow(Icons.star_rounded, "Tu valoración promedio",
                "${rating.toStringAsFixed(1)} ⭐ ($ratingCount reseñas)", Colors.amber),
          ],
        ],
      ),
    );
  }

  Widget _activityRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}