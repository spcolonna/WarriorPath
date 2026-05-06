import 'package:flutter/material.dart';
import 'package:warrior_path/screens/WelcomeScreen.dart';
import 'package:warrior_path/screens/landing_screen.dart';

class AppSplashScreen extends StatefulWidget {
  final bool showLanding;

  const AppSplashScreen({super.key, required this.showLanding});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF1C1C1E);
  static const _gold = Color(0xFFFFD700);

  late AnimationController _ctrl;

  // SPC company logo: fade in 0→30% del timeline
  late Animation<double> _spcFade;

  // App logo: scale + fade in 15→55%
  late Animation<double> _appScale;
  late Animation<double> _appFade;

  // Título "WARRIOR PATH": slide + fade in 40→68%
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  // Tagline: fade in 55→78%
  late Animation<double> _taglineFade;

  // "by SPC" footer: fade in 65→85%
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _spcFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.30, curve: Curves.easeIn)),
    );

    _appScale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.15, 0.58, curve: Curves.elasticOut)),
    );

    _appFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.15, 0.32, curve: Curves.easeIn)),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.40, 0.68, curve: Curves.easeIn)),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.40, 0.68, curve: Curves.easeOut)));

    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.55, 0.78, curve: Curves.easeIn)),
    );

    _footerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.68, 0.88, curve: Curves.easeIn)),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _ctrl.forward();
    // Esperar que termine la animación + pausa para disfrutarla
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => widget.showLanding
            ? const LandingScreen()
            : const WelcomeScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo con resplandor dorado sutil en el centro
          Center(
            child: AnimatedBuilder(
              animation: _appFade,
              builder: (_, _) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.08 * _appFade.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal centrado
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo SPC (empresa) ──────────────────────────────────────
              FadeTransition(
                opacity: _spcFade,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo/spc_logo_compressed.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PRESENTS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Logo de la app ──────────────────────────────────────────
              ScaleTransition(
                scale: _appScale,
                child: FadeTransition(
                  opacity: _appFade,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.25),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/Logo.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.sports_martial_arts,
                          size: 120,
                          color: _gold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Nombre de la app ────────────────────────────────────────
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: const Text(
                    'WARRIOR PATH',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Tagline ─────────────────────────────────────────────────
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'Tu camino hacia la excelencia',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),

          // ── Footer "by SPC" en la parte inferior ──────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _footerFade,
              child: Column(
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo/spc_logo_compressed.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
}
