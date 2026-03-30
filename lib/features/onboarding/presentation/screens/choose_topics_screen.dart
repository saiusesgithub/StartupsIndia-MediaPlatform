import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';
import '../../../../core/presentation/widgets/selectable_topic_chip.dart';

class ChooseTopicsScreen extends StatefulWidget {
  const ChooseTopicsScreen({super.key});

  @override
  State<ChooseTopicsScreen> createState() => _ChooseTopicsScreenState();
}

class _ChooseTopicsScreenState extends State<ChooseTopicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _topics = [
    'National', 'International', 'Sport', 'Lifestyle', 'Business', 'Health', 
    'Fashion', 'Technology', 'Science', 'Art', 'Politics'
  ];
  
  final Set<String> _selectedTopics = {};
  
  List<String> get _filteredTopics {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _topics;
    return _topics.where((t) => t.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
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
                    'Choose your Topics',
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
                            color: const Color(0xFFA0A3BD), // Grayscale/Placeholder
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
            
            // Topics Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filteredTopics.map((topic) {
                    return SelectableTopicChip(
                      label: topic,
                      isSelected: _selectedTopics.contains(topic),
                      onTap: () => _toggleTopic(topic),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/news-sources');
                },
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
