import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/features/home/providers/menu_provider.dart';
import 'package:meal_app/features/quick_service/providers/quick_service_provider.dart';
import 'package:meal_app/features/bulk_order/providers/bulk_order_provider.dart';
import 'package:meal_app/features/bulk_order/ui/widgets/bulk_order_address_section.dart';
import 'package:meal_app/features/quick_service/ui/widgets/quick_service_checkout.dart';

class OneDayLunchScreen extends StatefulWidget {
  const OneDayLunchScreen({super.key});

  @override
  State<OneDayLunchScreen> createState() => _OneDayLunchScreenState();
}

class _OneDayLunchScreenState extends State<OneDayLunchScreen> {
  String _deliveryType = 'next_day';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<QuickServiceProvider>();
      await p.loadOneDayConfig();
      await context.read<BulkOrderProvider>().loadSavedDeliveryAddress();
      final bulkAddr = context.read<BulkOrderProvider>().deliveryAddress;
      if (bulkAddr != null) p.setAddress(bulkAddr);
      await context.read<MenuProvider>().fetchTodayMenu(silent: true);
      final menu = context.read<MenuProvider>().todayMenu;
      p.setTodayMenu(menu == null ? null : Map<String, dynamic>.from(menu));
    });
  }

  Future<void> _pay() async {
    await QuickServiceCheckout.payOneDayLunch(
      context,
      deliveryType: _deliveryType,
      quantity: _quantity,
      skipAddressPrompt: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<QuickServiceProvider>();
    final cfg = p.oneDayConfig;
    final menu = p.todayMenu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppTheme.backgroundDark : Colors.white;

    final todayPrice = double.tryParse(cfg?['today_price']?.toString() ?? '') ?? 100.0;
    final nextDayPrice = double.tryParse(cfg?['next_day_price']?.toString() ?? '') ?? 90.0;
    final cutoff = cfg?['today_cutoff_time']?.toString() ?? '09:00';
    final selectedPrice = _deliveryType == 'today' ? todayPrice : nextDayPrice;
    final total = selectedPrice * _quantity;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('One Day Lunch'),
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
      ),
      body: p.isLoading && cfg == null
          ? const Center(child: CircularProgressIndicator())
          : cfg == null
              ? Center(child: Text(p.error ?? 'Service unavailable'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (menu != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: menu['image_url'] != null
                            ? CachedNetworkImage(
                                imageUrl: menu['image_url'].toString(),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 120,
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                alignment: Alignment.center,
                                child: const Icon(CupertinoIcons.tray_fill, size: 48),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        menu['items']?.toString() ?? "Today's menu",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _optionTile(
                      title: 'Next Day',
                      subtitle: '₹${nextDayPrice.toStringAsFixed(0)} / meal',
                      selected: _deliveryType == 'next_day',
                      onTap: () => setState(() => _deliveryType = 'next_day'),
                    ),
                    const SizedBox(height: 10),
                    _optionTile(
                      title: 'Today',
                      subtitle: '₹${todayPrice.toStringAsFixed(0)} / meal · order before $cutoff',
                      selected: _deliveryType == 'today',
                      onTap: () => setState(() => _deliveryType = 'today'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          icon: const Icon(CupertinoIcons.minus_circle),
                        ),
                        Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(CupertinoIcons.plus_circle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BulkOrderAddressSection(),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (ctx) {
                        final addr = ctx.watch<BulkOrderProvider>().deliveryAddress;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) ctx.read<QuickServiceProvider>().setAddress(addr);
                        });
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: p.isLoading ? null : _pay,
                        child: p.isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Pay & Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _optionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                color: selected ? AppTheme.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
