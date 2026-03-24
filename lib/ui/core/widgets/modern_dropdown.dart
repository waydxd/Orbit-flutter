import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

/// A modern dropdown field that opens a searchable bottom sheet.
class ModernDropdownField<T> extends StatelessWidget {
  final String label;
  final IconData? icon;
  final T? value;
  final String Function(T) displayStringForValue;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? placeholder;
  final bool searchable;
  final String? searchHint;

  const ModernDropdownField({
    required this.label,
    required this.value,
    required this.displayStringForValue,
    required this.items,
    required this.onChanged,
    super.key,
    this.icon,
    this.placeholder,
    this.searchable = false,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final displayText =
        hasValue ? displayStringForValue(value as T) : (placeholder ?? label);

    return GestureDetector(
      onTap: () => _openSelector(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: hasValue ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasValue) ...[
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    displayText,
                    style: TextStyle(
                      color:
                          hasValue ? AppColors.textPrimary : AppColors.grey400,
                      fontSize: hasValue ? 14 : 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: hasValue ? AppColors.primary : AppColors.grey400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _openSelector(BuildContext context) {
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _SelectorSheet<T>(
          title: label,
          items: items,
          selectedValue: value,
          displayStringForValue: displayStringForValue,
          searchable: searchable,
          searchHint: searchHint ?? 'Search $label...',
        );
      },
    ).then((selected) {
      if (selected != null) {
        onChanged(selected);
      }
    });
  }
}

class _SelectorSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) displayStringForValue;
  final bool searchable;
  final String searchHint;

  const _SelectorSheet({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.displayStringForValue,
    required this.searchable,
    required this.searchHint,
  });

  @override
  State<_SelectorSheet<T>> createState() => _SelectorSheetState<T>();
}

class _SelectorSheetState<T> extends State<_SelectorSheet<T>> {
  late TextEditingController _searchController;
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        final lower = query.toLowerCase();
        _filteredItems = widget.items.where((item) {
          return widget
              .displayStringForValue(item)
              .toLowerCase()
              .contains(lower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Cancel'),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ),
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: const TextStyle(
                      color: AppColors.grey400,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.grey400,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          Divider(height: 1, color: AppColors.grey200.withValues(alpha: 0.6)),
          Flexible(
            child: _filteredItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: AppColors.grey300,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: AppColors.grey400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedValue;
                      final displayText = widget.displayStringForValue(item);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(item),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayText,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
