import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream del estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  static User? get currentUser => _auth.currentUser;

  // ── REGISTRO CON EMAIL ──────────────────────────────────────────────────
  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    // Crear perfil en Firestore
    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': false,
    });

    return credential;
  }

  // ── LOGIN CON EMAIL ─────────────────────────────────────────────────────
  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── LOGIN CON GOOGLE ────────────────────────────────────────────────────
  static Future<UserCredential> loginWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'prompt': 'select_account'});
    final credential = await _auth.signInWithPopup(googleProvider);

    // Si es nuevo usuario, crear perfil en Firestore
    final userDoc = await _db
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (!userDoc.exists) {
      await _db.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': credential.user!.displayName ?? 'Usuario',
        'email': credential.user!.email ?? '',
        'role': '', // Se asigna en onboarding
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
      });
    }

    return credential;
  }

  // ── CERRAR SESIÓN ───────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── OBTENER ROL DEL USUARIO ─────────────────────────────────────────────
  static Future<String?> getUserRole() async {
    if (currentUser == null) return null;
    final doc = await _db
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    return doc.data()?['role'] as String?;
  }

  // ── ACTUALIZAR PERFIL EN FIRESTORE ──────────────────────────────────────
  static Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser!.uid)
        .update(data);
  }

  // ── RECUPERAR CONTRASEÑA ────────────────────────────────────────────────
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── CARGAR PERFIL DE FIRESTORE A STORAGE LOCAL ──────────────────────────
  // Sincroniza los datos de Firestore con StorageService al iniciar sesión
  static Future<void> loadProfileToStorage() async {
    if (currentUser == null) {
      debugPrint('⚠️ loadProfile: currentUser es null');
      return;
    }
    try {
      debugPrint('🔄 loadProfile: cargando UID=${currentUser!.uid}');
      final doc = await _db.collection('users').doc(currentUser!.uid).get();
      final data = doc.data();
      debugPrint('📄 loadProfile: doc existe=${doc.exists}, data=$data');
      if (data == null) return;

      final name = data['name'] as String? ?? currentUser!.displayName ?? '';
      final role = data['role'] as String? ?? '';
      debugPrint('👤 loadProfile: name=$name, role=$role');

      final bio = data['bio'] as String?;
      final salary = data['salary'] as String?;
      final imageUrl = data['imageUrl'] as String?;
      final education = data['education'] as String?;
      final profession = data['profession'] as String?
          ?? (role == 'company' ? 'Empresa' : 'Candidato');

      // Siempre guardar el rol explícitamente primero
      if (role.isNotEmpty) StorageService.saveUserRole(role);
      debugPrint('✅ loadProfile: rol guardado en storage = $role');

      StorageService.saveFullProfile(
        name: name,
        profession: profession,
        role: role,
        bio: bio,
        salary: salary,
        imageUrl: imageUrl,
        education: education,
      );

      // Si Firestore no tiene imagen (era base64), recuperar de localStorage por UID
      if (imageUrl == null || imageUrl.isEmpty) {
        final localImage = StorageService.getImageForUid(currentUser!.uid);
        if (localImage != null) {
          StorageService.saveImageUrl(localImage);
        }
      }

      // Campos extra
      final phone = data['phone'] as String?;
      final linkedin = data['linkedin'] as String?;
      final website = data['website'] as String?;
      final city = data['city'] as String?;
      if (phone != null) StorageService.savePhone(phone);
      if (linkedin != null) StorageService.saveLinkedin(linkedin);
      if (website != null) StorageService.saveWebsite(website);
      if (city != null) StorageService.saveCity(city);
    } catch (_) {}
  }

  // ── GUARDAR PERFIL COMPLETO EN FIRESTORE ────────────────────────────────
  static Future<void> saveFullProfileToFirestore({
    required String name,
    required String role,
    String? bio,
    String? salary,
    String? imageUrl,
    String? education,
    String? profession,
    Map<String, dynamic>? extra,
  }) async {
    if (currentUser == null) return;
    try {
      await currentUser!.updateDisplayName(name);

      // La imagen base64 puede superar el límite de Firestore (1MB)
      // Solo guardamos URL externas en Firestore; base64 se queda en localStorage
      final bool isBase64 = imageUrl != null && imageUrl.startsWith('data:');
      final String? firestoreImageUrl = isBase64 ? null : imageUrl;

      await _db.collection('users').doc(currentUser!.uid).set({
        'name': name,
        'role': role,
        if (bio != null) 'bio': bio,
        if (salary != null) 'salary': salary,
        if (firestoreImageUrl != null) 'imageUrl': firestoreImageUrl,
        if (education != null) 'education': education,
        if (profession != null) 'profession': profession,
        if (extra != null) ...extra,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}