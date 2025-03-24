import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../config/game_config/constants.dart';

class RippleIcon extends StatefulWidget {
  const RippleIcon({
    super.key,
    required this.onTap,
    required this.icon,
    required this.includeShadows,
  });

  final VoidCallback onTap;
  final Icon icon;
  final bool includeShadows;

  @override
  State<RippleIcon> createState() => _RippleIconState();
}

class _RippleIconState extends State<RippleIcon>
    with SingleTickerProviderStateMixin {
  // animate the shadows' opacity
  late AnimationController animationController;
  late Animation<double> sizeAnimation;
  late Animation<double> shadowAnimation;
  bool isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulsatingIconAnimation();
  }

  void _pulsatingIconAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    sizeAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut));
    shadowAnimation = Tween<double>(begin: 2, end: 6).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    // reverse + loop animation
    animationController.repeat(reverse: true);
  }

  // trigger single reverse animation
  Future<void> _triggerShrinkExitAnimation() async {
    // haptic feedback
    HapticFeedback.heavyImpact();

    final originalDuration = animationController.duration;

    animationController.stop();
    animationController.value = 1;
    animationController.duration = const Duration(milliseconds: 300);

    try {
      await animationController.reverse();
    } finally {
      if (mounted) {
        // restore original duration
        animationController.duration = originalDuration;
        animationController.reset();
        animationController.repeat(reverse: true);

        widget.onTap();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!animationController.isAnimating) {
      animationController.repeat(reverse: true);
    }
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
            Transform.scale(
              scale: sizeAnimation.value,
              child: GestureDetector(
                onTapDown: (_) => setState(() => isPressed = true),
                onTapUp: (_) => setState(() => isPressed = false),
                onTapCancel: () => setState(() => isPressed = false),
                onTap: _triggerShrinkExitAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: widget.includeShadows
                        ? [1, 2, 3]
                            .map(
                              (i) => BoxShadow(
                                color: colorGrey400.withAlpha((30 / i).round()),
                                spreadRadius: shadowAnimation.value * i,
                              ),
                            )
                            .toList()
                        : null,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 3000),
                    child: widget.icon,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
