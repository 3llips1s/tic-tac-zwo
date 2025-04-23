import 'package:flutter/material.dart';

class DisplayRippleIcon extends StatefulWidget {
  const DisplayRippleIcon({
    super.key,
    required this.icon,
    required this.rippleColor,
    this.shadowScale = 4.0, // Larger default shadow scale
  });

  final Icon icon;
  final Color rippleColor;
  final double shadowScale;

  @override
  State<DisplayRippleIcon> createState() => _DisplayRippleIconState();
}

class _DisplayRippleIconState extends State<DisplayRippleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> sizeAnimation;
  late Animation<double> shadowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Increase the scale range for more visible pulsation
    sizeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    // Significantly larger shadow range
    shadowAnimation = Tween<double>(begin: 5, end: widget.shadowScale * 5)
        .animate(CurvedAnimation(
            parent: animationController, curve: Curves.easeInOut));

    // Start repeating animation
    animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Container with rippling shadow effect
            Transform.scale(
              scale: sizeAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: widget.rippleColor.withOpacity(0.75),
                  shape: BoxShape.circle,
                  boxShadow: [1, 2]
                      .map(
                        (i) => BoxShadow(
                          color: widget.rippleColor.withAlpha((90 / i).round()),
                          spreadRadius: shadowAnimation.value * i,
                        ),
                      )
                      .toList(),
                ),
                child: Center(child: widget.icon),
              ),
            ),
          ],
        );
      },
    );
  }
}
