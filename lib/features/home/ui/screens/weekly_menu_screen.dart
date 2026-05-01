import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/features/home/providers/menu_provider.dart';
import 'package:meal_app/core/widgets/apple_card.dart';

class WeeklyMenuScreen extends StatefulWidget {
  const WeeklyMenuScreen({super.key});

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().fetchWeeklyMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('One Week Meal', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: menuProvider.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : menuProvider.error != null
              ? Center(child: Text(menuProvider.error!, style: const TextStyle(color: Colors.red)))
              : !menuProvider.isSubscribed
                  ? const Center(child: Text('You are not subscribed.'))
                  : menuProvider.weeklyMenu.isEmpty
                      ? const Center(child: Text('No weekly menu available.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: menuProvider.weeklyMenu.length,
                          itemBuilder: (context, index) {
                            final menu = menuProvider.weeklyMenu[index];
                            return AppleCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        menu['day_of_week']?.toUpperCase() ?? 'DAY',
                                        style: const TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    menu['item_name'] ?? 'Meal Item',
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    menu['description'] ?? '',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondaryLight, fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
    );
  }
}
