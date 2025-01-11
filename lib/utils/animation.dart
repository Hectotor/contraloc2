import 'package:flutter/material.dart';

class ArrowAnimation extends StatefulWidget {
  const ArrowAnimation({Key? key}) : super(key: key);

  @override
  State<ArrowAnimation> createState() => _ArrowAnimationState();
}

class _ArrowAnimationState extends State<ArrowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<Offset> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _buttonAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: const Offset(0, 0.5),
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _buttonAnimation,
      child: const Icon(
        Icons.arrow_downward_outlined,
        color: Color(0xFF08004D),
        size: 50,
      ),
    );
  }
}
