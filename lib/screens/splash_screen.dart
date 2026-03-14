import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'role_selection_screen.dart';
import 'feed_screen.dart';
import 'welcome_screen.dart';
import 'email_verification_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Controlador principal — logo + texto
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Pulso continuo del logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Partículas flotantes
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Barra de progreso
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.3, 0.9, curve: Curves.easeOut)),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    _progressController.forward();

    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;

      User? user;
      try {
        // 1. Procesar redirect de Google
        await AuthService.handleGoogleRedirectResult()
            .catchError((_) => null);
        debugPrint('🔵 Splash: redirect procesado, currentUser=${AuthService.currentUser?.email}');

        // 2. Esperar authState con timeout generoso
        user = await AuthService.authStateChanges
            .first
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
        debugPrint('🔵 Splash: authState user=${user?.email}');

        // 3. Si authState emitió null pero estamos regresando de redirect,
        //    esperar activamente hasta 10s a que Firebase confirme la sesión
        if (user == null) {
          user = await AuthService.waitForAuthAfterRedirect(maxSeconds: 10);
          debugPrint('🔵 Splash: waitForAuth user=${user?.email}');
        }
      } catch (e) {
        debugPrint('🔴 Splash error: $e');
        user = null;
      }

      // Fallback final
      user ??= AuthService.currentUser;
      debugPrint('🔵 Splash: user final=${user?.email}, role=${StorageService.getUserRole()}');

      if (!mounted) return;

      Widget nextScreen;

      if (user == null) {
        // Sin sesión → cerrar sesión Firebase por si hay estado residual
        await AuthService.signOut().catchError((_) => null);
        StorageService.clearAll();
        nextScreen = const WelcomeScreen();
      } else {
        // Verificar email antes de continuar (solo para registro con email/password)
        await AuthService.reloadUser();
        final isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');
        if (!isGoogleUser && !AuthService.isEmailVerified) {
          nextScreen = const EmailVerificationScreen();
        } else {
          // Con sesión → cargar perfil completo de Firestore
          await AuthService.loadProfileToStorage();
          final role = StorageService.getUserRole() ?? '';
          debugPrint('🔵 Splash: role=$role, isGoogle=$isGoogleUser');

          if (role.isEmpty) {
            // Usuario autenticado pero sin rol ni perfil en Firestore
            // → sesión huérfana, cerrar y mandar a Welcome
            await AuthService.signOut().catchError((_) => null);
            StorageService.clearAll();
            nextScreen = const WelcomeScreen();
          } else {
            final name = StorageService.getName()
                ?? user.displayName
                ?? 'Usuario';
            final profession = StorageService.getProfession()
                ?? (role == 'company' ? 'Empresa' : 'Candidato');
            nextScreen = FeedScreen(
              name: name,
              profession: profession,
              role: role,
            );
          }
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // PARTÍCULAS FLOTANTES
            AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _ParticlePainter(_particleController.value),
              ),
            ),

            // CONTENIDO CENTRAL
            AnimatedBuilder(
              animation: Listenable.merge([_mainController, _pulseController]),
              builder: (_, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO CON PULSO
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.handshake, color: Color(0xFF1565C0), size: 60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // NOMBRE
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: const Text(
                          "RightJob",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // TAGLINE
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "El trabajo correcto te está esperando",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BARRA DE PROGRESO INFERIOR
            Positioned(
              bottom: 60,
              left: 60,
              right: 60,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (_, __) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: Colors.white,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _progressController.value < 0.4
                          ? "Iniciando..."
                          : _progressController.value < 0.8
                              ? "Cargando tu perfil..."
                              : "¡Listo!",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // VERSION
            Positioned(
              bottom: 24,
              left: 0, right: 0,
              child: Center(
                child: Text(
                  "v1.0.0",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PARTÍCULAS FLOTANTES
class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles = List.generate(18, (i) => _Particle(i));

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final double t = (progress + p.offset) % 1.0;
      final double x = p.x * size.width;
      final double y = size.height - (t * (size.height + 60)) + 30;
      final double opacity = sin(t * pi).clamp(0.0, 1.0) * p.maxOpacity;
      final double radius = p.size * (0.7 + 0.3 * sin(t * pi * 2));

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  late double x;
  late double offset;
  late double size;
  late double maxOpacity;

  _Particle(int seed) {
    final rng = Random(seed * 137);
    x = rng.nextDouble();
    offset = rng.nextDouble();
    size = 2.0 + rng.nextDouble() * 4.0;
    maxOpacity = 0.08 + rng.nextDouble() * 0.18;
  }
}