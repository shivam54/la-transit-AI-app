import 'package:flutter/material.dart';

/// AmigoLogo
///
/// A reusable logo widget inspired by the Amigo AI mark:
/// - Gradient blue map-pin style base
/// - White chat bubble in the center
/// - Small orange "AI sparks" above the pin
class AmigoLogo extends StatelessWidget {
  final double size;

  const AmigoLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final pinSize = size;
    final bubbleSize = pinSize * 0.55;
    final sparkSize = pinSize * 0.12;

    return SizedBox(
      width: pinSize,
      height: pinSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Pin base (circle with subtle bottom point suggestion using shadow)
          Container(
            width: pinSize,
            height: pinSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00C6FF),
                  Color(0xFF0052D4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(pinSize * 0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: pinSize * 0.18,
                  offset: Offset(0, pinSize * 0.18),
                ),
              ],
            ),
          ),

          // Chat bubble
          Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(bubbleSize * 0.5),
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: bubbleSize * 0.7,
              color: const Color(0xFF0062A3),
            ),
          ),

          // AI sparks (three small dots above the logo)
          Positioned(
            top: -sparkSize * 0.4,
            right: pinSize * 0.14,
            child: Row(
              children: [
                _sparkDot(sparkSize, const Color(0xFFFFA726)),
                SizedBox(width: sparkSize * 0.15),
                _sparkDot(sparkSize * 0.9, const Color(0xFFFF7043)),
                SizedBox(width: sparkSize * 0.15),
                _sparkDot(sparkSize * 0.8, const Color(0xFFFFB300)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sparkDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: size * 0.9,
          ),
        ],
      ),
    );
  }
}


