import 'package:flutter/material.dart';
import '../../../../theme/style_guide.dart';

class Country {
  final String name;
  final String flagPath;

  const Country({required this.name, required this.flagPath});
}

class SelectCountryScreen extends StatefulWidget {
  const SelectCountryScreen({super.key});

  @override
  State<SelectCountryScreen> createState() => _SelectCountryScreenState();
}

class _SelectCountryScreenState extends State<SelectCountryScreen> {
  final List<Country> _allCountries = const [
    Country(name: 'Argentina',      flagPath: 'assets/flags/ar.png'),
    Country(name: 'Australia',      flagPath: 'assets/flags/au.png'),
    Country(name: 'Bangladesh',     flagPath: 'assets/flags/bd.png'),
    Country(name: 'Brazil',         flagPath: 'assets/flags/br.png'),
    Country(name: 'Canada',         flagPath: 'assets/flags/ca.png'),
    Country(name: 'China',          flagPath: 'assets/flags/cn.png'),
    Country(name: 'Colombia',       flagPath: 'assets/flags/co.png'),
    Country(name: 'Egypt',          flagPath: 'assets/flags/eg.png'),
    Country(name: 'France',         flagPath: 'assets/flags/fr.png'),
    Country(name: 'Germany',        flagPath: 'assets/flags/de.png'),
    Country(name: 'India',          flagPath: 'assets/flags/in.png'),
    Country(name: 'Indonesia',      flagPath: 'assets/flags/id.png'),
    Country(name: 'Iran',           flagPath: 'assets/flags/ir.png'),
    Country(name: 'Italy',          flagPath: 'assets/flags/it.png'),
    Country(name: 'Japan',          flagPath: 'assets/flags/jp.png'),
    Country(name: 'Kenya',          flagPath: 'assets/flags/ke.png'),
    Country(name: 'Mexico',         flagPath: 'assets/flags/mx.png'),
    Country(name: 'Myanmar',        flagPath: 'assets/flags/mm.png'),
    Country(name: 'Nigeria',        flagPath: 'assets/flags/ng.png'),
    Country(name: 'Pakistan',       flagPath: 'assets/flags/pk.png'),
    Country(name: 'Philippines',    flagPath: 'assets/flags/ph.png'),
    Country(name: 'Russia',         flagPath: 'assets/flags/ru.png'),
    Country(name: 'Saudi Arabia',   flagPath: 'assets/flags/sa.png'),
    Country(name: 'South Africa',   flagPath: 'assets/flags/za.png'),
    Country(name: 'South Korea',    flagPath: 'assets/flags/kr.png'),
    Country(name: 'Spain',          flagPath: 'assets/flags/es.png'),
    Country(name: 'Tanzania',       flagPath: 'assets/flags/tz.png'),
    Country(name: 'Thailand',       flagPath: 'assets/flags/th.png'),
    Country(name: 'Turkey',         flagPath: 'assets/flags/tr.png'),
    Country(name: 'United Kingdom', flagPath: 'assets/flags/gb.png'),
    Country(name: 'United States',  flagPath: 'assets/flags/us.png'),
    Country(name: 'Vietnam',        flagPath: 'assets/flags/vn.png'),
  ];

  List<Country> _filteredCountries = [];
  Country? _selectedCountry;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCountries = List.from(_allCountries);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = _allCountries
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_selectedCountry == null) return;
    // Navigation placeholder – wire to next screen when ready
    print('Selected: ${_selectedCountry!.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayscaleWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.grayscaleTitleActive),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Select your Country',
                    style: AppTypography.linkMedium
                        .copyWith(color: AppColors.grayscaleTitleActive),
                  ),
                ],
              ),
            ),

            // ── Search Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grayscaleWhite,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.grayscaleBodyText, width: 1),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(Icons.search,
                          color: AppColors.grayscaleBodyText, size: 22),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.textSmall
                            .copyWith(color: AppColors.grayscaleTitleActive),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: AppTypography.textSmall.copyWith(
                              color: AppColors.grayscaleButtonText),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Country List ─────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredCountries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  final isSelected = _selectedCountry == country;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCountry = country),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryDefault
                            : AppColors.grayscaleInputBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          // Flag PNG – guaranteed to render on every platform
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.asset(
                              country.flagPath,
                              width: 32,
                              height: 22,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 32,
                                height: 22,
                                color: AppColors.grayscaleLine,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            country.name,
                            style: AppTypography.textMedium.copyWith(
                              color: isSelected
                                  ? AppColors.grayscaleWhite
                                  : AppColors.grayscaleBodyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Next Button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed:
                    _selectedCountry == null ? null : _onNextPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDefault,
                  disabledBackgroundColor:
                      AppColors.grayscaleSecondaryButton,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Next',
                  style: AppTypography.linkMedium.copyWith(
                    color: _selectedCountry == null
                        ? AppColors.grayscaleButtonText
                        : AppColors.grayscaleWhite,
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
