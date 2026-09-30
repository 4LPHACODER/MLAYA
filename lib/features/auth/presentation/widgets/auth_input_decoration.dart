import 'package:flutter/material.dart';

InputDecoration buildAuthInputDecoration({
  required String labelText,
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: Icon(prefixIcon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAF6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: const Color(0xFF93A790).withValues(alpha: 0.25),
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF5E8D6A), width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB44545), width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB44545), width: 1.4),
    ),
    labelStyle: const TextStyle(
      color: Color(0xFF5C6D60),
      fontWeight: FontWeight.w500,
    ),
    hintStyle: TextStyle(color: const Color(0xFF667F6D).withValues(alpha: 0.7)),
    prefixIconColor: const Color(0xFF6E8573),
  );
}
