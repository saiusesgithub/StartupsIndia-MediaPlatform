import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _selectedOption = 0; // 0 for Email, 1 for SMS

  Widget _buildOptionCard({
    required int index,
    required String iconAsset,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.secondaryButton,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 64,
                  height: 64,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.titleActive,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            Radio<int>(
              value: index,
              groupValue: _selectedOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedOption = value;
                  });
                }
              },
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.titleActive),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Forgot\nPassword ?',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Don\'t worry! it happens. Please select the\nemail or number associated with your account.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.bodyText,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    index: 0,
                    iconAsset: 'assets/icons/mail.svg',
                    title: 'via Email:',
                    subtitle: 'example@youremail.com',
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    index: 1,
                    iconAsset: 'assets/icons/message.svg',
                    title: 'via SMS:',
                    subtitle: '+62-8421-4512-2531',
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: AppTheme.background,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
                  offset: Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  'Submit',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
