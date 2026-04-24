import 'package:flutter/material.dart';

class HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const HoverIconButton({Key? key, required this.icon, required this.onPressed})
    : super(key: key);

  @override
  _HoverIconButtonState createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.3 : 1.1), // agranda al hacer hover
          child: Icon(
            widget.icon,
            size: 40,
            color: _isHovered ? Colors.white : Colors.black, // cambia color
          ),
        ),
      ),
    );
  }
}
