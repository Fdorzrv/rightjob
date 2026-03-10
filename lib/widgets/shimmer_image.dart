import 'package:flutter/material.dart';

/// Imagen de red con shimmer mientras carga y fallback si falla
class ShimmerImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const ShimmerImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  @override
  State<ShimmerImage> createState() => _ShimmerImageState();
}

class _ShimmerImageState extends State<ShimmerImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _shimmer() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [
              (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
              _shimmerAnim.value.clamp(0.0, 1.0),
              (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
            ],
            colors: const [Color(0xFFE0E0E0), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = Image.network(
      widget.url,
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: child,
          );
        }
        return _shimmer();
      },
      errorBuilder: (_, __, ___) =>
          widget.fallback ??
          Container(
            color: const Color(0xFFE8EEF7),
            child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
          ),
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: img);
    }
    return img;
  }
}

/// CircleAvatar con shimmer mientras carga
class ShimmerAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final Widget? fallbackIcon;
  final Color? fallbackColor;

  const ShimmerAvatar({
    super.key,
    this.imageUrl,
    required this.radius,
    this.fallbackIcon,
    this.fallbackColor,
  });

  @override
  State<ShimmerAvatar> createState() => _ShimmerAvatarState();
}

class _ShimmerAvatarState extends State<ShimmerAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  bool _loaded = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    final double size = widget.radius * 2;

    if (widget.imageUrl == null || _error) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.fallbackColor ?? Colors.blue.shade100,
        child: widget.fallbackIcon ?? Icon(Icons.person, size: widget.radius, color: Colors.blue),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          widget.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              if (!_loaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _loaded = true);
                });
              }
              return child;
            }
            // Shimmer circular
            return AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      (_anim.value - 0.3).clamp(0.0, 1.0),
                      _anim.value.clamp(0.0, 1.0),
                      (_anim.value + 0.3).clamp(0.0, 1.0),
                    ],
                    colors: const [Color(0xFFE0E0E0), Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _error = true);
            });
            return CircleAvatar(
              radius: widget.radius,
              backgroundColor: widget.fallbackColor ?? Colors.blue.shade100,
              child: widget.fallbackIcon ?? Icon(Icons.person, size: widget.radius, color: Colors.blue),
            );
          },
        ),
      ),
    );
  }
}