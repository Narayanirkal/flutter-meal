import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/features/bulk_order/providers/bulk_order_provider.dart';
import 'package:meal_app/features/bulk_order/ui/screens/bulk_order_standard_screen.dart';
import 'package:meal_app/features/bulk_order/ui/screens/bulk_order_variety_screen.dart';
import 'package:meal_app/features/bulk_order/ui/widgets/bulk_order_widgets.dart';

/// Entry point: user picks standard (< threshold) or large variety (50+) flow.
class BulkOrderHubScreen extends StatefulWidget {
  const BulkOrderHubScreen({super.key});

  @override
  State<BulkOrderHubScreen> createState() => _BulkOrderHubScreenState();
}

class _BulkOrderHubScreenState extends State<BulkOrderHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<BulkOrderProvider>();
      await p.loadConfig();
      final cfg = p.config;
      if (cfg != null && cfg.earliestDeliveryDate.length >= 10) {
        await p.loadMenusForDate(cfg.earliestDeliveryDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BulkOrderProvider>();
    final cfg = p.config;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bulk order',
          style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimaryLight),
        ),
      ),
      body: p.isLoading && cfg == null
          ? const Center(child: CircularProgressIndicator())
          : cfg == null
              ? Center(child: Text(p.error ?? 'Bulk ordering is unavailable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Choose the type of bulk order that fits your group size.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      BulkOrderTypeCard(
                        title: 'Standard bulk',
                        subtitle:
                            '${cfg.minQuantity}–${cfg.tierThreshold - 1} meals',
                        detail:
                            'One meal for your delivery date — the same dish for everyone. Enter how many meals you need.',
                        icon: CupertinoIcons.person_3_fill,
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const BulkOrderStandardScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BulkOrderTypeCard(
                        title: 'Large event bulk',
                        subtitle: '${cfg.tierThreshold}+ meals',
                        detail: cfg.allowMultipleVarietyMeals
                            ? 'Pick from our bulk meal catalog. Set portions for each dish — no need to plan a total upfront.'
                            : 'Pick one meal from our bulk catalog and set how many portions you need (minimum ${cfg.tierThreshold}).',
                        icon: CupertinoIcons.square_stack_3d_up_fill,
                        color: Colors.deepOrange,
                        onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const BulkOrderVarietyScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      bulkInfoBanner(
                        isDark: isDark,
                        message:
                            'Not sure? Under ${cfg.tierThreshold} meals uses the school menu for your date. ${cfg.tierThreshold} or more uses our large-event meal list.',
                      ),
                    ],
                  ),
                ),
    );
  }
}
