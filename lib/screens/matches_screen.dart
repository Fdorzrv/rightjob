import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';
import '../widgets/shimmer_image.dart';
import 'notifications_screen.dart';

class MatchesScreen extends StatefulWidget {
  final List<JobMatch> matches; // mantenido por compatibilidad
  final Function(String name, String imageUrl, String type)? onMessageSent;

  const MatchesScreen({super.key, this.matches = const [], this.onMessageSent});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<JobMatch> _liveMatches = [];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    // Escuchar Firestore en tiempo real
    FirestoreService.watchMatches().listen((matches) {
      if (mounted) setState(() => _liveMatches = matches);
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<JobMatch> get _allMatches => _liveMatches.isNotEmpty ? _liveMatches : widget.matches;

  List<JobMatch> get _newMatches => _allMatches
      .where((m) => m.hasNewMatch)
      .where((m) => m.name.toLowerCase().contains(_searchQuery))
      .toList();

  List<JobMatch> get _conversations => _allMatches
      .where((m) => !m.hasNewMatch)
      .where((m) => m.name.toLowerCase().contains(_searchQuery))
      .toList();

  int get _totalUnread => _allMatches.fold(0, (sum, m) => sum + m.unreadCount);

  @override
  Widget build(BuildContext context) {
    final String userRole = StorageService.getUserRole() ?? 'candidate';
    final bool isCompany = userRole == 'company';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // HEADER
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
                      const Icon(Icons.handshake, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mis Conexiones",
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                            Text(
                              isCompany ? "Candidatos interesados en tu empresa" : "Empresas que quieren conocerte",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Badge total sin leer
                      if (_totalUnread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_totalUnread sin leer',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _allMatches.isEmpty ? "Sin conexiones" : "${_allMatches.length} conexión${_allMatches.length > 1 ? 'es' : ''}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // BARRA DE BÚSQUEDA
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Buscar conexiones...",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                                child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 18),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_allMatches.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // SECCIÓN: NUEVOS MATCHES
                    if (_newMatches.isNotEmpty) ...[
                      _sectionTitle("🎉 Nuevos Matches", _newMatches.length),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _newMatches.length,
                          itemBuilder: (context, index) => _buildNewMatchBubble(context, _newMatches[index], index),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // SECCIÓN: CONVERSACIONES
                    if (_conversations.isNotEmpty) ...[
                      _sectionTitle("💬 Conversaciones", _conversations.length),
                      const SizedBox(height: 12),
                      ..._conversations.asMap().entries.map((e) =>
                        _buildAnimatedCard(context, e.value, e.key)
                      ),
                    ],

                    // Sin resultados de búsqueda
                    if (_newMatches.isEmpty && _conversations.isEmpty && _searchQuery.isNotEmpty)
                      _buildNoResults(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
      ],
    );
  }

  // Burbuja horizontal para nuevos matches
  Widget _buildNewMatchBubble(BuildContext context, JobMatch match, int index) {
    final Animation<double> anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval(index * 0.1, (index * 0.1 + 0.5).clamp(0.0, 1.0), curve: Curves.elasticOut),
      ),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.scale(
        scale: anim.value,
        child: GestureDetector(
          onTap: () => _openChat(context, match),
          child: Container(
            width: 76,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        ),
                      ),
                      child: ShimmerAvatar(
                        imageUrl: match.imageUrl,
                        radius: 30,
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  match.name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tarjeta de conversación con animación staggered
  Widget _buildAnimatedCard(BuildContext context, JobMatch match, int index) {
    final Animation<double> fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval((index * 0.12).clamp(0.0, 0.8), ((index * 0.12) + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    );
    final Animation<double> slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: Interval((index * 0.12).clamp(0.0, 0.8), ((index * 0.12) + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (_, __) => Opacity(
        opacity: fadeAnim.value,
        child: Transform.translate(
          offset: Offset(0, slideAnim.value),
          child: _buildConversationCard(context, match),
        ),
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, JobMatch match) {
    final bool hasUnread = match.unreadCount > 0;

    return GestureDetector(
      onTap: () => _openChat(context, match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hasUnread ? 0.1 : 0.05),
              blurRadius: hasUnread ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: hasUnread
              ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // AVATAR
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: hasUnread
                        ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                ),
                child: ShimmerAvatar(
                  imageUrl: match.imageUrl,
                  radius: 28,
                ),
              ),
              const SizedBox(width: 14),

              // TEXTO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.name,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.blue[400], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      match.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasUnread ? Colors.black87 : Colors.grey[500],
                        fontSize: 13,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // TRAILING
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(match.time, style: TextStyle(fontSize: 11, color: hasUnread ? Colors.blue : Colors.grey)),
                  const SizedBox(height: 8),
                  if (hasUnread)
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${match.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.blue),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context, JobMatch match) {
    // Marcar como leído ANTES de navegar para evitar flash del badge rojo
    match.hasNewMatch = false;
    match.unreadCount = 0;
    FirestoreService.markMatchAsRead(match.name);
    setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(
        chatPartnerName: match.name,
        chatPartnerImage: match.imageUrl,
        chatPartnerSubtitle: match.subtitle,
        chatPartnerBio: match.bio,
        chatPartnerSalary: match.salary,
        chatPartnerSkills: match.skills,
        chatPartnerPhone: match.phone,
        chatPartnerLinkedin: match.linkedin,
        chatPartnerWebsite: match.website,
        procesoCerrado: match.procesoCerrado,
        rated: match.rated,
        onMessageSent: (type) => widget.onMessageSent?.call(match.name, match.imageUrl, type),
      )),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("Sin resultados para \"$_searchQuery\"",
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.06), shape: BoxShape.circle),
              child: Icon(Icons.forum, size: 72, color: Colors.blue[200]),
            ),
            const SizedBox(height: 24),
            const Text("Sin conexiones aún",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(
              "Desliza a la derecha en el feed para conectar con perfiles que te interesen.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}