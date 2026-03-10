import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class RatingScreen extends StatefulWidget {
  final String contactName;
  final String? contactImageUrl;
  final String contactSubtitle;

  const RatingScreen({
    super.key,
    required this.contactName,
    this.contactImageUrl,
    required this.contactSubtitle,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _comunicacion = 0;
  double _honestidad = 0;
  double _profesionalismo = 0;
  final _commentController = TextEditingController();
  bool _sending = false;

  double get _promedio => (_comunicacion + _honestidad + _profesionalismo) / 3;
  bool get _isValid => _comunicacion > 0 && _honestidad > 0 && _profesionalismo > 0;

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _sending = true);
    await FirestoreService.saveRating(
      toName: widget.contactName,
      comunicacion: _comunicacion,
      honestidad: _honestidad,
      profesionalismo: _profesionalismo,
      comment: _commentController.text.trim(),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = StorageService.getUserRole() == 'company';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Valorar proceso",
            style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar + nombre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.contactName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(widget.contactSubtitle,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  ),
                  if (_isValid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _promedioColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, color: _promedioColor, size: 16),
                          const SizedBox(width: 4),
                          Text(_promedio.toStringAsFixed(1),
                              style: TextStyle(color: _promedioColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildCriterioCard(
              icon: Icons.chat_bubble_outline,
              titulo: "Comunicación",
              descripcion: isCompany
                  ? "¿Qué tan clara y fluida fue la comunicación del candidato?"
                  : "¿Qué tan clara y fluida fue la comunicación de la empresa?",
              valor: _comunicacion,
              onChanged: (v) => setState(() => _comunicacion = v),
            ),
            const SizedBox(height: 16),
            _buildCriterioCard(
              icon: Icons.verified_user_outlined,
              titulo: "Perfil honesto",
              descripcion: "¿La información del perfil era real y precisa?",
              valor: _honestidad,
              onChanged: (v) => setState(() => _honestidad = v),
            ),
            const SizedBox(height: 16),
            _buildCriterioCard(
              icon: Icons.workspace_premium_outlined,
              titulo: "Profesionalismo",
              descripcion: "¿Demostró seriedad y compromiso durante el proceso?",
              valor: _profesionalismo,
              onChanged: (v) => setState(() => _profesionalismo = v),
            ),
            const SizedBox(height: 16),

            // Comentario opcional
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.edit_note, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text("Comentario (opcional)",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: "Comparte tu experiencia...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? const Color(0xFF1565C0) : Colors.grey[300],
                  foregroundColor: _isValid ? Colors.white : Colors.grey[500],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isValid && !_sending ? _submit : null,
                child: _sending
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, size: 20),
                          SizedBox(width: 8),
                          Text("Enviar valoración",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
              ),
            ),
            if (!_isValid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("Califica los 3 criterios para continuar",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final img = widget.contactImageUrl;
    if (img != null && img.isNotEmpty) {
      if (img.startsWith('data:')) {
        try {
          return CircleAvatar(radius: 28, backgroundImage: MemoryImage(base64Decode(img.split(',').last)));
        } catch (_) {}
      } else if (img.startsWith('http')) {
        return CircleAvatar(radius: 28, backgroundImage: NetworkImage(img));
      }
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.blue.shade100,
      child: Icon(Icons.person, color: Colors.blue.shade700, size: 28),
    );
  }

  Color get _promedioColor {
    if (_promedio >= 4) return Colors.green;
    if (_promedio >= 2.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCriterioCard({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required double valor,
    required void Function(double) onChanged,
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
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(descripcion,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => onChanged((i + 1).toDouble()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < valor ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < valor ? const Color(0xFFFFB300) : Colors.grey[300],
                    size: 38,
                  ),
                ),
              );
            }),
          ),
          if (valor > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(_labelForRating(valor),
                    style: TextStyle(
                        color: _colorForRating(valor), fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }

  String _labelForRating(double v) {
    if (v == 1) return "Muy malo";
    if (v == 2) return "Malo";
    if (v == 3) return "Regular";
    if (v == 4) return "Bueno";
    return "Excelente ⭐";
  }

  Color _colorForRating(double v) {
    if (v <= 2) return Colors.red;
    if (v == 3) return Colors.orange;
    return Colors.green;
  }
}