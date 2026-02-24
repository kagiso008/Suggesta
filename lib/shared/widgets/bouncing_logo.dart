import 'package:flutter/material.dart';

/// A widget that displays an image with a bouncing animation.
/// The animation repeats indefinitely, creating a bouncing effect.
class BouncingLogo extends StatefulWidget {
  /// The image asset path
  final String imagePath;

  /// The width of the logo
  final double width;

  /// The height of the logo
  final double height;

  /// The duration of one bounce cycle
  final Duration bounceDuration;

  /// The bounce height (as a fraction of the logo height)
  final double bounceHeight;

  /// Whether to show a shadow that scales with the bounce
  final bool showShadow;

  /// The color of the shadow
  final Color shadowColor;

  /// The blur radius of the shadow
  final double shadowBlurRadius;

  const BouncingLogo({
    super.key,
    required this.imagePath,
    this.width = 120,
    this.height = 120,
    this.bounceDuration = const Duration(milliseconds: 800),
    this.bounceHeight = 0.2,
    this.showShadow = true,
    this.shadowColor = Colors.black38,
    this.shadowBlurRadius = 10.0,
  });

  @override
  State<BouncingLogo> createState() => _BouncingLogoState();
}

class _BouncingLogoState extends State<BouncingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.bounceDuration,
      vsync: this,
    );

    // Create a bouncing animation using CurvedAnimation with bounceOut curve
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Create a shadow animation that scales with the bounce
    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0 - (widget.bounceHeight * 0.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start the animation and make it repeat forever
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate the vertical translation based on bounce animation
        final translateY =
            -widget.bounceHeight * widget.height * _bounceAnimation.value;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo image
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: widget.showShadow
                      ? [
                          BoxShadow(
                            color: widget.shadowColor,
                            blurRadius:
                                widget.shadowBlurRadius *
                                _shadowAnimation.value,
                            spreadRadius: 2.0 * _shadowAnimation.value,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.imagePath,
                    width: widget.width,
                    height: widget.height,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
