import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    required this.onFilterPressed,
    this.onSearchTap,
    required this.filterActive,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback onFilterPressed;
  final bool filterActive;

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    widget.controller?.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final borderColor = focused
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.16);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1C4A94).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.72),
            size: 22,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: widget.controller,
              readOnly: widget.onSearchTap != null,
              onTap: widget.onSearchTap,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: AppColors.gradientEnd,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                hintText: 'Search sessions, speakers, topics...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (widget.controller != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller!,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox(width: 4);
                return IconButton(
                  onPressed: _clear,
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 6, 6),
            child: Tooltip(
              message: 'Filter sessions',
              child: Material(
                color: widget.filterActive
                    ? AppColors.gradientEnd
                    : const Color(0xFF3EC8F0),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onFilterPressed,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
