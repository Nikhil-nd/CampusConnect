 import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const AppSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
