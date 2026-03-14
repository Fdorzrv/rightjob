import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'feed_screen.dart';
import 'role_selection_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  Timer? _checkTimer;
  bool _resending = false;
  bool _resentOk = false;
  int _secondsLeft = 60;
  Timer? _cooldownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Verificar cada 3 segundos si el usuario ya confirmó
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerification());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _cooldownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    await AuthService.reloadUser();
    if (!mounted) return;
    if (AuthService.isEmailVerified) {
      _checkTimer?.cancel();
      // Navegar al siguiente paso
      final role = StorageService.getUserRole() ?? '';
      if (role.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      } else {
        final name = StorageService.getName() ?? AuthService.currentUser?.displayName ?? 'Usuario';
        final profession = StorageService.getProfession() ?? 'Candidato';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FeedScreen(
            name: name,
            profession: profession,
            role: role,
          )),
        );
      }
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft < 60) return;
    setState(() => _resending = true);
    try {
      await AuthService.resendVerificationEmail();
      if (!mounted) return;
      setState(() { _resentOk = true; _secondsLeft = 60; });
      // Cooldown de 60 segundos antes de poder reenviar
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) {
          t.cancel();
          setState(() { _secondsLeft = 60; _resentOk = false; });
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo reenviar el correo. Intenta más tarde.")),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? '';
    final canResend = !_resending && _secondsLeft == 60 && !_resentOk;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Ícono animado
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Verifica tu correo",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 12),
              Text(
                "Enviamos un enlace de verificación a:",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Card de instrucciones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12),
                  ],
                ),
                child: Column(
                  children: [
                    _step("1", "Abre tu app de correo o Gmail"),
                    const SizedBox(height: 14),
                    _step("2", "Busca un mensaje de RightJob"),
                    const SizedBox(height: 14),
                    _step("3", "Haz clic en el enlace de verificación"),
                    const SizedBox(height: 14),
                    _step("4", "Esta pantalla avanzará automáticamente ✅"),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Indicador de espera
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Esperando verificación...",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Botón reenviar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: canResend ? const Color(0xFF1565C0) : Colors.grey,
                    side: BorderSide(
                      color: canResend ? const Color(0xFF1565C0) : Colors.grey[300]!,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canResend ? _resend : null,
                  icon: _resending
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _resentOk
                        ? "Reenviado ✓ (espera ${_secondsLeft}s)"
                        : "Reenviar correo",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón salir
              TextButton(
                onPressed: _signOut,
                child: Text(
                  "Usar otra cuenta",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
      ],
    );
  }
}