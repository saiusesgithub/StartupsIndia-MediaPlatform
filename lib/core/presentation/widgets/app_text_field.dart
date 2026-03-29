import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isPassword;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.isPassword = false,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: hasError ? AppColors.errorLight : AppColors.grayscaleWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hasError ? AppColors.errorDark : AppColors.grayscaleBodyText,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          obscureText: widget.isPassword ? _obscureText : false,
                          style: AppTypography.textSmall.copyWith(
                            color: AppColors.grayscaleTitleActive,
                          ),
                          onChanged: (value) {
                            field.didChange(value);
                          },
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      if (hasError && !widget.isPassword)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.close, color: AppColors.errorDark, size: 16),
                        ),
                      if (widget.isPassword)
                        IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.grayscaleTitleActive,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
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
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ],
    );
  }
}
