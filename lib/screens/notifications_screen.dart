import 'package:flutter/material.dart';
import '../widgets/shimmer_image.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

enum NotificationType { match, message, rating, vacancy }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: m['id'] ?? '',
    type: NotificationType.values.firstWhere(
      (t) => t.name == m['type'], orElse: () => NotificationType.message),
    title: m['title'] ?? '',
    subtitle: m['subtitle'] ?? '',
    imageUrl: m['imageUrl'] ?? '',
    time: DateTime.tryParse(m['time'] ?? '') ?? DateTime.now(),
    isRead: m['isRead'] ?? false,
  );
}

// ── BANNER FLOTANTE ──────────────────────────────────────────────────────────

class NotificationBanner extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();

    // Auto-dismiss tras 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.notification.type) {
      case NotificationType.match: return const Color(0xFF1565C0);
      case NotificationType.message: return const Color(0xFF00897B);
      case NotificationType.rating: return const Color(0xFFF57C00);
      case NotificationType.vacancy: return const Color(0xFF6A1B9A);
    }
  }

  IconData get _icon {
    switch (widget.notification.type) {
      case NotificationType.match: return Icons.handshake_rounded;
      case NotificationType.message: return Icons.chat_bubble_rounded;
      case NotificationType.rating: return Icons.star_rounded;
      case NotificationType.vacancy: return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: () { _dismiss(); widget.onTap?.call(); },
          onVerticalDragEnd: (d) { if (d.primaryVelocity! < 0) _dismiss(); },
          child: Container(
            margin: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16, right: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _color.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(_icon, color: _color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.notification.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(widget.notification.subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PANTALLA DE NOTIFICACIONES ───────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  final List<AppNotification> notifications;
  final VoidCallback? onMarkAllRead;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    this.onMarkAllRead,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.notifications);
    // Marcar todas como leídas
    for (final n in _notifications) { n.isRead = true; }
    widget.onMarkAllRead?.call();
    _persistReadState();
  }

  Future<void> _persistReadState() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await FirestoreService.markAllNotificationsRead(uid);
  }

  void _remove(AppNotification n) {
    setState(() => _notifications.remove(n));
    final uid = AuthService.currentUser?.uid;
    if (uid != null) FirestoreService.deleteNotification(uid, n.id);
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Ahora";
    if (diff.inMinutes < 60) return "hace ${diff.inMinutes} min";
    if (diff.inHours < 24) return "hace ${diff.inHours}h";
    if (diff.inDays == 1) return "ayer";
    return "hace ${diff.inDays}d";
  }

  // Agrupa notificaciones en secciones
  Map<String, List<AppNotification>> _grouped() {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final week = <AppNotification>[];
    final older = <AppNotification>[];

    for (final n in _notifications) {
      final diff = now.difference(n.time);
      if (diff.inHours < 24) today.add(n);
      else if (diff.inHours < 48) yesterday.add(n);
      else if (diff.inDays < 7) week.add(n);
      else older.add(n);
    }

    return {
      if (today.isNotEmpty) 'Hoy': today,
      if (yesterday.isNotEmpty) 'Ayer': yesterday,
      if (week.isNotEmpty) 'Esta semana': week,
      if (older.isNotEmpty) 'Anteriores': older,
    };
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();

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
                  bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Notificaciones",
                              style: TextStyle(color: Colors.white, fontSize: 24,
                                  fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Text(
                            _notifications.isEmpty
                                ? "Todo al día"
                                : "${_notifications.length} notificaciones",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (_notifications.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() {
                            final uid = AuthService.currentUser?.uid;
                            if (uid != null) FirestoreService.deleteAllNotifications(uid);
                            _notifications.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text("Limpiar todo",
                                style: TextStyle(color: Colors.white, fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // CONTENIDO
          if (_notifications.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (final entry in groups.entries) ...[
                    _groupLabel(entry.key),
                    ...entry.value.map((n) => _buildTile(n)),
                    const SizedBox(height: 8),
                  ]
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _groupLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.grey[500], letterSpacing: 0.8)),
  );

  Widget _buildTile(AppNotification n) {
    final color = _colorFor(n.type);
    final icon = _iconFor(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade100, borderRadius: BorderRadius.circular(18)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => _remove(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: n.isRead ? null : Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey[200],
                child: ShimmerAvatar(imageUrl: n.imageUrl, radius: 24),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5)),
                  child: Icon(icon, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(child: Text(n.title,
                  style: TextStyle(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                      fontSize: 14, color: Colors.black87))),
              if (!n.isRead)
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4)),
                const SizedBox(height: 4),
                Text(_timeAgo(n.time),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400],
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFor(NotificationType t) {
    switch (t) {
      case NotificationType.match: return const Color(0xFF1565C0);
      case NotificationType.message: return const Color(0xFF00897B);
      case NotificationType.rating: return const Color(0xFFF57C00);
      case NotificationType.vacancy: return const Color(0xFF6A1B9A);
    }
  }

  IconData _iconFor(NotificationType t) {
    switch (t) {
      case NotificationType.match: return Icons.handshake_rounded;
      case NotificationType.message: return Icons.chat_bubble_rounded;
      case NotificationType.rating: return Icons.star_rounded;
      case NotificationType.vacancy: return Icons.work_rounded;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.07), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none, size: 64, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          const Text("Sin notificaciones",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text("Aquí aparecerán tus matches,\nmensajes y valoraciones.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}