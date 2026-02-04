import 'package:flutter/material.dart';

class DefaultTextBox extends StatelessWidget {
  final String label;
  final bool obscureText;

  const DefaultTextBox({
    super.key,
    required this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
