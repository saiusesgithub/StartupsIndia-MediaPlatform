import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class SourceModel {
  final String name;
  final String logoUrl;
  bool isFollowing;

  SourceModel({
    required this.name,
    required this.logoUrl,
    this.isFollowing = false,
  });
}

class ChooseNewsSourcesScreen extends StatefulWidget {
  const ChooseNewsSourcesScreen({super.key});

  @override
  State<ChooseNewsSourcesScreen> createState() => _ChooseNewsSourcesScreenState();
}

class _ChooseNewsSourcesScreenState extends State<ChooseNewsSourcesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<SourceModel> _sources = [
    SourceModel(name: 'CNBC', logoUrl: 'assets/icons/cnbc.png'),
    SourceModel(name: 'VICE', logoUrl: 'assets/icons/vice.png'),
    SourceModel(name: 'Vox', logoUrl: 'assets/icons/vox.png'),
    SourceModel(name: 'BBC News', logoUrl: 'assets/icons/bbc.png'),
    SourceModel(name: 'SCMP', logoUrl: 'assets/icons/scmp.png'),
    SourceModel(name: 'CNN', logoUrl: 'assets/icons/cnn.png'),
    SourceModel(name: 'MSN', logoUrl: 'assets/icons/msn.png'),
    SourceModel(name: 'CNET', logoUrl: 'assets/icons/cnet.png'),
    SourceModel(name: 'USA Today', logoUrl: 'assets/icons/usa_today.png'),
    SourceModel(name: 'Time', logoUrl: 'assets/icons/time.png'),
    SourceModel(name: 'Buzzfeed', logoUrl: 'assets/icons/buzzfeed.png'),
    SourceModel(name: 'Daily Mail', logoUrl: 'assets/icons/daily_mail.png'),
  ];

  List<SourceModel> get _filteredSources {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _sources;
    return _sources.where((s) => s.name.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    // Navigate to Fill Profile – the last onboarding step
    Navigator.pushNamed(context, '/fill-profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: AppColors.grayscaleTitleActive),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Choose your News Sources',
                    style: AppTypography.linkMedium.copyWith(
                      color: AppColors.grayscaleTitleActive,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grayscaleWhite,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.grayscaleBodyText,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.textSmall.copyWith(
                          color: AppColors.grayscaleTitleActive,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: AppTypography.textSmall.copyWith(
                            color: const Color(0xFFA0A3BD),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.search, color: AppColors.grayscaleBodyText, size: 20),
                    ),
                  ],
                ),
              ),
            ),
            
            // Topics Grid -> ListView mapping Grid rows or GridView
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filteredSources.length,
                itemBuilder: (context, index) {
                  final source = _filteredSources[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grayscaleInputBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEEF0F4)), // soft border 
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Image wrapper
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              source.logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          source.name,
                          style: AppTypography.textMedium.copyWith(
                            color: AppColors.grayscaleTitleActive,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Follow button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                source.isFollowing = !source.isFollowing;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: source.isFollowing 
                                  ? AppColors.primaryDefault 
                                  : Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: AppColors.primaryDefault,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: source.isFollowing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check, size: 16, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Following',
                                        style: AppTypography.textSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Follow',
                                    style: AppTypography.textSmall.copyWith(
                                      color: AppColors.primaryDefault,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDefault,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Next',
                  style: AppTypography.linkMedium.copyWith(
                    color: AppColors.grayscaleWhite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
