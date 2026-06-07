import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/providers/meal_provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/features/quick_service/providers/quick_service_provider.dart';
import 'package:meal_app/features/quick_service/ui/screens/special_dishes_screen.dart';
import 'package:meal_app/features/quick_service/ui/widgets/quick_service_checkout.dart';

class QuickOrderSection extends StatefulWidget {
  const QuickOrderSection({super.key});

  @override
  State<QuickOrderSection> createState() => _QuickOrderSectionState();
}

class _QuickOrderSectionState extends State<QuickOrderSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuickServiceProvider>().loadOneDayConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<QuickServiceProvider>();
    final cfg = provider.oneDayConfig;
    final status = context.watch<MealProvider>().subscriptionStatusData;
    final hasActive = status?['has_active_subscription'] == true;
    final showSubscriberBadge = !hasActive;

    final todayPrice = (cfg?['today_price'] as num?)?.toDouble() ?? 100;
    final nextDayPrice = (cfg?['next_day_price'] as num?)?.toDouble() ?? 90;
    final cutoff = cfg?['today_cutoff_time']?.toString() ?? '09:00';

    final titleColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final cardBg = isDark ? AppTheme.surfaceDark : Colors.white;
    final borderColor = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              if (showSubscriberBadge) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Not a subscriber?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OneDayLunchCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  todayPrice: todayPrice,
                  nextDayPrice: nextDayPrice,
                  cutoff: cutoff,
                  enabled: cfg != null && !provider.isLoading,
                  onToday: () => QuickServiceCheckout.payOneDayLunch(
                    context,
                    deliveryType: 'today',
                  ),
                  onNextDay: () => QuickServiceCheckout.payOneDayLunch(
                    context,
                    deliveryType: 'next_day',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SpecialsCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const SpecialDishesScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OneDayLunchCard extends StatelessWidget {
  const _OneDayLunchCard({
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.todayPrice,
    required this.nextDayPrice,
    required this.cutoff,
    required this.enabled,
    required this.onToday,
    required this.onNextDay,
  });

  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final double todayPrice;
  final double nextDayPrice;
  final String cutoff;
  final bool enabled;
  final VoidCallback onToday;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: const Icon(CupertinoIcons.bag, size: 16, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'One Day Lunch',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Order a single meal without a subscription.',
            style: TextStyle(fontSize: 11, height: 1.3, color: subtitleColor),
          ),
          const SizedBox(height: 12),
          _DeliveryOption(
            label: 'TODAY',
            labelColor: const Color(0xFFEA580C),
            icon: CupertinoIcons.sun_max_fill,
            iconColor: const Color(0xFFEA580C),
            price: todayPrice,
            hint: 'Order before $cutoff',
            enabled: enabled,
            onTap: onToday,
          ),
          const SizedBox(height: 8),
          _DeliveryOption(
            label: 'NEXT DAY',
            labelColor: const Color(0xFF2563EB),
            icon: CupertinoIcons.calendar,
            iconColor: const Color(0xFF2563EB),
            price: nextDayPrice,
            hint: 'Schedule for tomorrow',
            enabled: enabled,
            onTap: onNextDay,
          ),
        ],
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.label,
    required this.labelColor,
    required this.icon,
    required this.iconColor,
    required this.price,
    required this.hint,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color labelColor;
  final IconData icon;
  final Color iconColor;
  final double price;
  final String hint;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 4),
                        Text(
                          '₹${price.toStringAsFixed(0)} /meal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialsCard extends StatelessWidget {
  const _SpecialsCard({
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.onTap,
  });

  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(CupertinoIcons.star_fill, size: 16, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buuttii Specials',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Special dishes with categories, prices & quantities.',
                style: TextStyle(fontSize: 11, height: 1.35, color: subtitleColor),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Browse & order',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
