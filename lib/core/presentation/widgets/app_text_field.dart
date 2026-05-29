import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/style_guide.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.inputFormatters,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.textSmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.grayscaleBodyText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        FormField<String>(
          initialValue: widget.controller.text,
          validator: widget.validator == null
              ? null
              : (_) => widget.validator!(widget.controller.text),
          builder: (field) {
            final hasError = field.hasError;

            final borderColor = hasError
                ? AppColors.errorDark
                : _isFocused
                ? AppColors.primaryDefault
                : (isDark ? AppColors.darkBorder : AppColors.grayscaleLine);

            final fillColor = hasError
                ? (isDark ? const Color(0xFF2A1015) : AppColors.errorLight)
                : (isDark
                      ? AppColors.darkInputBackground
                      : AppColors.grayscaleWhite);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(10),
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
                          readOnly: widget.readOnly,
                          enabled: widget.enabled,
                          obscureText: widget.isPassword ? _obscureText : false,
                          keyboardType: widget.isPassword
                              ? TextInputType.visiblePassword
                              : widget.keyboardType,
                          inputFormatters: widget.inputFormatters,
                          style: AppTypography.textSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.grayscaleTitleActive,
                            fontSize: 14,
                          ),
                          onChanged: field.didChange,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: AppTypography.textSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary.withValues(
                                      alpha: 0.55,
                                    )
                                  : AppColors.grayscaleButtonText.withValues(
                                      alpha: 0.62,
                                    ),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (hasError && !widget.isPassword)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.close,
                            color: AppColors.errorDark,
                            size: 16,
                          ),
                        ),
                      if (widget.isPassword)
                        IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.grayscaleButtonText,
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
                    padding: const EdgeInsets.only(top: 5),
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
