import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? null : double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style:
          FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: 22,
              vertical: compact ? 12 : 16,
            ),
            // Native file dialogs can pause painting before an ink ripple ends.
            splashFactory: NoSplash.splashFactory,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.transparent;
              }
              if (states.contains(WidgetState.focused)) {
                return const Color(0x337C3AED);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0x147C3AED);
              }
              return Colors.transparent;
            }),
          ),
    ),
  );
}
