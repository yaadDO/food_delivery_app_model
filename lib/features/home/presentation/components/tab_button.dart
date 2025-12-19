import 'package:flutter/material.dart';

class TabButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  const TabButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.isSelected,
  });

  @override
  State<TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _colorController;

  final Gradient _selectedGradient = const LinearGradient(
    colors: [Colors.cyan, Color(0xFF00BCD4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack)
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant TabButton oldWidget) {
    if (widget.isSelected != oldWidget.isSelected) {
      widget.isSelected ? _scaleController.forward() : _scaleController.reverse();
      widget.isSelected ? _colorController.forward() : _colorController.reverse();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _scaleController.forward().then((_) => _scaleController.reverse());
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _colorController,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyan.withOpacity(_colorController.value * 0.1),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) => _selectedGradient.createShader(bounds),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Icon(
                        widget.icon,
                        size: 24,
                        color: widget.isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.title,
              key: ValueKey<bool>(widget.isSelected),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.isSelected
                    ? Colors.cyan
                    : Colors.grey[400],
                letterSpacing: widget.isSelected ? 0.5 : 0,
              ),
            ),
          ),
          // Animated underline
          if (widget.isSelected)
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.scale(
                  scaleX: value,
                  child: Container(
                    height: 2,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: _selectedGradient,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}