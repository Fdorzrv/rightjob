// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class StorageService {

  static String? _get(String key) {
    try {
      final val = web.window.localStorage.getItem(key);
      if (val == null || val == 'null') return null;
      return val;
    } catch (_) { return null; }
  }

  static void _set(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } catch (_) {}
  }

  static void _remove(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }

  // ── PERFIL ────────────────────────────────────────────────────────────────
  static void saveUserProfile(String name, String profession, String role) {
    _set('user_name', name);
    _set('user_profession', profession);
    _set('user_role', role);
  }

  static void saveUserRole(String role) => _set('user_role', role);
  static void saveBio(String bio) => _set('user_bio', bio);
  static void saveSalary(String salary) => _set('user_salary', salary);
  static void saveImageUrl(String url) => _set('user_image_url', url);

  static void saveImageForUid(String uid, String imageData) =>
      _set('img_$uid', imageData);
  static String? getImageForUid(String uid) => _get('img_$uid');

  static void saveFullProfile({
    required String name,
    required String profession,
    required String role,
    String? bio,
    String? salary,
    String? imageUrl,
    String? education,
  }) {
    _set('user_name', name);
    _set('user_profession', profession);
    _set('user_role', role);
    if (bio != null) _set('user_bio', bio);
    if (salary != null) _set('user_salary', salary);
    if (imageUrl != null) _set('user_image_url', imageUrl);
    if (education != null) _set('user_education', education);
  }

  // ── GETTERS ───────────────────────────────────────────────────────────────
  static String? getName()       => _get('user_name');
  static String? getProfession() => _get('user_profession');
  static String? getUserRole()   => _get('user_role');
  static String? getBio()        => _get('user_bio');
  static String? getSalary()     => _get('user_salary');
  static String? getImageUrl()   => _get('user_image_url');
  static String? getEducation()  => _get('user_education');
  static String? getPhone()      => _get('user_phone');
  static String? getLinkedin()   => _get('user_linkedin');
  static String? getWebsite()    => _get('user_website');
  static String? getCity()       => _get('user_city');

  static void savePhone(String v)    => _set('user_phone', v);
  static void saveLinkedin(String v) => _set('user_linkedin', v);
  static void saveWebsite(String v)  => _set('user_website', v);
  static void saveCity(String v)     => _set('user_city', v);

  // ── ONBOARDING ────────────────────────────────────────────────────────────
  static bool hasSeenOnboarding() => _get('onboarding_done') == 'true';
  static void setOnboardingDone() => _set('onboarding_done', 'true');

  // ── BLOQUEOS ──────────────────────────────────────────────────────────────
  static List<String> getBlockedUsers() {
    try {
      final raw = _get('blocked_users') ?? '';
      if (raw.isEmpty) return [];
      return raw.split(',').where((s) => s.isNotEmpty).toList();
    } catch (_) { return []; }
  }

  static void blockUser(String name) {
    try {
      final blocked = getBlockedUsers();
      if (!blocked.contains(name)) {
        blocked.add(name);
        _set('blocked_users', blocked.join(','));
      }
    } catch (_) {}
  }

  static void unblockUser(String name) {
    try {
      final blocked = getBlockedUsers();
      blocked.remove(name);
      _set('blocked_users', blocked.join(','));
    } catch (_) {}
  }

  static bool isUserBlocked(String name) {
    try { return getBlockedUsers().contains(name); }
    catch (_) { return false; }
  }

  // ── DARK MODE ─────────────────────────────────────────────────────────────
  static bool isDarkMode() => _get('dark_mode') == 'true';
  static void setDarkMode(bool value) =>
      _set('dark_mode', value ? 'true' : 'false');

  // ── CLEAR ─────────────────────────────────────────────────────────────────
  static void clearAll() {
    for (final key in [
      'user_name', 'user_profession', 'user_role', 'user_bio',
      'user_salary', 'user_image_url', 'user_education',
      'user_phone', 'user_linkedin', 'user_website', 'user_city',
      'onboarding_done',
    ]) { _remove(key); }
  }
}