import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, '홈'),
      (Icons.sports_martial_arts_rounded, '던전'),
      (Icons.storefront_outlined, '상점'),
      (Icons.receipt_long_outlined, '기록'),
    ];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: EdgeInsets.zero,
      child: BottomAppBar(
        color: Colors.white.withValues(alpha: 0.94),
        elevation: 14,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xFFB5C4DC).withValues(alpha: 0.24),
        shape: const AutomaticNotchedShape(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          CircleBorder(),
        ),
        notchMargin: 10,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              Expanded(child: _NavItem(item: items[0], selected: currentIndex == 0, onTap: () => onTap(0))),
              Expanded(child: _NavItem(item: items[1], selected: currentIndex == 1, onTap: () => onTap(1))),
              const SizedBox(width: 72),
              Expanded(child: _NavItem(item: items[2], selected: currentIndex == 2, onTap: () => onTap(2))),
              Expanded(child: _NavItem(item: items[3], selected: currentIndex == 3, onTap: () => onTap(3))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final (IconData, String) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$1,
              size: 22,
              color: selected ? const Color(0xFFFF8B93) : const Color(0xFFA0A9B8),
            ),
            const SizedBox(height: 2),
            Text(
              item.$2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFFFF8B93) : const Color(0xFFA0A9B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedCard extends StatelessWidget {
  const RoundedCard({required this.child, required this.padding, super.key});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8C7DE).withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.icon, required this.title, super.key});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF8B93), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2940),
          ),
        ),
      ],
    );
  }
}
