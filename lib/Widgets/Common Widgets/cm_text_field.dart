import 'package:flutter/material.dart';
import 'package:mockup/Colors/app_colors.dart';

/// A labelled form field with a reserved error slot.
///
/// Two decisions worth keeping:
///
/// * The label sits **above** the field rather than acting as a floating
///   placeholder. A placeholder that doubles as a label disappears the moment
///   the user types, which is the point at which they most need to know what
///   the field wanted — and it defeats screen readers, which read the hint
///   only while the field is empty.
/// * The error slot always occupies its line, so validating a field does not
///   shove the layout (and the submit button) downwards under the user's
///   thumb mid-tap.
class CmTextField extends StatelessWidget {
  const CmTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          // start, not left: mirrors correctly in Arabic.
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 16, color: AppColors.deepNavy),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffix,
            // 56dp of vertical room: comfortably past the 48dp minimum target
            // even before the OS text-scale multiplier is applied.
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: _border(AppColors.borderGray),
            enabledBorder: _border(
              hasError ? AppColors.dangerRed : AppColors.borderGray,
            ),
            focusedBorder: _border(
              hasError ? AppColors.dangerRed : AppColors.deepNavy,
              width: 2,
            ),
            // The message is rendered below instead of by InputDecoration so
            // its height can be reserved whether or not there is an error.
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),
        // Reserved: keeps the button from jumping when validation fires.
        SizedBox(
          height: 20,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      // 4.53:1 on white — AA for body text. The previous
                      // red-on-navy error was 4.44:1 and failed.
                      color: AppColors.dangerRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
