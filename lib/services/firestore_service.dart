import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import '../models/vacancy_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference get _matches => _db.collection('matches');
  static CollectionReference get _chats => _db.collection('chats');

  static String get _uid => AuthService.currentUser!.uid;
  static String get _userName => AuthService.currentUser?.displayName ?? 'Usuario';

  // ID consistente para el chat — basado en UID del usuario + nombre del contacto ficticio
  static String chatId(String otherName) {
    return '${_uid}__${otherName.replaceAll(' ', '_')}';
  }

  // ── MATCHES ──────────────────────────────────────────────────────────────

  static Future<void> saveMatch(JobMatch match) async {
    await _matches.doc(_uid).collection('user_matches')
        .doc(_sanitize(match.name))
        .set({
      'name': match.name,
      'imageUrl': match.imageUrl,
      'subtitle': match.subtitle,
      'bio': match.bio ?? '',
      'salary': match.salary ?? '',
      'skills': match.skills,
      'lastMessage': '',
      'time': FieldValue.serverTimestamp(),
      'unreadCount': match.unreadCount,
      'hasNewMatch': match.hasNewMatch,
      if (match.phone != null) 'phone': match.phone,
      if (match.linkedin != null) 'linkedin': match.linkedin,
      if (match.website != null) 'website': match.website,
    });
  }

  static Stream<List<JobMatch>> watchMatches() {
    return _matches
        .doc(_uid)
        .collection('user_matches')
        .orderBy('time', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return JobMatch(
                name: data['name'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                subtitle: data['subtitle'] ?? '',
                bio: data['bio'],
                salary: data['salary'],
                skills: List<String>.from(data['skills'] ?? []),
                lastMessage: data['lastMessage'] ?? '',
                unreadCount: data['unreadCount'] ?? 0,
                hasNewMatch: data['hasNewMatch'] ?? false,
                phone: data['phone'] as String?,
                linkedin: data['linkedin'] as String?,
                website: data['website'] as String?,
                procesoCerrado: data['procesoCerrado'] as bool? ?? false,
                rated: data['rated'] as bool? ?? false,
              );
            }).toList());
  }

  static Future<void> updateMatchLastMessage({
    required String matchName,
    required String lastMessage,
    required int unreadCount,
    bool hasNewMatch = false,
  }) async {
    await _matches.doc(_uid).collection('user_matches')
        .doc(_sanitize(matchName))
        .update({
      'lastMessage': lastMessage,
      'time': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'hasNewMatch': hasNewMatch,
    });
  }

  static Future<void> markMatchAsRead(String matchName) async {
    await _matches.doc(_uid).collection('user_matches')
        .doc(_sanitize(matchName))
        .update({'unreadCount': 0, 'hasNewMatch': false});
  }

  // ── CHAT ─────────────────────────────────────────────────────────────────

  static Future<void> sendMessage({
    required String otherName,
    required String text,
  }) async {
    await _sendRawMessage(otherName: otherName, data: {
      'text': text,
      'type': 'text',
    });
  }

  static Future<void> sendImage({
    required String otherName,
    required String imageData,
  }) async {
    await _sendRawMessage(otherName: otherName, data: {
      'text': '',
      'type': 'image',
      'imageData': imageData,
    });
  }

  static Future<void> sendPdf({
    required String otherName,
    required String pdfBase64,
    required String fileName,
  }) async {
    await _sendRawMessage(otherName: otherName, data: {
      'text': fileName,
      'type': 'pdf',
      'pdfBase64': pdfBase64,
      'fileName': fileName,
    });
  }

  // Envía PDF como URL de Storage (no base64)
  static Future<void> sendPdfUrl({
    required String otherName,
    required String pdfUrl,
    required String fileName,
  }) async {
    await _sendRawMessage(otherName: otherName, data: {
      'text': fileName,
      'type': 'pdf',
      'pdfUrl': pdfUrl,
      'fileName': fileName,
    });
  }

  // Obtener chatId entre dos UIDs (para Storage)
  static String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static Future<void> _sendRawMessage({
    required String otherName,
    required Map<String, dynamic> data,
  }) async {
    final cid = chatId(otherName);
    final msgRef = _chats.doc(cid).collection('messages').doc();

    await msgRef.set({
      'id': msgRef.id,
      'senderId': _uid,
      'senderName': _userName,
      'time': FieldValue.serverTimestamp(),
      'status': 'delivered',
      ...data,
    });

    await _chats.doc(cid).set({
      'ownerId': _uid,
      'contactName': otherName,
      'lastMessage': data['type'] == 'image' ? '📷 Imagen' : data['type'] == 'pdf' ? '📄 ${data['fileName']}' : data['text'],
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await updateMatchLastMessage(
      matchName: otherName,
      lastMessage: data['type'] == 'image' ? '📷 Imagen' : data['type'] == 'pdf' ? '📄 ${data['fileName']}' : data['text'] as String,
      unreadCount: 0,
    );
  }

  static Stream<List<ChatMessage>> watchMessages(String otherName) {
    final cid = chatId(otherName);
    return _chats
        .doc(cid)
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              final isMe = data['senderId'] == _uid;
              final ts = data['time'] as Timestamp?;
              final typeStr = data['type'] as String? ?? 'text';
              final type = typeStr == 'image'
                  ? MessageType.image
                  : typeStr == 'pdf'
                      ? MessageType.pdf
                      : MessageType.text;
              return ChatMessage(
                text: data['text'] ?? '',
                isMe: isMe,
                time: ts?.toDate() ?? DateTime.now(),
                status: isMe ? MessageStatus.read : MessageStatus.delivered,
                type: type,
                imageData: data['imageData'] as String?,
                pdfBase64: data['pdfBase64'] as String?,
                fileName: data['fileName'] as String?,
              );
            }).toList());
  }

  static Future<void> clearMessages(String otherName) async {
    final cid = chatId(otherName);
    final snap = await _chats.doc(cid).collection('messages').get();
    // Borrar en batches de 500 (límite de Firestore) para evitar parpadeo
    const batchSize = 500;
    for (int i = 0; i < snap.docs.length; i += batchSize) {
      final batch = _db.batch();
      final chunk = snap.docs.skip(i).take(batchSize);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await updateMatchLastMessage(
      matchName: otherName,
      lastMessage: '',
      unreadCount: 0,
    );
  }

  // ── VALORACIONES ──────────────────────────────────────────────────────────

  // Guarda la valoración que el usuario actual da a otro usuario
  static Future<void> saveRating({
    required String toName,
    required double comunicacion,
    required double honestidad,
    required double profesionalismo,
    String comment = '',
  }) async {
    final promedio = (comunicacion + honestidad + profesionalismo) / 3;
    // Guardamos en el documento del usuario valorado (por nombre, luego migrar a UID)
    await _db.collection('ratings').doc(_sanitize(toName)).collection('reviews').doc(_uid).set({
      'fromUid': _uid,
      'fromName': _userName,
      'toName': toName,
      'comunicacion': comunicacion,
      'honestidad': honestidad,
      'profesionalismo': profesionalismo,
      'promedio': promedio,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Actualizar resumen de promedios
    final snap = await _db.collection('ratings').doc(_sanitize(toName)).collection('reviews').get();
    final reviews = snap.docs.map((d) => d.data()['promedio'] as double).toList();
    final avg = reviews.reduce((a, b) => a + b) / reviews.length;
    await _db.collection('ratings').doc(_sanitize(toName)).set({
      'name': toName,
      'avgTotal': avg,
      'avgComunicacion': snap.docs.map((d) => d.data()['comunicacion'] as double).reduce((a, b) => a + b) / snap.docs.length,
      'avgHonestidad': snap.docs.map((d) => d.data()['honestidad'] as double).reduce((a, b) => a + b) / snap.docs.length,
      'avgProfesionalismo': snap.docs.map((d) => d.data()['profesionalismo'] as double).reduce((a, b) => a + b) / snap.docs.length,
      'totalReviews': reviews.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Marcar proceso como cerrado en el match
    await _matches.doc(_uid).collection('user_matches')
        .doc(_sanitize(toName))
        .update({'procesoCerrado': true, 'rated': true});
  }

  // Obtiene las valoraciones públicas de un usuario
  static Future<Map<String, dynamic>?> getRatingSummary(String name) async {
    final doc = await _db.collection('ratings').doc(_sanitize(name)).get();
    return doc.data();
  }

  // Verifica si el usuario actual ya valoró a alguien
  static Future<bool> hasRated(String toName) async {
    final doc = await _db.collection('ratings').doc(_sanitize(toName)).collection('reviews').doc(_uid).get();
    return doc.exists;
  }

  // Marca el proceso como cerrado (habilita la opción de valorar)
  static Future<void> closeProceso(String matchName) async {
    await _matches.doc(_uid).collection('user_matches')
        .doc(_sanitize(matchName))
        .set({'procesoCerrado': true}, SetOptions(merge: true));
  }

  // ── BÚSQUEDA DE PERFILES ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> searchProfiles({
    required String targetRole, // 'candidate' o 'company'
    String? city,
    String? sector,
    String? availability,
    String? experience,
    String? minSalary,
    String? maxSalary,
  }) async {
    Query query = _db.collection('users').where('role', isEqualTo: targetRole);

    final snap = await query.get();
    final results = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      if (doc.id == _uid) continue; // excluir al propio usuario
      final data = doc.data() as Map<String, dynamic>;

      // Filtrar por ciudad
      if (city != null && city.isNotEmpty) {
        final profileCity = (data['city'] ?? '').toString().toLowerCase();
        if (!profileCity.contains(city.toLowerCase())) continue;
      }

      // Filtrar por sector
      if (sector != null) {
        final profileSector = (data['sector'] ?? data['profession'] ?? '').toString().toLowerCase();
        if (!profileSector.contains(sector.toLowerCase())) continue;
      }

      // Filtrar por disponibilidad
      if (availability != null) {
        final profileAvail = (data['availability'] ?? '').toString();
        if (profileAvail != availability) continue;
      }

      // Filtrar por experiencia
      if (experience != null) {
        final profileExp = (data['experience'] ?? '').toString();
        if (profileExp != experience) continue;
      }

      // Filtrar por salario
      if (minSalary != null || maxSalary != null) {
        final profileSalNum = int.tryParse(
            (data['salary'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (minSalary != null) {
          final min = int.tryParse(minSalary.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          if (profileSalNum < min) continue;
        }
        if (maxSalary != null) {
          final max = int.tryParse(maxSalary.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999999;
          if (profileSalNum > max) continue;
        }
      }

      results.add({
        'uid': doc.id,
        'name': data['name'] ?? 'Sin nombre',
        'profession': data['profession'] ?? '',
        'city': data['city'] ?? '',
        'salary': data['salary'] ?? '',
        'bio': data['bio'] ?? '',
        'imageUrl': data['imageUrl'] ?? '',
        'sector': data['sector'] ?? '',
        'availability': data['availability'] ?? '',
        'experience': data['experience'] ?? '',
        'phone': data['phone'] ?? '',
        'linkedin': data['linkedin'] ?? '',
        'website': data['website'] ?? '',
      });
    }
    return results;
  }

  // Incrementa el contador de swipes recibidos en el perfil del usuario swipeado
  static Future<void> updateCity(String city) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({'city': city});
  }

  static Future<void> incrementSwipesReceived(String toName) async {
    try {
      // Busca el uid del usuario por nombre en la colección users
      final snap = await _db.collection('users')
          .where('name', isEqualTo: toName)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await _db.collection('users').doc(snap.docs.first.id).set({
          'swipesReceived': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> getMyStats() async {
    final results = <String, dynamic>{
      'totalMatches': 0,
      'swipesReceived': 0,
      'messagesSent': 0,
      'messagesReceived': 0,
    };

    try {
      // Total de matches
      final matchesSnap = await _matches.doc(_uid).collection('user_matches').get();
      results['totalMatches'] = matchesSnap.docs.length;

      // Mensajes enviados y recibidos
      int sent = 0, received = 0;
      for (final matchDoc in matchesSnap.docs) {
        try {
          final data = matchDoc.data() as Map<String, dynamic>;
          final partnerName = data['name'] as String? ?? '';
          final cid = chatId(partnerName);
          final msgsSnap = await _chats.doc(cid).collection('messages').get();
          for (final msg in msgsSnap.docs) {
            final msgData = msg.data() as Map<String, dynamic>;
            if (msgData['senderId'] == _uid) { sent++; } else { received++; }
          }
        } catch (_) {}
      }
      results['messagesSent'] = sent;
      results['messagesReceived'] = received;
    } catch (e) {
      debugPrint('❌ getMyStats error: $e');
    }

    // collectionGroup requiere índice — lo intentamos pero no bloqueamos si falla
    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      if (userDoc.exists) {
        results['swipesReceived'] = (userDoc.data()?['swipesReceived'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    // Mi valoración promedio
    try {
      final ratingDoc = await _db.collection('ratings').doc(_sanitize(_userName)).get();
      if (ratingDoc.exists) {
        final rData = ratingDoc.data()!;
        results['myRating'] = rData['avgTotal'];
        results['myRatingCount'] = rData['totalReviews'];
      }
    } catch (_) {}

    return results;
  }

  static String _sanitize(String name) => name.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

  // ── VACANTES ──────────────────────────────────────────────────────────────

  static CollectionReference get _vacancies => _db.collection('vacancies');

  static Future<String> saveVacancy(Vacancy vacancy) async {
    if (vacancy.id.isEmpty) {
      final ref = await _vacancies.add({
        ...vacancy.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } else {
      await _vacancies.doc(vacancy.id).update(vacancy.toMap());
      return vacancy.id;
    }
  }

  static Stream<List<Vacancy>> watchMyVacancies() {
    return _vacancies
        .where('companyUid', isEqualTo: _uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Vacancy.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();
          // Ordenar en cliente por fecha descendente
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  static Future<void> closeVacancy(String vacancyId) async {
    await _vacancies.doc(vacancyId).update({'status': 'closed'});
  }

  static Future<void> reopenVacancy(String vacancyId) async {
    await _vacancies.doc(vacancyId).update({'status': 'active'});
  }

  static Future<void> incrementVacancyStat(String vacancyId, String field) async {
    try {
      await _vacancies.doc(vacancyId).update({
        'stats.$field': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  static Future<void> updateCandidateStatus(String vacancyId, String candidateUid, String status) async {
    await _vacancies.doc(vacancyId).collection('candidates').doc(candidateUid).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Actualizar contadores
    if (status == 'inProcess') {
      await _vacancies.doc(vacancyId).update({'stats.inProcess': FieldValue.increment(1)});
    } else if (status == 'hired') {
      await _vacancies.doc(vacancyId).update({'stats.hired': FieldValue.increment(1)});
    }
  }

  static Future<List<Map<String, dynamic>>> getVacancyCandidates(String vacancyId) async {
    // Traer matches que tienen esta vacancyId
    final snap = await _vacancies.doc(vacancyId).collection('candidates').get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  // ── NOTIFICACIONES ────────────────────────────────────────────────────────

  static CollectionReference _notifRef(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  static Future<void> saveNotification(String toUid, Map<String, dynamic> data) async {
    try {
      await _notifRef(toUid).add({
        ...data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Stream<List<Map<String, dynamic>>> watchNotifications(String uid) {
    return _notifRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'firestoreId': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  static Future<void> markAllNotificationsRead(String uid) async {
    try {
      final snap = await _notifRef(uid).where('isRead', isEqualTo: false).get();
      final batch = _db.batch();
      for (final doc in snap.docs) { batch.update(doc.reference, {'isRead': true}); }
      await batch.commit();
    } catch (_) {}
  }

  static Future<void> deleteNotification(String uid, String notifId) async {
    try {
      // notifId puede ser el id local o el firestoreId
      final snap = await _notifRef(uid).where('id', isEqualTo: notifId).get();
      for (final doc in snap.docs) { await doc.reference.delete(); }
    } catch (_) {}
  }

  static Future<void> deleteAllNotifications(String uid) async {
    try {
      final snap = await _notifRef(uid).get();
      final batch = _db.batch();
      for (final doc in snap.docs) { batch.delete(doc.reference); }
      await batch.commit();
    } catch (_) {}
  }
}