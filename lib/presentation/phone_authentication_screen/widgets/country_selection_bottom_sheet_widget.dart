import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CountrySelectionBottomSheetWidget extends StatefulWidget {
  final Function(Map<String, String>) onCountrySelected;

  const CountrySelectionBottomSheetWidget({
    Key? key,
    required this.onCountrySelected,
  }) : super(key: key);

  @override
  State<CountrySelectionBottomSheetWidget> createState() =>
      _CountrySelectionBottomSheetWidgetState();
}

class _CountrySelectionBottomSheetWidgetState
    extends State<CountrySelectionBottomSheetWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCountries = [];

  final List<Map<String, String>> _countries = [
    {"name": "United States", "code": "+1", "flag": "🇺🇸"},
    {"name": "Canada", "code": "+1", "flag": "🇨🇦"},
    {"name": "United Kingdom", "code": "+44", "flag": "🇬🇧"},
    {"name": "Australia", "code": "+61", "flag": "🇦🇺"},
    {"name": "Germany", "code": "+49", "flag": "🇩🇪"},
    {"name": "France", "code": "+33", "flag": "🇫🇷"},
    {"name": "Italy", "code": "+39", "flag": "🇮🇹"},
    {"name": "Spain", "code": "+34", "flag": "🇪🇸"},
    {"name": "Japan", "code": "+81", "flag": "🇯🇵"},
    {"name": "South Korea", "code": "+82", "flag": "🇰🇷"},
    {"name": "China", "code": "+86", "flag": "🇨🇳"},
    {"name": "India", "code": "+91", "flag": "🇮🇳"},
    {"name": "Brazil", "code": "+55", "flag": "🇧🇷"},
    {"name": "Mexico", "code": "+52", "flag": "🇲🇽"},
    {"name": "Argentina", "code": "+54", "flag": "🇦🇷"},
    {"name": "Netherlands", "code": "+31", "flag": "🇳🇱"},
    {"name": "Sweden", "code": "+46", "flag": "🇸🇪"},
    {"name": "Norway", "code": "+47", "flag": "🇳🇴"},
    {"name": "Denmark", "code": "+45", "flag": "🇩🇰"},
    {"name": "Switzerland", "code": "+41", "flag": "🇨🇭"},
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = _countries
          .where((country) =>
              country["name"]!.toLowerCase().contains(query.toLowerCase()) ||
              country["code"]!.contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Select Country',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
          ),

          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                hintText: 'Search country...',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Countries list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return ListTile(
                  leading: Text(
                    country["flag"]!,
                    style: TextStyle(fontSize: 18.sp),
                  ),
                  title: Text(
                    country["name"]!,
                    style: AppTheme.lightTheme.textTheme.bodyLarge,
                  ),
                  trailing: Text(
                    country["code"]!,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    widget.onCountrySelected(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
