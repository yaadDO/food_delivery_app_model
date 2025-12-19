import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(13),
        ),

        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
          borderRadius: BorderRadius.circular(13),
        ),

        hintText: hintText,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        fillColor: Theme.of(context).colorScheme.background,
        filled: true,
      ),
    );
  }
}