import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.textSmall.copyWith(
            color: AppColors.grayscaleBodyText,
          ),
        ),
        const SizedBox(height: 4),
        FormField<String>(
          validator: widget.validator,
          builder: (field) {
            final hasError = field.hasError;

            // Border priority: error → focused (red) → default (grey)
            final borderColor = hasError
                ? AppColors.errorDark
                : _isFocused
                    ? AppColors.primaryDefault
                    : AppColors.grayscaleLine;

            final fillColor = hasError
                ? AppColors.errorLight
                : AppColors.grayscaleWhite;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: borderColor,
                      width: _isFocused && !hasError ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          obscureText: widget.isPassword ? _obscureText : false,
                          keyboardType: widget.isPassword
                              ? TextInputType.visiblePassword
                              : widget.keyboardType,
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleTitleActive,
                          ),
                          onChanged: field.didChange,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: AppTypography.textSmall.copyWith(
                              color: AppColors.grayscaleButtonText,
                            ),
                            // Suppress ALL theme borders — Container handles visuals
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            // Suppress theme fill so no grey appears
                            filled: true,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                          ),
                        ),
                      ),
                      if (hasError && !widget.isPassword)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.close,
                              color: AppColors.errorDark, size: 16),
                        ),
                      if (widget.isPassword)
                        IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.grayscaleButtonText,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                    ],
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      field.errorText ?? '',
                      style: AppTypography.textSmall.copyWith(
                        color: AppColors.errorDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
