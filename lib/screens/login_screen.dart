import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'email_verification_screen.dart';
import 'role_selection_screen.dart';
import 'feed_screen.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  final bool startOnRegister;
  const LoginScreen({super.key, this.startOnRegister = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late bool _isLogin;
  bool _loading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _slideController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isLogin = !widget.startOnRegister;
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _slideAnim = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _handleEmailAuth() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError("Completa todos los campos");
      return;
    }
    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showError("Ingresa tu nombre");
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Verificar que el correo esté confirmado
        await AuthService.reloadUser();
        if (!AuthService.isEmailVerified) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
            );
          }
          return;
        }
        await _navigateAfterAuth();
      } else {
        await AuthService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: '',
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(_parseFirebaseError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() => _loading = true);
    try {
      await AuthService.loginWithGoogle();
      if (!mounted) return;
      final role = StorageService.getUserRole() ?? '';
      if (role.isEmpty) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
      } else {
        await _navigateAfterAuth();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'redirect-pending') return;
      _showError(_parseFirebaseError(e.code));
    } catch (e) {
      debugPrint('🔴 Google catch error: $e');
      if (mounted) _showError("Error al iniciar con Google");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateAfterAuth() async {
    await AuthService.loadProfileToStorage();
    final role = StorageService.getUserRole() ?? 'candidate';
    final name = StorageService.getName()
        ?? AuthService.currentUser?.displayName
        ?? 'Usuario';
    final profession = StorageService.getProfession()
        ?? (role == 'company' ? 'Empresa' : 'Candidato');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedScreen(
          name: name,
          profession: profession,
          role: role,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showResetPassword() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Recuperar contraseña",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "tu@email.com",
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await AuthService.resetPassword(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _showError("✅ Correo de recuperación enviado");
                }
              }
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  String _parseFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return "No existe una cuenta con ese correo";
      case 'wrong-password': return "Contraseña incorrecta";
      case 'email-already-in-use': return "Ese correo ya está registrado";
      case 'weak-password': return "La contraseña debe tener al menos 6 caracteres";
      case 'invalid-email': return "El correo no es válido";
      case 'too-many-requests': return "Demasiados intentos. Intenta más tarde";
      case 'network-request-failed': return "Sin conexión a internet";
      default: return "Ocurrió un error. Intenta de nuevo";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER DEGRADADO
            Container(
              height: 280,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: canGoBack ? 0 : 40),
                  // Botón atrás si hay pantalla anterior
                  if (canGoBack)
                    Align(
                      alignment: Alignment.topLeft,
                      child: SafeArea(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  // LOGO
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("RJ",
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900,
                          color: Color(0xFF1565C0), letterSpacing: -1,
                        )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("RightJob",
                    style: TextStyle(color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin ? "Bienvenido de vuelta 👋" : "Crea tu cuenta gratis",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                  ),
                ],
              ),
            ),

            // FORMULARIO
            AnimatedBuilder(
              animation: _slideController,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: child,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    // Tabs Login / Registro
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _tabButton("Iniciar sesión", _isLogin),
                          _tabButton("Registrarme", !_isLogin),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo nombre (solo en registro)
                    if (!_isLogin) ...[
                      _inputField(
                        controller: _nameController,
                        hint: "Tu nombre completo",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email
                    _inputField(
                      controller: _emailController,
                      hint: "Correo electrónico",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // Contraseña
                    _inputField(
                      controller: _passwordController,
                      hint: "Contraseña",
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey, size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    // Olvidé contraseña
                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showResetPassword,
                          child: const Text("¿Olvidaste tu contraseña?",
                            style: TextStyle(color: Colors.blue, fontSize: 13)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // BOTÓN PRINCIPAL
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _loading ? null : _handleEmailAuth,
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _isLogin ? "Iniciar sesión" : "Crear cuenta",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // SEPARADOR
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("o", style: TextStyle(color: Colors.grey[400])),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // BOTÓN GOOGLE
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _loading ? null : _handleGoogleAuth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo Google con colores
                            const Text("G",
                              style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800,
                                color: Color(0xFF4285F4),
                              )),
                            const SizedBox(width: 10),
                            Text("Continuar con Google",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // CAMBIAR MODO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? "¿No tienes cuenta? " : "¿Ya tienes cuenta? ",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: _toggleMode,
                          child: Text(
                            _isLogin ? "Registrarme" : "Iniciar sesión",
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final wantsLogin = label == "Iniciar sesión";
          if (wantsLogin != _isLogin) _toggleMode();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4, offset: const Offset(0, 2))
            ] : [],
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: active ? const Color(0xFF1565C0) : Colors.grey[500],
            )),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}