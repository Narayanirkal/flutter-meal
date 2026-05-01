import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:meal_app/features/auth/providers/auth_provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/widgets/apple_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:meal_app/core/providers/lookup_provider.dart';
import 'package:meal_app/features/profile/providers/profile_provider.dart';
import 'package:meal_app/features/children/providers/children_provider.dart';
import 'package:meal_app/features/children/ui/screens/children_management_screen.dart';
import 'package:meal_app/features/profile/ui/screens/teacher_profile_screen.dart';
import 'package:meal_app/features/profile/ui/screens/professional_profile_screen.dart';
import 'package:meal_app/features/profile/ui/screens/settings_screen.dart';
import 'package:meal_app/features/home/ui/screens/subscription_screen.dart';
import 'package:meal_app/features/home/providers/homepage_provider.dart';
import 'package:meal_app/features/home/data/models/homepage_entry.dart';
import 'package:meal_app/features/home/providers/menu_provider.dart';
import 'package:meal_app/features/home/ui/screens/weekly_menu_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildrenProvider>().fetchChildren();
      context.read<HomepageProvider>().fetchHomepageEntries();
      context.read<MenuProvider>().fetchTodayMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ChildrenProvider>().fetchChildren();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeArea(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildWelcomeSection(authProvider, isDark),
                      const SizedBox(height: 20),
                      _buildMenuSection(context, isDark),
                      const SizedBox(height: 20),
                      _buildFeatureCards(context),
                      const SizedBox(height: 30),
                      _buildQuickStatus(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Buuttii',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
      ),
      actions: [
        _buildSubscribeButton(context),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(CupertinoIcons.settings_solid, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildSubscribeButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                'UPGRADE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.4))
    .scale(duration: 2000.ms, begin: const Offset(1, 1), end: const Offset(1.02, 1.02), curve: Curves.easeInOut);
  }

  Widget _buildWelcomeSection(AuthProvider authProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppTheme.primaryColor.withOpacity(0.2), Colors.transparent]
            : [AppTheme.primaryColor.withOpacity(0.05), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome back, ',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: authProvider.username.isNotEmpty ? authProvider.username : 'User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMenuSection(BuildContext context, bool isDark) {
    final menuProvider = context.watch<MenuProvider>();
    
    if (menuProvider.isLoading) return const SizedBox.shrink();
    if (!menuProvider.isSubscribed || menuProvider.todayMenu == null) return const SizedBox.shrink();

    final menu = menuProvider.todayMenu!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Menu",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, CupertinoPageRoute(builder: (_) => const WeeklyMenuScreen()));
              },
              child: const Text('View One Week Meal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppleCard(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.flame_fill, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu['item_name'] ?? 'Meal Item',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu['description'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    final homepageProvider = context.watch<HomepageProvider>();
    
    if (homepageProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homepageProvider.entries.isEmpty) {
      return const Center(child: Text('No features available'));
    }

    return Column(
      children: homepageProvider.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildFeatureCard(
            context,
            entry.name,
            entry.description,
            _getIconForEntry(entry.name),
            _getColorForEntry(entry.name),
            () => _handleCardTap(context, entry),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForEntry(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('child')) return CupertinoIcons.person_2_fill;
    if (lower.contains('teacher')) return CupertinoIcons.book_fill;
    if (lower.contains('professional')) return CupertinoIcons.briefcase_fill;
    if (lower.contains('bulk')) return CupertinoIcons.cube_box_fill;
    return CupertinoIcons.star_fill;
  }

  Color _getColorForEntry(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('child')) return Colors.blue;
    if (lower.contains('teacher')) return Colors.green;
    if (lower.contains('professional')) return Colors.orange;
    if (lower.contains('bulk')) return Colors.purple;
    return Colors.indigo;
  }

  void _handleCardTap(BuildContext context, HomepageEntry entry) {
    final name = entry.name.toLowerCase();
    if (entry.entityId == 'ENT-3' || name.contains('child')) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => const ChildrenManagementScreen()));
    } else if (entry.entityId == 'ENT-4' || name.contains('teacher')) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => const TeacherProfileScreen()));
    } else if (name.contains('professional')) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => const ProfessionalProfileScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!')));
    }
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppleCard(
      onTap: onTap,
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _buildQuickStatus(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatusMiniCard(
                context,
                'Children', 
                context.watch<ChildrenProvider>().children.length.toString(), 
                CupertinoIcons.person_2_fill, 
                Colors.blue
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatusMiniCard(
                context,
                'Meal Status', 
                'Pending', 
                CupertinoIcons.clock_fill, 
                Colors.amber
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildStatusMiniCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _showChildrenTeacherOptions as it's now handled by _handleCardTap
}


