import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_form_screen.dart';
import 'onboarding_screen.dart';
import '../services/storage_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() => _selectedRole = role);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _selectedRole = null);
      _showPrivacyModal(role);
    });
  }

  void _showPrivacyModal(String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrivacyModal(
        onAccept: () {
          Navigator.pop(context); // cerrar modal
          final bool seenOnboarding = StorageService.hasSeenOnboarding();
          final Widget next = seenOnboarding
              ? ProfileFormScreen(role: role)
              : OnboardingScreen(role: role);
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => next,
              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _slideAnim.value),
                child: child,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // BOTÓN REGRESAR
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),

                    // LOGO Y TÍTULO
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.handshake, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "RightJob",
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "¿Cómo quieres usar la app?",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16),
                    ),

                    const Spacer(flex: 2),

                    // TARJETA CANDIDATO
                    _buildRoleCard(
                      role: 'candidate',
                      icon: Icons.person_outline,
                      title: "Soy Candidato",
                      subtitle: "Busco empleo y quiero conectar\ncon empresas que me interesen",
                      isSelected: _selectedRole == 'candidate',
                      isOutlined: false,
                    ),
                    const SizedBox(height: 16),

                    // TARJETA EMPRESA
                    _buildRoleCard(
                      role: 'company',
                      icon: Icons.business,
                      title: "Soy Empresa",
                      subtitle: "Busco talento y quiero publicar\nofertas de trabajo",
                      isSelected: _selectedRole == 'company',
                      isOutlined: true,
                    ),

                    const Spacer(flex: 3),

                    Text(
                      "Al continuar aceptas nuestros Términos y Condiciones",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isOutlined,
  }) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: isOutlined
              ? Colors.white.withValues(alpha: isSelected ? 0.25 : 0.1)
              : isSelected ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isOutlined ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5) : null,
          boxShadow: !isOutlined
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isOutlined ? Colors.white.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: isOutlined ? Colors.white : Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isOutlined ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isOutlined ? Colors.white.withValues(alpha: 0.75) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOutlined ? Colors.white.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward, size: 18, color: isOutlined ? Colors.white : Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MODAL DE PRIVACIDAD ──────────────────────────────────────────────────────
class _PrivacyModal extends StatelessWidget {
  final VoidCallback onAccept;
  const _PrivacyModal({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icono principal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFF1565C0), size: 36),
          ),
          const SizedBox(height: 16),

          // Título
          const Text(
            "Tus datos están seguros 🔒",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Antes de continuar, queremos que sepas cómo cuidamos tu información.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Puntos clave
          _privacyPoint(
            icon: Icons.lock_outline_rounded,
            color: Colors.blue,
            title: "Información privada",
            description: "Tu correo y teléfono solo se comparten cuando hay un match mutuo.",
          ),
          const SizedBox(height: 14),
          _privacyPoint(
            icon: Icons.visibility_off_outlined,
            color: Colors.purple,
            title: "Tú decides qué compartir",
            description: "Solo mostramos lo que tú pones en tu perfil. Nada más.",
          ),
          const SizedBox(height: 14),
          _privacyPoint(
            icon: Icons.delete_outline_rounded,
            color: Colors.red,
            title: "Puedes eliminar tu cuenta",
            description: "En cualquier momento puedes borrar tu perfil y todos tus datos.",
          ),
          const SizedBox(height: 14),
          _privacyPoint(
            icon: Icons.storage_rounded,
            color: Colors.green,
            title: "Almacenamiento seguro",
            description: "Usamos Firebase de Google para proteger tu información con cifrado.",
          ),

          const SizedBox(height: 28),

          // Botón aceptar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: onAccept,
              child: const Text(
                "Entendido, ¡vamos! 🚀",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Link política completa
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            child: Text(
              "Ver política de privacidad completa",
              style: TextStyle(fontSize: 12, color: Colors.grey[500], decoration: TextDecoration.underline),
            ),
          ),
          ],
        ),    // Column
      ),      // SingleChildScrollView
    );        // Container
  }

  Widget _privacyPoint({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}