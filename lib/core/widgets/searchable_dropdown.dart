import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:meal_app/core/theme/app_theme.dart';

class SearchableDropdown<T> extends FormField<T> {
  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final String hint;
  final bool isLoading;
  final Function(String)? onSearch;
  final VoidCallback? onInteraction;

  SearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    T? value,
    required FormFieldSetter<T> onChanged,
    FormFieldValidator<T>? validator,
    this.hint = 'Select an option',
    this.isLoading = false,
    this.onSearch,
    this.onInteraction,
  }) : super(
          initialValue: value,
          onSaved: onChanged,
          validator: validator,
          builder: (FormFieldState<T> state) {
            final isDark = Theme.of(state.context).brightness == Brightness.dark;
            final hasError = state.hasError;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    FocusScope.of(state.context).unfocus();
                    if (onInteraction != null) onInteraction();
                    _showSearchDialog(state.context, state, items, itemLabel, onSearch, isLoading);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasError 
                          ? Colors.red 
                          : (isDark ? Colors.white10 : Colors.black12)
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.value != null ? itemLabel(state.value as T) : hint,
                            style: TextStyle(
                              color: state.value != null 
                                ? (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight)
                                : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CupertinoActivityIndicator(radius: 8),
                          )
                        else
                          Icon(Icons.keyboard_arrow_down_rounded, 
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                      ],
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );

  static void _showSearchDialog<T>(
    BuildContext context, 
    FormFieldState<T> state,
    List<T> items,
    String Function(T) itemLabel,
    Function(String)? onSearch,
    bool isLoading,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _SearchDialog<T>(
              items: items,
              itemLabel: itemLabel,
              isLoading: isLoading,
              onSelected: (value) {
                state.didChange(value);
                state.save();
                Navigator.pop(context);
              },
              onSearch: onSearch,
            );
          }
        );
      },
    );
  }
}

class _SearchDialog<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) itemLabel;
  final Function(T) onSelected;
  final Function(String)? onSearch;
  final bool isLoading;

  const _SearchDialog({
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.onSearch,
    required this.isLoading,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  late List<T> filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(_SearchDialog<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filterItems(_searchController.text);
    }
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = widget.items
          .where((item) =>
              widget.itemLabel(item).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayItems = _searchController.text.isEmpty ? widget.items : filteredItems;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: isDark ? AppTheme.surfaceDark : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.isLoading && displayItems.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(radius: 12),
                    SizedBox(height: 16),
                    Text('Fetching latest data...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else if (displayItems.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No items found'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return ListTile(
                    title: Text(widget.itemLabel(item)),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      widget.onSelected(item);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

