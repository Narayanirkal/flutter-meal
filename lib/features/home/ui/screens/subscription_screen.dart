import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/providers/subscription_provider.dart';
import 'package:meal_app/core/models/subscription_model.dart';
import 'package:meal_app/core/widgets/apple_card.dart';
import 'package:meal_app/core/providers/payment_provider.dart';
import 'package:meal_app/core/providers/cart_provider.dart';
import 'package:meal_app/features/children/providers/children_provider.dart';
import 'package:meal_app/features/profile/providers/profile_provider.dart';
import 'package:meal_app/features/subscription/ui/screens/payment_status_screen.dart';
import 'package:meal_app/features/subscription/ui/screens/cart_screen.dart';
import 'package:meal_app/core/utils/error_handler.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _step = 0;
  String? _selectedEntityType;
  String? _selectedEntityId;
  String? _selectedEntityName;
  int? _selectedMealSizeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchSubscriptions(force: true);
      context.read<ChildrenProvider>().fetchChildren();
      context.read<ProfileProvider>().fetchProfiles(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      floatingActionButton: context.watch<CartProvider>().itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const CartScreen())),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(CupertinoIcons.cart_fill, color: Colors.white),
              label: Text(
                'Cart (${context.watch<CartProvider>().itemCount})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SubscriptionProvider>().fetchSubscriptions(force: true);
          await context.read<ChildrenProvider>().fetchChildren();
          await context.read<ProfileProvider>().fetchProfiles(force: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _step == 0 ? _buildEntitySelectionView() : _buildPlanSelectionView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntitySelectionView() {
    final childrenProvider = context.read<ChildrenProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Profile to Upgrade',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: isDark ? Colors.white : AppTheme.textPrimaryLight),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'Who are you buying this subscription for?',
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : AppTheme.textSecondaryLight),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 40),

        if (childrenProvider.children.isNotEmpty) ...[
          const Text('CHILDREN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 12),
          ...childrenProvider.children.map((child) => _buildSelectionItem(
            context,
            'child',
            child.id!,
            child.name,
            'Child - ${child.rollNumber}',
            isDark,
            mealSizeId: child.mealSizeId,
          )),
          const SizedBox(height: 20),
        ],

        const Text('OTHER PROFILES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey)),
        const SizedBox(height: 12),
        if (profileProvider.teacherProfile != null)
          _buildSelectionItem(
            context,
            'teacher',
            profileProvider.teacherProfile!.id!,
            profileProvider.teacherProfile!.name,
            'Teacher Profile',
            isDark,
          ),
        if (profileProvider.professionalProfile != null)
          _buildSelectionItem(
            context,
            'professional',
            profileProvider.professionalProfile!.id!,
            profileProvider.professionalProfile!.name,
            'Professional Profile',
            isDark,
          ),

        if (childrenProvider.children.isEmpty && profileProvider.teacherProfile == null && profileProvider.professionalProfile == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No active profiles found to upgrade. Please create a profile first.')),
          ),
      ],
    );
  }

  Widget _buildPlanSelectionView() {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    
    // Filter plans based on selected entity's meal size (if applicable)
    final availablePlans = subscriptionProvider.subscriptions.where((plan) {
      if (_selectedMealSizeId != null && plan.mealSizeId != null) {
        return plan.mealSizeId == _selectedMealSizeId;
      }
      return true; // if no meal size specified on entity or plan, show it
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, color: isDark ? Colors.white : AppTheme.textPrimaryLight),
        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'Unlock premium features and professional meal tracking.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : AppTheme.textSecondaryLight),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 40),
        
        if (subscriptionProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (availablePlans.isEmpty)
          const Text('No subscription plans available for this profile type.')
        else
          ...availablePlans.map((plan) => _buildPlanCard(context, plan)),
        
        const SizedBox(height: 40),
        _buildFAQSection(),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back),
        onPressed: () {
          if (_step == 1) {
            setState(() => _step = 0);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Buuttii Premium',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionModel plan) {
    final isPremium = plan.planName.toLowerCase().contains('pro') || plan.planName.toLowerCase().contains('premium');
    
    return AppleCard(
      color: isPremium ? AppTheme.primaryColor : null,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.planName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isPremium ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight),
                ),
              ),
              Text(
                '₹${plan.price}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isPremium ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Text(
            plan.billingCycle,
            style: TextStyle(
              fontSize: 14,
              color: isPremium ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppTheme.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureRow('Family Meal Tracking', isPremium),
          _buildFeatureRow('Priority Support', isPremium),
          _buildFeatureRow('${plan.trialDays} Days Free Trial', isPremium),
          const SizedBox(height: 24),
          // Buy Now button
          ElevatedButton(
            onPressed: () => _showDateSelectionSheet(context, plan, 'buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPremium ? Colors.white : AppTheme.primaryColor,
              foregroundColor: isPremium ? AppTheme.primaryColor : Colors.white,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.creditcard, size: 18),
                SizedBox(width: 8),
                Text('Buy Now', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Add to Cart button
          OutlinedButton(
            onPressed: () => _showDateSelectionSheet(context, plan, 'cart'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isPremium ? Colors.white : AppTheme.primaryColor,
              side: BorderSide(color: isPremium ? Colors.white54 : AppTheme.primaryColor),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.cart_badge_plus, size: 18),
                SizedBox(width: 8),
                Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildFeatureRow(String text, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.checkmark_circle_fill, 
            color: isPremium ? Colors.white70 : AppTheme.primaryColor, 
            size: 18
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isPremium ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _buildFAQItem('Can I cancel anytime?', 'Yes, you can cancel your subscription at any time from the settings.'),
        _buildFAQItem('Is there a free trial?', 'Yes, all plans come with a free trial period.'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimaryLight)),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildSelectionItem(
    BuildContext context, 
    String entityType, 
    String entityId, 
    String name, 
    String subtitle, 
    bool isDark,
    {int? mealSizeId}
  ) {
    return AppleCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        setState(() {
          _selectedEntityType = entityType;
          _selectedEntityId = entityId;
          _selectedEntityName = name;
          _selectedMealSizeId = mealSizeId;
          _step = 1; // Move to plan selection
        });
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : AppTheme.textPrimaryLight)),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.textSecondaryLight, fontSize: 12)),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _showDateSelectionSheet(BuildContext context, SubscriptionModel plan, String action) async {
    final nextDay = DateTime.now().add(const Duration(days: 1));
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: nextDay,
      firstDate: nextDay,
      lastDate: nextDay.add(const Duration(days: 60)),
      helpText: 'Select Meal Start Date',
      confirmText: action == 'cart' ? 'ADD TO CART' : 'PROCEED TO PAY',
    );
    if (selectedDate != null && context.mounted) {
       final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
       
       if (action == 'cart') {
         // Add to local cart
         context.read<CartProvider>().addItem(CartItem(
           entityType: _selectedEntityType!,
           entityId: _selectedEntityId!,
           entityName: _selectedEntityName ?? 'Profile',
           subscriptionId: plan.id,
           planName: plan.planName,
           price: plan.price,
           billingCycle: plan.billingCycle,
           startDate: dateStr,
           mealSizeId: plan.mealSizeId,
         ));
         if (context.mounted) {
           ErrorHandler.showSuccess(context, '${plan.planName} added to cart for ${_selectedEntityName ?? 'profile'}');
         }
       } else {
         _handlePayment(context, plan.id, _selectedEntityType!, _selectedEntityId!, dateStr);
       }
    }
  }

  Future<void> _handlePayment(
    BuildContext context,
    String planId,
    String entityType,
    String entityId,
    String startDate,
  ) async {
    final paymentProvider = context.read<PaymentProvider>();

    // Show a loading dialog while we create the order & initialize the SDK
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 14),
              SizedBox(height: 16),
              Text(
                'Preparing Payment...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    // initiateCheckout calls backend, then drives the PhonePe SDK natively.
    // The SDK opens PhonePe app / payment page and blocks until user finishes.
    final result = await paymentProvider.initiateCheckout(
      subscriptionId: planId,
      entityType: entityType,
      entityId: entityId,
      startDate: startDate,
      isSandbox: true, // change to false for production
    );

    // Close the loading dialog
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (!context.mounted) return;

    if (result != null) {
      final String sdkStatus = result['sdkStatus'] as String? ?? 'FAILURE';
      final String txnId = result['merchantTransactionId'] as String? ?? '';
      final String orderId = result['orderId'] as String? ?? '';

      if (sdkStatus == 'SUCCESS' || sdkStatus == 'INTERRUPTED') {
        // SUCCESS: payment went through → verify with backend
        // INTERRUPTED: user may have completed on the bank page → verify too
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => PaymentStatusScreen(
              txnId: txnId,
              orderId: orderId,
            ),
          ),
        );
      } else {
        // FAILURE: show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment failed or was cancelled.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else if (paymentProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.error!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
