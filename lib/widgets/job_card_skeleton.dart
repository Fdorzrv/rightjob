import 'package:flutter/material.dart';

/// Shimmer effect sin paquetes externos.
/// Usa AnimationController + LinearGradient animado para simular la carga.
class JobCardSkeleton extends StatefulWidget {
  const JobCardSkeleton({super.key});

  @override
  State<JobCardSkeleton> createState() => _JobCardSkeletonState();
}

class _JobCardSkeletonState extends State<JobCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Fondo base gris
                Container(color: Colors.grey[300]),

                // Capa shimmer animada
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Color(0xFFE0E0E0),
                          Color(0xFFF5F5F5),
                          Color(0xFFE0E0E0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        transform: _SlidingGradientTransform(_animation.value),
                      ),
                    ),
                  ),
                ),

                // Contenido skeleton (imita el layout de JobCard)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x44BDBDBD)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Etiqueta salario
                        _SkeletonBox(width: 80, height: 24, radius: 10),
                        const SizedBox(height: 12),
                        // Nombre
                        _SkeletonBox(width: 200, height: 22, radius: 6),
                        const SizedBox(height: 8),
                        // Subtítulo
                        _SkeletonBox(width: 140, height: 16, radius: 6),
                        const SizedBox(height: 10),
                        // Bio línea 1
                        _SkeletonBox(width: double.infinity, height: 12, radius: 4),
                        const SizedBox(height: 6),
                        // Bio línea 2
                        _SkeletonBox(width: 180, height: 12, radius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Caja gris para imitar un bloque de texto o imagen
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[400]!.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Transforma el gradiente para que se deslice horizontalmente
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}