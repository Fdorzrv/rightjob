import 'dart:typed_data';

enum MessageStatus { sending, delivered, read }
enum MessageType { text, image, pdf }

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  MessageStatus status;
  final MessageType type;

  // Para imágenes (base64 data URI)
  final String? imageData;

  // Para PDFs
  final String? pdfBase64;
  final String? fileName;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.status = MessageStatus.sending,
    this.type = MessageType.text,
    this.imageData,
    this.pdfBase64,
    this.fileName,
  });
}