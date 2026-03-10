import 'package:flutter/material.dart';
import 'profile_form_screen.dart';
import 'profile_form_screen.dart';
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
      final Widget next = ProfileFormScreen(role: role);
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => next,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
      setState(() => _selectedRole = null);
    });
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
                        onTap: () => Navigator.pop(context),
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