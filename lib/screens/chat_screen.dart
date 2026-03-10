import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/message_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/permission_service.dart';
import 'contact_profile_screen.dart';
import 'rating_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatPartnerName;
  final String? chatPartnerImage;
  final String? chatPartnerSubtitle;
  final String? chatPartnerBio;
  final String? chatPartnerSalary;
  final List<String> chatPartnerSkills;
  final String? chatPartnerPhone;
  final String? chatPartnerLinkedin;
  final String? chatPartnerWebsite;
  final bool procesoCerrado;
  final bool rated;
  final void Function(String type)? onMessageSent;

  const ChatScreen({
    super.key,
    required this.chatPartnerName,
    this.chatPartnerImage,
    this.chatPartnerSubtitle,
    this.chatPartnerBio,
    this.chatPartnerSalary,
    this.chatPartnerSkills = const [],
    this.chatPartnerPhone,
    this.chatPartnerLinkedin,
    this.chatPartnerWebsite,
    this.procesoCerrado = false,
    this.rated = false,
    this.onMessageSent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _inputController;
  late Animation<double> _inputScale;

  bool _isTyping = false;
  bool _hasSentFirstMessage = false;
  bool _isBlocked = false;
  bool _blockChecked = false;
  late bool _procesoCerrado;
  late bool _rated;
  StreamSubscription? _messagesSub;
  bool _partnerIsTyping = false;
  late String _userRole;
  int _autoReplyIndex = 0;
  List<ChatMessage> _messages = [];

  final List<String> _candidateAutoReplies = [
    "Gracias por tu mensaje. ¿Podrías contarme más sobre el puesto?",
    "Me interesa mucho la oportunidad. ¿Cuál sería el siguiente paso?",
    "Perfecto, lo tendré en cuenta. ¿Cuándo podríamos agendar una llamada?",
    "Entendido. Revisaré la información y te confirmo pronto.",
  ];

  final List<String> _companyAutoReplies = [
    "Gracias por tu interés. Tu perfil es muy llamativo para nosotros.",
    "Nos parece un candidato con mucho potencial. ¿Tienes disponibilidad esta semana?",
    "Excelente. Lo comentamos con el equipo de RRHH y te contactamos.",
    "Perfecto. ¿Podrías compartir tu portafolio o CV actualizado?",
  ];

  @override
  void initState() {
    super.initState();
    _userRole = StorageService.getUserRole() ?? 'candidate';
    _procesoCerrado = widget.procesoCerrado;
    _rated = widget.rated;

    // Verificar bloqueo después del primer frame renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {
        _isBlocked = StorageService.isUserBlocked(widget.chatPartnerName);
        _blockChecked = true;
      });
    });

    _inputController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _inputScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _inputController, curve: Curves.easeInOut),
    );

    // Escuchar mensajes en tiempo real desde Firestore
    _messagesSub = FirestoreService.watchMessages(widget.chatPartnerName).listen((msgs) {
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  String _nextAutoReply() {
    final replies = _userRole == 'company' ? _candidateAutoReplies : _companyAutoReplies;
    final reply = replies[_autoReplyIndex % replies.length];
    _autoReplyIndex++;
    return reply;
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    if (_isBlocked) return;

    final text = _controller.text.trim();
    _controller.clear();

    if (!_hasSentFirstMessage) {
      _hasSentFirstMessage = true;
      widget.onMessageSent?.call('text');
    }

    FirestoreService.sendMessage(
      otherName: widget.chatPartnerName,
      text: text,
    );

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    final dataUrl = reader.result as String;
    if (!_hasSentFirstMessage) { _hasSentFirstMessage = true; widget.onMessageSent?.call('image'); }
    await FirestoreService.sendImage(otherName: widget.chatPartnerName, imageData: dataUrl);
    _scrollToBottom();
  }

  Future<void> _pickPdf() async {
    final input = html.FileUploadInputElement()
      ..accept = '.pdf'
      ..click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = reader.result as Uint8List;
    final base64Str = base64Encode(bytes);
    if (!_hasSentFirstMessage) { _hasSentFirstMessage = true; widget.onMessageSent?.call('pdf'); }
    await FirestoreService.sendPdf(otherName: widget.chatPartnerName, pdfBase64: base64Str, fileName: file.name);
    _scrollToBottom();
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Adjuntar archivo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachOption(
                  icon: Icons.image_rounded,
                  label: "Imagen",
                  color: const Color(0xFF1565C0),
                  onTap: () { Navigator.pop(context); _pickImage(); },
                ),
                _attachOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "PDF",
                  color: Colors.red.shade600,
                  onTap: () { Navigator.pop(context); _pickPdf(); },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompany = _userRole == 'company';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(isCompany),
      body: Column(
        children: [
          // Badge match
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.handshake, size: 13, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      "¡Es un Match Profesional!",
                      style: TextStyle(color: Colors.blue[700], fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // MENSAJES
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("¡Di hola! 👋",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                        const SizedBox(height: 8),
                        Text("Sé el primero en enviar un mensaje",
                          style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                      ],
                    ),
                  )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_partnerIsTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return TypingIndicator(isCompany: !isCompany);
                }
                final msg = _messages[index];
                final bool showDate = index == 0 ||
                    _messages[index].time.day != _messages[index - 1].time.day;
                return Column(
                  children: [
                    if (showDate) _buildDateDivider(msg.time),
                    _buildMessageBubble(msg),
                  ],
                );
              },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isCompany) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.blue),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Avatar con foto o ícono
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            ),
            child: widget.chatPartnerImage != null
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(widget.chatPartnerImage!),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      isCompany ? Icons.person : Icons.business,
                      size: 18,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatPartnerName,
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _partnerIsTyping
                      ? Text(
                          "escribiendo...",
                          key: const ValueKey('typing'),
                          style: TextStyle(color: Colors.blue[400], fontSize: 11, fontStyle: FontStyle.italic),
                        )
                      : Row(
                          key: const ValueKey('online'),
                          children: [
                            Container(
                              width: 7, height: 7,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text("En línea", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          onSelected: (value) async {
            switch (value) {
              case 'profile':
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactProfileScreen(
                    name: widget.chatPartnerName,
                    imageUrl: widget.chatPartnerImage,
                    subtitle: widget.chatPartnerSubtitle ?? (_userRole == 'company' ? 'Candidato' : 'Empresa'),
                    bio: widget.chatPartnerBio,
                    salary: widget.chatPartnerSalary,
                    skills: widget.chatPartnerSkills,
                    phone: widget.chatPartnerPhone,
                    linkedin: widget.chatPartnerLinkedin,
                    website: widget.chatPartnerWebsite,
                    onSendMessage: () => Navigator.pop(context),
                  )),
                );
                if (mounted) setState(() {}); // Rebuild al regresar
                break;
              case 'close_proceso':
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text("Cerrar proceso", style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text("¿Confirmas que el proceso con este contacto ha finalizado? A continuación podrás valorarlo."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirestoreService.closeProceso(widget.chatPartnerName);
                          if (!mounted) return;
                          setState(() => _procesoCerrado = true);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RatingScreen(
                              contactName: widget.chatPartnerName,
                              contactImageUrl: widget.chatPartnerImage,
                              contactSubtitle: widget.chatPartnerSubtitle ?? (_userRole == 'company' ? 'Candidato' : 'Empresa'),
                            )),
                          );
                          if (result == true && mounted) {
                            setState(() => _rated = true);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text("¡Valoración enviada! ⭐"),
                              backgroundColor: Colors.amber[700],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ));
                          }
                        },
                        child: const Text("Cerrar proceso"),
                      ),
                    ],
                  ),
                );
                break;
              case 'rate':
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RatingScreen(
                    contactName: widget.chatPartnerName,
                    contactImageUrl: widget.chatPartnerImage,
                    contactSubtitle: widget.chatPartnerSubtitle ?? (_userRole == 'company' ? 'Candidato' : 'Empresa'),
                  )),
                );
                if (result == true && mounted) {
                  setState(() => _rated = true);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text("¡Valoración enviada! ⭐"),
                    backgroundColor: Colors.amber[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
                break;
              case 'clear':
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text("Limpiar conversación", style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text("¿Estás seguro de que deseas eliminar todos los mensajes?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirestoreService.clearMessages(widget.chatPartnerName);
                          if (mounted) {
                            setState(() => _partnerIsTyping = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Conversación eliminada"),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.red[400],
                            ),
                          );
                          }
                        },
                        child: const Text("Eliminar"),
                      ),
                    ],
                  ),
                );
                break;
              case 'block':
                final isBlocked = StorageService.isUserBlocked(widget.chatPartnerName);
                if (isBlocked) {
                  StorageService.unblockUser(widget.chatPartnerName);
                } else {
                  StorageService.blockUser(widget.chatPartnerName);
                }
                setState(() {
                  _isBlocked = StorageService.isUserBlocked(widget.chatPartnerName);
                  _blockChecked = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBlocked
                        ? "${widget.chatPartnerName} desbloqueado"
                        : "${widget.chatPartnerName} bloqueado"),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: isBlocked ? Colors.green[600] : Colors.red[400],
                  ),
                );
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(children: [
                Icon(Icons.person, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Text("Ver perfil"),
              ]),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(children: [
                Icon(Icons.delete_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Text("Limpiar conversación"),
              ]),
            ),
            if (!_procesoCerrado)
              const PopupMenuItem(
                value: 'close_proceso',
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: Colors.teal, size: 20),
                  SizedBox(width: 12),
                  Text("Cerrar proceso", style: TextStyle(color: Colors.teal)),
                ]),
              ),
            if (_procesoCerrado && !_rated)
              const PopupMenuItem(
                value: 'rate',
                child: Row(children: [
                  Icon(Icons.star_outline_rounded, color: Color(0xFFFFB300), size: 20),
                  SizedBox(width: 12),
                  Text("Valorar proceso", style: TextStyle(color: Color(0xFFFFB300))),
                ]),
              ),
            if (_rated)
              const PopupMenuItem(
                enabled: false,
                value: 'rated',
                child: Row(children: [
                  Icon(Icons.star_rounded, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Text("Ya valoraste este proceso", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'block',
              child: Row(children: [
                Icon(_isBlocked ? Icons.check_circle_outline : Icons.block,
                    color: _isBlocked ? Colors.green : Colors.red, size: 20),
                const SizedBox(width: 12),
                Text(_isBlocked ? "Desbloquear" : "Bloquear",
                    style: TextStyle(color: _isBlocked ? Colors.green : Colors.red)),
              ]),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey[200], height: 1),
      ),
    );
  }

  Widget _buildDateDivider(DateTime time) {
    final now = DateTime.now();
    final isToday = time.day == now.day && time.month == now.month;
    final label = isToday ? "Hoy" : "${time.day}/${time.month}/${time.year}";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ),
          Expanded(child: Divider(color: Colors.grey[300], height: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: m.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del interlocutor
          if (!m.isMe) ...[
            widget.chatPartnerImage != null
                ? CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(widget.chatPartnerImage!),
                  )
                : CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      _userRole == 'company' ? Icons.person : Icons.business,
                      size: 14, color: Colors.blue,
                    ),
                  ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Burbuja
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  padding: m.type == MessageType.image
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: m.isMe
                        ? const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: m.isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(m.isMe ? 18 : 4),
                      bottomRight: Radius.circular(m.isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: m.isMe
                            ? Colors.blue.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: m.type == MessageType.image
                      ? _buildImageBubble(m)
                      : m.type == MessageType.pdf
                          ? _buildPdfBubble(m)
                          : Text(
                              m.text,
                              style: TextStyle(
                                color: m.isMe ? Colors.white : Colors.black87,
                                fontSize: 14.5,
                                height: 1.4,
                              ),
                            ),
                ),
                const SizedBox(height: 3),

                // Hora + estado
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(m.time),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    if (m.isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(m.status),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (m.isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildImageBubble(ChatMessage m) {
    if (m.imageData == null) return const SizedBox.shrink();
    ImageProvider? provider;
    try {
      if (m.imageData!.startsWith('data:')) {
        provider = MemoryImage(base64Decode(m.imageData!.split(',').last));
      } else {
        provider = NetworkImage(m.imageData!);
      }
    } catch (_) {}

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: provider != null
          ? Image(image: provider, width: 220, fit: BoxFit.cover)
          : const Icon(Icons.broken_image, size: 60, color: Colors.grey),
    );
  }

  Widget _buildPdfBubble(ChatMessage m) {
    return GestureDetector(
      onTap: () {
        if (m.pdfBase64 == null) return;
        final bytes = base64Decode(m.pdfBase64!);
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', m.fileName ?? 'documento.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: m.isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: m.isMe ? Colors.white : Colors.red.shade600,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.fileName ?? 'documento.pdf',
                  style: TextStyle(
                    color: m.isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "Toca para descargar",
                  style: TextStyle(
                    color: m.isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 11, color: Colors.grey[400]);
      case MessageStatus.delivered:
        return Icon(Icons.done, size: 12, color: Colors.grey[400]);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Colors.blue);
    }
  }

  Widget _buildInputArea() {
    if (_isBlocked && _blockChecked) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.red[400], size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Bloqueaste a ${widget.chatPartnerName}",
                    style: TextStyle(color: Colors.red[400], fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    StorageService.unblockUser(widget.chatPartnerName);
                    setState(() {
                      _isBlocked = false;
                      _blockChecked = true;
                    });
                  },
                  child: Text("Desbloquear", style: TextStyle(color: Colors.blue[600], fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      child: SafeArea(
        child: Row(
          children: [
            // Botón adjuntar
            GestureDetector(
              onTap: _showAttachMenu,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(Icons.attach_file_rounded, color: Colors.grey[500], size: 20),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Escribe un mensaje...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botón enviar con animación
            ScaleTransition(
              scale: _inputScale,
              child: GestureDetector(
                onTapDown: (_) => _inputController.forward(),
                onTapUp: (_) {
                  _inputController.reverse();
                  _sendMessage();
                },
                onTapCancel: () => _inputController.reverse(),
                child: Container(
                  width: 46, height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x441565C0), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TYPING INDICATOR CON 3 PUNTOS ANIMADOS
// ─────────────────────────────────────────────
class TypingIndicator extends StatefulWidget {
  final bool isCompany;
  const TypingIndicator({super.key, this.isCompany = true});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) =>
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450)),
    );
    _animations = _controllers.map((c) =>
      Tween<double>(begin: 0, end: -7).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)),
    ).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              widget.isCompany ? Icons.business : Icons.person,
              size: 14, color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _animations[i].value),
                    child: Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}