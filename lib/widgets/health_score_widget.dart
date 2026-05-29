import 'package:flutter/material.dart';

class HealthScoreWidget extends StatefulWidget {
  final int health;
  const HealthScoreWidget({super.key, required this.health});

  @override
  State<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends State<HealthScoreWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // The dynamic border glowing opacity breath: from 35% up to 95% opacity
    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // The beating heart animation
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.22), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.22, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int h = widget.health;
    
    // 🎨 Determine Semantic Theme Colors
    final Color themeColor = (h >= 90)
        ? const Color(0xFF1E8E3E) // Vibrant Green
        : (h >= 80)
            ? const Color(0xFFFF8F00) // Vibrant Amber
            : const Color(0xFFD50000); // Cherry Red

    // Lock physical heart color Strictly to Cherry Red (Color(0xFFD50000)) as requested by USER!
    const Color heartColor = Color(0xFFD50000); 

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final double currentOpacity = _pulseAnimation.value;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: themeColor.withOpacity(currentOpacity),
              width: 2.2, // Gorgeous high-definition border
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(currentOpacity * 0.18),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _heartScaleAnimation,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: heartColor, // 🔒 LOCKED to Pure Red
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "HEALTH",
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    "${h}%",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[850],
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
