import 'package:start_on/models/app_local_data.dart';
import 'package:start_on/widgets/common.dart';
import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.data});

  final AppLocalData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ShopItem('오늘 면제권', '오늘 하루 퀘스트 면제', '500', Icons.receipt_long_rounded, const Color(0xFFFFE28B)),
      ShopItem('스티커', '귀여운 캐릭터 스티커', '300', Icons.auto_awesome_rounded, const Color(0xFFAED7FF)),
      ShopItem('캐릭터', '새로운 캐릭터 해금', '1500', Icons.bug_report_outlined, const Color(0xFFFF8B93)),
      ShopItem('실물 상품', '특별한 굿즈', '2000', Icons.card_giftcard_rounded, const Color(0xFFD86DFF)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '상점',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2940),
                    ),
                  ),
                  SizedBox(height: 6),

                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE48A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFE48A).withValues(alpha: 0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 18, color: Color(0xFF745C00)),
                  const SizedBox(width: 6),
                  Text(
                    '${data.credits}',
                    style: const TextStyle(
                      color: Color(0xFF473200),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeading(icon: Icons.auto_awesome_outlined, title: '오늘의 추천'),
        const SizedBox(height: 14),
        const VipPassCard(),
        const SizedBox(height: 22),
        const SectionHeading(icon: Icons.inventory_2_outlined, title: '모든 상품'),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, index) => ShopItemCard(item: items[index]),
        ),
      ],
    );
  }
}

class VipPassCard extends StatelessWidget {
  const VipPassCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7F88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7F88).withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 28)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  '30% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'VIP패스',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '첫구매 할인!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                '10,000원',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF7F88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    '구매하기',
                    style: TextStyle(fontWeight: FontWeight.w800),
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

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({super.key, required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C2940),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7E899D),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, size: 16, color: Color(0xFFE1C468)),
              const SizedBox(width: 4),
              Text(
                item.price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2940),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8B93),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('구매'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShopItem {
  ShopItem(this.title, this.subtitle, this.price, this.icon, this.color);

  final String title;
  final String subtitle;
  final String price;
  final IconData icon;
  final Color color;
}
