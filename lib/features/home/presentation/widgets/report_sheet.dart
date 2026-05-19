import 'package:flutter/material.dart';

import '../../../../theme/style_guide.dart';
import '../../data/repositories/report_repository.dart';

class ReportSheet extends StatefulWidget {
  final String title;
  final Future<void> Function(ReportReason) onSubmit;

  const ReportSheet._({required this.title, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Future<void> Function(ReportReason) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReportSheet._(title: title, onSubmit: onSubmit),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

enum _SheetState { picking, loading, success, alreadyReported, error }

class _ReportSheetState extends State<ReportSheet> {
  ReportReason? _selected;
  _SheetState _state = _SheetState.picking;

  Future<void> _submit() async {
    final reason = _selected;
    if (reason == null) return;

    setState(() => _state = _SheetState.loading);

    try {
      await widget.onSubmit(reason);
      if (!mounted) return;
      setState(() => _state = _SheetState.success);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _state = isAlreadyReported(e)
            ? _SheetState.alreadyReported
            : _SheetState.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.grayscaleWhite;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.grayscaleLine;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        0,
        12,
        0,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (_state == _SheetState.success ||
              _state == _SheetState.alreadyReported)
            _buildDoneState(isDark)
          else if (_state == _SheetState.error)
            _buildErrorState(isDark)
          else
            _buildPickerState(isDark, borderColor),
        ],
      ),
    );
  }

  Widget _buildPickerState(bool isDark, Color borderColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            widget.title,
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            'Why are you reporting this?',
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
        ),
        ...ReportReason.values.map(
          (reason) => _ReasonTile(
            reason: reason,
            isSelected: _selected == reason,
            isDark: isDark,
            borderColor: borderColor,
            onTap: () => setState(() => _selected = reason),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selected != null && _state != _SheetState.loading)
                  ? _submit
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDefault,
                disabledBackgroundColor: isDark
                    ? AppColors.darkBorder
                    : AppColors.grayscaleSecondaryButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _state == _SheetState.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit report',
                      style: AppTypography.textSmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneState(bool isDark) {
    final isAlready = _state == _SheetState.alreadyReported;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.successDefault.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.successDefault,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isAlready ? 'Already reported' : 'Report submitted',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAlready
                ? "You've already reported this. We're looking into it."
                : "Thank you. Our team will review this report.",
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Done',
                style: AppTypography.textSmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.errorDark.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.errorDark,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Something went wrong',
            style: AppTypography.displaySmallBold.copyWith(
              fontSize: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.grayscaleTitleActive,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Could not submit your report. Please try again.',
            textAlign: TextAlign.center,
            style: AppTypography.textSmall.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.grayscaleBodyText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.grayscaleLine,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTypography.textSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.grayscaleBodyText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _state = _SheetState.picking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDefault,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Try again',
                    style: AppTypography.textSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ReportReason reason;
  final bool isSelected;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason.label,
                style: AppTypography.textSmall.copyWith(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.grayscaleTitleActive,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDefault
                      : borderColor,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
