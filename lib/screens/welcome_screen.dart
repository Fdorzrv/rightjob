import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _contentController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _badgesFade;
  late Animation<double> _ctaSlide;
  late Animation<double> _ctaFade;
  late Animation<double> _float;
  late Animation<double> _pulse;
  late Animation<double> _bgRotate;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bgRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(_bgController);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    ));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    ));
    _titleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    ));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    ));
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    ));
    _badgesFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
    ));
    _ctaSlide = Tween<double>(begin: 40.0, end: 0.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));
    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));
    _float = Tween<double>(begin: -8.0, end: 8.0).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── FONDO ANIMADO ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgRotate,
            builder: (_, __) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1628), Color(0xFF0D2B5E), Color(0xFF1565C0)],
                ),
              ),
              child: CustomPaint(
                size: Size(size.width, size.height),
                painter: _BackgroundPainter(_bgRotate.value),
              ),
            ),
          ),

          // ── CONTENIDO ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // LOGO ANIMADO
                  AnimatedBuilder(
                    animation: Listenable.merge([_contentController, _floatController, _pulseController]),
                    builder: (_, __) => Opacity(
                      opacity: _logoFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _float.value),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _buildLogo(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // TÍTULO
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (_, __) => Opacity(
                      opacity: _titleFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Column(
                          children: [
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Conecta con tu\n",
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -1.0,
                                      height: 1.1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "trabajo ideal",
                                    style: TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64B5F6),
                                      letterSpacing: -1.0,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SUBTÍTULO
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (_, __) => Opacity(
                      opacity: _subtitleFade.value,
                      child: Text(
                        "La plataforma donde candidatos y empresas hacen match profesional",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // BADGES DE FEATURES
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (_, __) => Opacity(
                      opacity: _badgesFade.value,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          _badge(Icons.swipe, "Swipe a tu ritmo"),
                          _badge(Icons.handshake_outlined, "Match real"),
                          _badge(Icons.chat_bubble_outline, "Chat directo"),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // BOTONES CTA
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (_, __) => Opacity(
                      opacity: _ctaFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _ctaSlide.value),
                        child: Column(
                          children: [
                            // BOTÓN PRINCIPAL
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1565C0),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text("Iniciar Sesión",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // BOTÓN SECUNDARIO
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.35),
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(startOnRegister: true),
                                  ),
                                ),
                                child: Text("Registrarse",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  )),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anillo exterior pulsante
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            // Anillo medio
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            // Logo central
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text("RJ",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                    letterSpacing: -1,
                  )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF90CAF9), size: 15),
          const SizedBox(width: 6),
          Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }
}

// ── PINTOR DEL FONDO ANIMADO ───────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final double rotation;
  _BackgroundPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Círculo grande superior derecho
    paint.color = const Color(0xFF1976D2).withValues(alpha: 0.3);
    canvas.drawCircle(
      Offset(size.width + 60 * math.cos(rotation * 0.3),
             -80 + 40 * math.sin(rotation * 0.2)),
      200, paint,
    );

    // Círculo medio inferior izquierdo
    paint.color = const Color(0xFF0D47A1).withValues(alpha: 0.4);
    canvas.drawCircle(
      Offset(-60 + 30 * math.sin(rotation * 0.4),
             size.height + 50 * math.cos(rotation * 0.3)),
      180, paint,
    );

    // Círculo pequeño centro
    paint.color = const Color(0xFF42A5F5).withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(size.width * 0.5 + 20 * math.cos(rotation * 0.5),
             size.height * 0.45 + 20 * math.sin(rotation * 0.4)),
      120, paint,
    );

    // Líneas decorativas diagonales
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final offset = i * 80.0;
      canvas.drawLine(
        Offset(-50 + offset, 0),
        Offset(size.width - 50 + offset, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.rotation != rotation;
}