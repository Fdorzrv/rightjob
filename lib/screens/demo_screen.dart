import 'package:flutter/material.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> with TickerProviderStateMixin {
  int _step = 0;
  late AnimationController _tooltipController;
  late AnimationController _matchController;
  late Animation<double> _tooltipFade;
  late Animation<double> _matchScale;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _showMatch = false;
  bool _cardDismissed = false;

  late AnimationController _flyController;
  late Animation<Offset> _flyAnim;
  bool _isFlying = false;

  final List<_DemoProfile> _profiles = [
    _DemoProfile(name:"Carlos Méndez",role:"UI/UX Designer",location:"Remoto",salary:"MXN \$50,000 - \$60,000",skills:["Figma","Flutter","Prototipado"],color:const Color(0xFF1565C0),emoji:"🎨"),
    _DemoProfile(name:"TechCorp MX",role:"Empresa de Software",location:"CDMX",salary:"MXN \$40,000 - \$80,000",skills:["React","Node.js","AWS"],color:const Color(0xFF2E7D32),emoji:"🏢"),
    _DemoProfile(name:"Ana Rodríguez",role:"Product Manager",location:"Monterrey",salary:"MXN \$70,000 - \$90,000",skills:["Agile","Roadmaps","Jira"],color:const Color(0xFF6A1B9A),emoji:"📊"),
    _DemoProfile(name:"Innovatech",role:"Startup de IA",location:"Guadalajara",salary:"MXN \$60,000 - \$100,000",skills:["Python","ML","Data"],color:const Color(0xFFC62828),emoji:"🤖"),
  ];

  final List<_TourStep> _steps = [
    _TourStep(title:"¡Desliza a la derecha! 👉",description:"¿Te interesa este perfil? Arrastra la tarjeta hacia la derecha para hacer match.",icon:Icons.swipe_right_rounded,requiredSwipe:SwipeRequirement.right),
    _TourStep(title:"Ahora a la izquierda 👈",description:"¿No es lo que buscas? Desliza a la izquierda para pasar al siguiente perfil.",icon:Icons.swipe_left_rounded,requiredSwipe:SwipeRequirement.left),
    _TourStep(title:"¡Es un Match! 🎉",description:"Cuando ambos se eligen mutuamente se conectan y pueden chatear directamente.",icon:Icons.handshake_rounded,requiredSwipe:SwipeRequirement.none),
    _TourStep(title:"Chat directo 💬",description:"Sin intermediarios. Comparte tu CV y coordina entrevistas en tiempo real.",icon:Icons.chat_bubble_rounded,requiredSwipe:SwipeRequirement.none),
  ];

  @override
  void initState() {
    super.initState();
    _tooltipController = AnimationController(vsync:this,duration:const Duration(milliseconds:400));
    _tooltipFade = CurvedAnimation(parent:_tooltipController,curve:Curves.easeOut);
    _matchController = AnimationController(vsync:this,duration:const Duration(milliseconds:600));
    _matchScale = CurvedAnimation(parent:_matchController,curve:Curves.elasticOut);
    _flyController = AnimationController(vsync:this,duration:const Duration(milliseconds:350));
    _flyAnim = Tween<Offset>(begin:Offset.zero,end:Offset.zero).animate(_flyController);
    _tooltipController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoAdvance());
  }

  @override
  void dispose() {
    _tooltipController.dispose();
    _matchController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  void _checkAutoAdvance() {
    if (_step == 2 && !_showMatch) _triggerMatch();
  }

  Future<void> _triggerMatch() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showMatch = true);
    _matchController.forward();
    await Future.delayed(const Duration(milliseconds: 4500));
    if (!mounted) return;
    _matchController.reverse();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showMatch = false);
    _advanceStep();
  }

  void _onDragStart(DragStartDetails d) {
    if (_isFlying || _cardDismissed) return;
    setState(() { _isDragging = true; _dragOffset = Offset.zero; });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_isFlying || _cardDismissed) return;
    setState(() => _dragOffset += d.delta);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    if (_isFlying || _cardDismissed) return;
    final step = _steps[_step];
    const threshold = 80.0;
    final isRight = _dragOffset.dx > threshold;
    final isLeft = _dragOffset.dx < -threshold;
    if (step.requiredSwipe == SwipeRequirement.right && isRight) {
      await _flyCard(right: true);
      _advanceStep();
    } else if (step.requiredSwipe == SwipeRequirement.left && isLeft) {
      await _flyCard(right: false);
      _advanceStep();
    } else {
      setState(() { _isDragging = false; _dragOffset = Offset.zero; });
    }
  }

  Future<void> _flyCard({required bool right}) async {
    setState(() => _isFlying = true);
    _flyAnim = Tween<Offset>(begin:_dragOffset,end:Offset(right ? 500 : -500, _dragOffset.dy - 100))
        .animate(CurvedAnimation(parent:_flyController,curve:Curves.easeInCubic));
    _flyController.reset();
    await _flyController.forward();
    if (mounted) setState(() { _cardDismissed = true; _isFlying = false; _dragOffset = Offset.zero; });
  }

  void _advanceStep() {
    if (_step < _steps.length - 1) {
      _tooltipController.reset();
      setState(() {
        _step++;
        _cardDismissed = false;
        _isDragging = false;
        _dragOffset = Offset.zero;
        if (_profiles.length > 1) _profiles.removeAt(0);
      });
      _flyController.reset();
      _tooltipController.forward();
      _checkAutoAdvance();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final profile = _profiles.isNotEmpty ? _profiles[0] : null;
    final nextProfile = _profiles.length > 1 ? _profiles[1] : null;
    final isLastStep = _step == _steps.length - 1;
    final needsSwipe = step.requiredSwipe != SwipeRequirement.none;
    final rotation = _dragOffset.dx / 300.0;
    final swipeRightProgress = (_dragOffset.dx / 100.0).clamp(0.0, 1.0);
    final swipeLeftProgress = (-_dragOffset.dx / 100.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF0D2B5E), Color(0xFF1565C0)],
        ))),
        SafeArea(child: Column(children: [
          // TOP BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color:Colors.white.withValues(alpha:0.15),shape:BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              Text("Demo interactiva", style: TextStyle(color:Colors.white.withValues(alpha:0.8),fontSize:14,fontWeight:FontWeight.w600)),
              const Spacer(),
              Row(children: List.generate(_steps.length, (i) => Container(
                width: i == _step ? 18 : 6, height: 6,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: i == _step ? Colors.white : Colors.white.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ))),
            ]),
          ),
          const SizedBox(height: 16),

          // TOOLTIP
          FadeTransition(
            opacity: _tooltipFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color:Colors.white.withValues(alpha:0.2)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color:Colors.white.withValues(alpha:0.15),shape:BoxShape.circle),
                    child: Icon(step.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(step.title, style: const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:15)),
                    const SizedBox(height: 4),
                    Text(step.description, style: TextStyle(color:Colors.white.withValues(alpha:0.75),fontSize:12,height:1.4)),
                  ])),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // TARJETA
          Expanded(child: Stack(alignment: Alignment.center, children: [
            // Tarjeta de fondo
            if (nextProfile != null && !_cardDismissed)
              Transform.scale(scale: 0.93, child: _buildCard(nextProfile, faded: true)),

            // Tarjeta principal draggable
            if (profile != null && !_cardDismissed)
              GestureDetector(
                onPanStart: needsSwipe ? _onDragStart : null,
                onPanUpdate: needsSwipe ? _onDragUpdate : null,
                onPanEnd: needsSwipe ? _onDragEnd : null,
                child: AnimatedBuilder(
                  animation: _flyController,
                  builder: (_, child) {
                    final offset = _isFlying ? _flyAnim.value : _dragOffset;
                    return Transform.translate(
                      offset: offset,
                      child: Transform.rotate(
                        angle: _isFlying ? (_flyAnim.value.dx > 0 ? 0.3 : -0.3) : rotation,
                        child: child,
                      ),
                    );
                  },
                  child: Stack(children: [
                    _buildCard(profile),
                    // Overlay LIKE
                    if (swipeRightProgress > 0.1)
                      Positioned.fill(child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.green.withValues(alpha: swipeRightProgress * 0.4),
                        ),
                        child: Align(alignment: Alignment.topLeft, child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Opacity(opacity: swipeRightProgress, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal:14,vertical:8),
                            decoration: BoxDecoration(border:Border.all(color:Colors.green,width:3),borderRadius:BorderRadius.circular(12)),
                            child: const Text("LIKE ✅", style: TextStyle(color:Colors.green,fontWeight:FontWeight.w900,fontSize:22)),
                          )),
                        )),
                      )),
                    // Overlay NOPE
                    if (swipeLeftProgress > 0.1)
                      Positioned.fill(child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.red.withValues(alpha: swipeLeftProgress * 0.4),
                        ),
                        child: Align(alignment: Alignment.topRight, child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Opacity(opacity: swipeLeftProgress, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal:14,vertical:8),
                            decoration: BoxDecoration(border:Border.all(color:Colors.red,width:3),borderRadius:BorderRadius.circular(12)),
                            child: const Text("NOPE ❌", style: TextStyle(color:Colors.red,fontWeight:FontWeight.w900,fontSize:22)),
                          )),
                        )),
                      )),
                  ]),
                ),
              ),

            // Hint animado
            if (needsSwipe && !_isDragging && !_cardDismissed)
              Positioned(bottom: 20, child: _SwipeHint(right: step.requiredSwipe == SwipeRequirement.right)),

            // Match overlay
            if (_showMatch)
              ScaleTransition(scale: _matchScale, child: _buildMatchOverlay()),
          ])),

          // BOTÓN — solo en pasos sin swipe
          if (!needsSwipe)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _advanceStep,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(isLastStep ? "¡Listo, quiero registrarme!" : "Siguiente",
                      style: const TextStyle(fontWeight:FontWeight.bold,fontSize:15)),
                    const SizedBox(width: 8),
                    Icon(isLastStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 18),
                  ]),
                ),
              ),
            )
          else
            const SizedBox(height: 28),
        ])),
      ]),
    );
  }

  Widget _buildCard(_DemoProfile profile, {bool faded = false}) {
    final sh = MediaQuery.of(context).size.height;
    final h = sh < 700 ? 260.0 : 330.0;
    final w = sh < 700 ? 260.0 : 300.0;
    return Opacity(
      opacity: faded ? 0.65 : 1.0,
      child: Container(
        width: w, height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
            colors:[profile.color,profile.color.withValues(alpha:0.7),Colors.black.withValues(alpha:0.5)]),
          boxShadow:[BoxShadow(color:profile.color.withValues(alpha:0.4),blurRadius:20,offset:const Offset(0,8))],
        ),
        child: Padding(
          padding: EdgeInsets.all(sh < 700 ? 16 : 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: sh < 700 ? 50 : 70, height: sh < 700 ? 50 : 70,
              decoration: BoxDecoration(color:Colors.white.withValues(alpha:0.2),shape:BoxShape.circle),
              child: Center(child: Text(profile.emoji, style: TextStyle(fontSize: sh < 700 ? 24 : 32))),
            ),
            const Spacer(),
            Wrap(spacing:6,runSpacing:6,children:profile.skills.map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
              decoration: BoxDecoration(
                color:Colors.white.withValues(alpha:0.2),
                borderRadius:BorderRadius.circular(20),
                border:Border.all(color:Colors.white.withValues(alpha:0.3)),
              ),
              child: Text(s, style: const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)),
            )).toList()),
            const SizedBox(height: 12),
            Text(profile.name, style: TextStyle(color:Colors.white,fontSize: sh < 700 ? 18 : 22,fontWeight:FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children:[
              const Icon(Icons.location_on,color:Colors.white70,size:13),
              const SizedBox(width:4),
              Text("${profile.role} • ${profile.location}",style:TextStyle(color:Colors.white.withValues(alpha:0.8),fontSize:13)),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:12,vertical:6),
              decoration: BoxDecoration(color:Colors.green.withValues(alpha:0.85),borderRadius:BorderRadius.circular(20)),
              child: Text(profile.salary, style: const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMatchOverlay() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors:[Color(0xFF1565C0),Color(0xFF42A5F5)],begin:Alignment.topLeft,end:Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow:[BoxShadow(color:Colors.blue.withValues(alpha:0.5),blurRadius:30,spreadRadius:5)],
      ),
      child: Column(mainAxisSize:MainAxisSize.min,children:[
        const Text("🎉", style: TextStyle(fontSize:64)),
        const SizedBox(height:12),
        const Text("¡Es un Match!", style: TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.bold)),
        const SizedBox(height:8),
        Text("Ahora pueden chatear directamente",
          textAlign:TextAlign.center,
          style:TextStyle(color:Colors.white.withValues(alpha:0.85),fontSize:14)),
      ]),
    );
  }
}

// ── SWIPE HINT ───────────────────────────────────────────────────────────────
class _SwipeHint extends StatefulWidget {
  final bool right;
  const _SwipeHint({required this.right});
  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync:this,duration:const Duration(milliseconds:900))..repeat(reverse:true);
    _anim = Tween<double>(begin:0,end:14).animate(CurvedAnimation(parent:_c,curve:Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(mainAxisSize:MainAxisSize.min,children:[
        if (!widget.right) ...[
          Transform.translate(offset:Offset(-_anim.value,0),
            child:Icon(Icons.arrow_back_ios_rounded,color:Colors.white.withValues(alpha:0.9),size:20)),
          const SizedBox(width:4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal:16,vertical:10),
          decoration: BoxDecoration(
            color: widget.right ? Colors.green.withValues(alpha:0.85) : Colors.red.withValues(alpha:0.85),
            borderRadius: BorderRadius.circular(30),
            boxShadow:[BoxShadow(color:(widget.right?Colors.green:Colors.red).withValues(alpha:0.4),blurRadius:12)],
          ),
          child: Text(widget.right?"Desliza la tarjeta →":"← Desliza la tarjeta",
            style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:13)),
        ),
        if (widget.right) ...[
          const SizedBox(width:4),
          Transform.translate(offset:Offset(_anim.value,0),
            child:Icon(Icons.arrow_forward_ios_rounded,color:Colors.white.withValues(alpha:0.9),size:20)),
        ],
      ]),
    );
  }
}

// ── MODELOS ──────────────────────────────────────────────────────────────────
class _DemoProfile {
  final String name,role,location,salary,emoji;
  final List<String> skills;
  final Color color;
  const _DemoProfile({required this.name,required this.role,required this.location,required this.salary,required this.skills,required this.color,required this.emoji});
}

enum SwipeRequirement { right, left, none }

class _TourStep {
  final String title,description;
  final IconData icon;
  final SwipeRequirement requiredSwipe;
  const _TourStep({required this.title,required this.description,required this.icon,required this.requiredSwipe});
}