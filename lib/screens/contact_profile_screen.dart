import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../widgets/shimmer_image.dart';

class ContactProfileScreen extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final String subtitle;
  final String? bio;
  final String? salary;
  final List<String> skills;
  final VoidCallback? onSendMessage;
  // Datos de contacto — solo visibles tras match
  final String? phone;
  final String? linkedin;
  final String? website;

  const ContactProfileScreen({
    super.key,
    required this.name,
    this.imageUrl,
    required this.subtitle,
    this.bio,
    this.salary,
    this.skills = const [],
    this.onSendMessage,
    this.phone,
    this.linkedin,
    this.website,
  });

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  late bool _isBlocked;
  Map<String, dynamic>? _ratingSummary;

  @override
  void initState() {
    super.initState();
    _isBlocked = StorageService.isUserBlocked(widget.name);
    _loadRating();
  }

  Future<void> _loadRating() async {
    final summary = await FirestoreService.getRatingSummary(widget.name);
    if (mounted) setState(() => _ratingSummary = summary);
  }

  void _toggleBlock() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isBlocked ? "Desbloquear usuario" : "Bloquear usuario",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _isBlocked
              ? "¿Deseas desbloquear a ${widget.name}?"
              : "¿Estás seguro de que deseas bloquear a ${widget.name}? No podrás recibir mensajes de esta persona.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBlocked ? Colors.blue : Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              if (_isBlocked) {
                StorageService.unblockUser(widget.name);
              } else {
                StorageService.blockUser(widget.name);
              }
              setState(() => _isBlocked = !_isBlocked);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBlocked
                      ? "${widget.name} bloqueado"
                      : "${widget.name} desbloqueado"),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: _isBlocked ? Colors.red[400] : Colors.green[600],
                ),
              );
            },
            child: Text(_isBlocked ? "Desbloquear" : "Bloquear"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompany = StorageService.getUserRole() == 'company';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // HEADER CON FOTO
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _toggleBlock,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isBlocked ? Icons.block : Icons.more_vert,
                      color: _isBlocked ? Colors.red[300] : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto o degradado
                  widget.imageUrl != null
                      ? ShimmerImage(
                          url: widget.imageUrl!,
                          fit: BoxFit.cover,
                          fallback: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                            ),
                          ),
                        ),
                  // Degradado inferior
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Nombre y subtítulo
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.block, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text("Bloqueado", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        Text(
                          widget.name,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
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

                  // BIO
                  if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                    _sectionTitle(Icons.person, "Sobre mí"),
                    const SizedBox(height: 10),
                    _card(
                      child: Text(
                        widget.bio!,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SALARIO
                  if (widget.salary != null && widget.salary!.isNotEmpty) ...[
                    _sectionTitle(Icons.payments, isCompany ? "Expectativa Salarial" : "Salario Ofrecido"),
                    const SizedBox(height: 10),
                    _card(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.attach_money, color: Colors.green, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCompany ? "Expectativa mensual" : "Salario mensual",
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              Text(
                                widget.salary!,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SKILLS
                  if (widget.skills.isNotEmpty) ...[
                    _sectionTitle(Icons.star, "Habilidades"),
                    const SizedBox(height: 10),
                    _card(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.skills.map((skill) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // DATOS DE CONTACTO — solo visibles tras match
                  if (widget.phone != null || widget.linkedin != null || widget.website != null) ...[
                    _sectionTitle(Icons.verified_user, "Datos de Contacto"),
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open, size: 13, color: Colors.green[600]),
                          const SizedBox(width: 6),
                          Text(
                            "Visibles por tu match",
                            style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    _card(
                      child: Column(
                        children: [
                          if (widget.phone != null) ...[
                            _contactTile(Icons.phone, "Teléfono", widget.phone!),
                          ],
                          if (widget.phone != null && (widget.linkedin != null || widget.website != null))
                            const Divider(height: 20),
                          if (widget.linkedin != null) ...[
                            _contactTile(Icons.link, "LinkedIn", widget.linkedin!),
                          ],
                          if (widget.linkedin != null && widget.website != null)
                            const Divider(height: 20),
                          if (widget.website != null) ...[
                            _contactTile(Icons.language, "Sitio web", widget.website!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // BOTÓN CONTACTAR
                  if (!_isBlocked) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSendMessage?.call();
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text(
                          "Enviar mensaje",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _toggleBlock,
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text("Bloquear usuario", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _toggleBlock,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text("Desbloquear usuario", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  if (_ratingSummary != null) ...[
                    const SizedBox(height: 20),
                    _buildRatingSection(),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _contactTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    final avg = (_ratingSummary!['avgTotal'] as num?)?.toDouble() ?? 0;
    final total = _ratingSummary!['totalReviews'] as int? ?? 0;
    final avgCom = (_ratingSummary!['avgComunicacion'] as num?)?.toDouble() ?? 0;
    final avgHon = (_ratingSummary!['avgHonestidad'] as num?)?.toDouble() ?? 0;
    final avgPro = (_ratingSummary!['avgProfesionalismo'] as num?)?.toDouble() ?? 0;

    Color avgColor = avg >= 4 ? Colors.green : avg >= 2.5 ? Colors.orange : Colors.red;

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
          _sectionTitle(Icons.star_rounded, "Valoraciones"),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: avgColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(avg.toStringAsFixed(1),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: avgColor)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) => Icon(
                        i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xFFFFB300), size: 14,
                      )),
                    ),
                    const SizedBox(height: 2),
                    Text("$total reseña${total == 1 ? '' : 's'}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _ratingBar("Comunicación", avgCom),
                    const SizedBox(height: 8),
                    _ratingBar("Honestidad", avgHon),
                    const SizedBox(height: 8),
                    _ratingBar("Profesionalismo", avgPro),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, double value) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 5,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= 4 ? Colors.green : value >= 2.5 ? Colors.orange : Colors.red,
              ),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
      ],
    );
  }
}