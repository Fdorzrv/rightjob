import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'profile_form_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String role; // 'candidate' | 'company'

  const OnboardingScreen({super.key, required this.role});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<_OnboardingPage> _pages;

  // Controladores de animación por página
  late List<AnimationController> _iconControllers;
  late List<AnimationController> _textControllers;
  late List<Animation<double>> _iconScales;
  late List<Animation<double>> _iconFades;
  late List<Animation<Offset>> _textSlides;
  late List<Animation<double>> _textFades;

  @override
  void initState() {
    super.initState();
    _pages = widget.role == 'candidate' ? _candidatePages() : _companyPages();

    _iconControllers = List.generate(
      _pages.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 700)),
    );
    _textControllers = List.generate(
      _pages.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)),
    );

    _iconScales = _iconControllers.map((c) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();
    _iconFades = _iconControllers.map((c) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: const Interval(0.0, 0.5)))).toList();
    _textSlides = _textControllers.map((c) =>
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();
    _textFades = _textControllers.map((c) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    _animatePage(0);
  }

  void _animatePage(int index) {
    _iconControllers[index].forward(from: 0);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _textControllers[index].forward(from: 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _iconControllers) { c.dispose(); }
    for (final c in _textControllers) { c.dispose(); }
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // setOnboardingDone se llama al completar el registro en ProfileFormScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => ProfileFormScreen(role: widget.role),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  List<_OnboardingPage> _candidatePages() => [
    _OnboardingPage(
      icon: Icons.swipe_rounded,
      secondaryIcon: Icons.work_rounded,
      gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      accentColor: const Color(0xFF42A5F5),
      title: "Encuentra tu\ntrabajo ideal",
      subtitle: "Swipe entre ofertas que se\nadaptan a tu perfil y habilidades",
      features: ["Ofertas personalizadas", "Filtros por sector y salario", "Resultados en tiempo real"],
    ),
    _OnboardingPage(
      icon: Icons.handshake_rounded,
      secondaryIcon: Icons.chat_bubble_rounded,
      gradient: [const Color(0xFF00695C), const Color(0xFF26A69A)],
      accentColor: const Color(0xFF26A69A),
      title: "Haz match y chatea\ndirecto con la empresa",
      subtitle: "Cuando hay interés mutuo,\nla conversación comienza al instante",
      features: ["Match en tiempo real", "Chat directo con reclutadores", "Comparte tu CV desde el chat"],
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      secondaryIcon: Icons.star_rounded,
      gradient: [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
      accentColor: const Color(0xFFAB47BC),
      title: "Muestra\ntu valor",
      subtitle: "Un perfil profesional que destaca\ntus habilidades y experiencia",
      features: ["Perfil completo y atractivo", "Valoraciones verificadas", "Visibilidad ante cientos de empresas"],
    ),
  ];

  List<_OnboardingPage> _companyPages() => [
    _OnboardingPage(
      icon: Icons.people_alt_rounded,
      secondaryIcon: Icons.swipe_rounded,
      gradient: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
      accentColor: const Color(0xFF42A5F5),
      title: "Encuentra al\ncandidato perfecto",
      subtitle: "Swipe entre perfiles calificados\nque se ajustan a tu vacante",
      features: ["Candidatos filtrados", "Perfiles completos y verificados", "Búsqueda por habilidades"],
    ),
    _OnboardingPage(
      icon: Icons.work_rounded,
      secondaryIcon: Icons.bar_chart_rounded,
      gradient: [const Color(0xFF00695C), const Color(0xFF26A69A)],
      accentColor: const Color(0xFF26A69A),
      title: "Publica tus\nvacantes",
      subtitle: "Gestiona todas tus ofertas\nde trabajo en un solo lugar",
      features: ["Múltiples vacantes activas", "Estadísticas por vacante", "Edita y cierra cuando quieras"],
    ),
    _OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      secondaryIcon: Icons.check_circle_rounded,
      gradient: [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
      accentColor: const Color(0xFFAB47BC),
      title: "Contrata\nmás rápido",
      subtitle: "Conecta directo con candidatos\ninteresados en tu empresa",
      features: ["Chat directo sin intermediarios", "Proceso ágil y transparente", "Valoraciones de candidatos"],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // TOP BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Puntos indicadores
                    Row(
                      children: List.generate(_pages.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                    // Botón saltar
                    GestureDetector(
                      onTap: _finish,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("Saltar",
                            style: TextStyle(color: Colors.white, fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),

              // PÁGINAS
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _animatePage(i);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(i),
                ),
              ),

              // BOTÓN SIGUIENTE
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: GestureDetector(
                  onTap: _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isLast ? "¡Comenzar ahora!" : "Siguiente",
                        style: TextStyle(
                          color: page.gradient.first,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int i) {
    final page = _pages[i];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // ILUSTRACIÓN ANIMADA
          ScaleTransition(
            scale: _iconScales[i],
            child: FadeTransition(
              opacity: _iconFades[i],
              child: _buildIllustration(page),
            ),
          ),
          const SizedBox(height: 32),

          // TEXTO ANIMADO
          SlideTransition(
            position: _textSlides[i],
            child: FadeTransition(
              opacity: _textFades[i],
              child: Column(
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...page.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 10),
                        Text(f, style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(_OnboardingPage page) {
    return SizedBox(
      width: 160, height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulsingCircle(color: Colors.white.withValues(alpha: 0.1), size: 160),
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Icon(page.icon, size: 52, color: Colors.white),
          Positioned(
            right: 10, top: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(page.secondaryIcon, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CÍRCULO PULSANTE ──────────────────────────────────────────────────────────

class _PulsingCircle extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingCircle({required this.color, required this.size});

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

// ── MODELO DE PÁGINA ──────────────────────────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final IconData secondaryIcon;
  final List<Color> gradient;
  final Color accentColor;
  final String title;
  final String subtitle;
  final List<String> features;

  const _OnboardingPage({
    required this.icon,
    required this.secondaryIcon,
    required this.gradient,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}