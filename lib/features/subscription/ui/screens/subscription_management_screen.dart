import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/core/providers/payment_provider.dart';
import 'package:meal_app/core/widgets/apple_card.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchActiveSubscriptions();
      context.read<PaymentProvider>().fetchPaymentHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subscriptions & Payments',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppTheme.textPrimaryLight,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          tabs: const [
            Tab(text: 'Active Plans'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivePlans(paymentProvider, isDark),
          _buildHistory(paymentProvider, isDark),
        ],
      ),
    );
  }

  Widget _buildActivePlans(PaymentProvider provider, bool isDark) {
    if (provider.isLoading) return const Center(child: CupertinoActivityIndicator());
    
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.orange.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Could not load subscriptions',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => provider.fetchActiveSubscriptions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.activeSubscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.creditcard, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No active subscriptions found.',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.activeSubscriptions.length,
      itemBuilder: (context, index) {
        final sub = provider.activeSubscriptions[index];
        
        // Safe type conversion for all fields
        final planName = _safeString(sub['plan_name'], 'PLAN');
        final entityName = _safeString(sub['entity_name'], 'Profile');
        final entityType = _safeString(sub['entity_type'], '');
        final amountPaid = _safeString(sub['amount_paid'], '');
        final daysRemaining = sub['days_remaining'];
        final status = _safeString(sub['status'] ?? sub['subscription_status'], 'ACTIVE');
        final includeSaturday = sub['include_saturday'] == null ? true : sub['include_saturday'] == true;
        
        final expiryStr = _safeString(sub['end_date'] ?? sub['expiry_date'], '');
        DateTime? expiry;
        if (expiryStr.isNotEmpty) {
          expiry = DateTime.tryParse(expiryStr);
        }
        
        return AppleCard(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      planName.toUpperCase(),
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entityName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                ),
              ),
              if (entityType.isNotEmpty)
                Text(
                  entityType.toUpperCase(),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 4),
              if (expiry != null)
                Text(
                  'Expires on: ${DateFormat('dd MMM yyyy').format(expiry)}',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              if (amountPaid.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Amount: ₹$amountPaid',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                includeSaturday ? 'Variant: With Saturday' : 'Variant: Without Saturday',
                style: TextStyle(
                  color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    ),
                  ),
                  Row(
                    children: [
                      if (daysRemaining != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '$daysRemaining days left',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistory(PaymentProvider provider, bool isDark) {
    if (provider.isLoading) return const Center(child: CupertinoActivityIndicator());
    
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.orange.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Could not load payment history',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => provider.fetchPaymentHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.paymentHistory.isEmpty) {
      return Center(
        child: Text(
          'No payment history found.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = provider.paymentHistory[index];
        
        // Safe type conversion — prevents "type X is not a subtype of type String"
        final planName = _safeString(payment['plan_name'] ?? payment['entity_name'], 'Subscription');
        final entityName = _safeString(payment['entity_name'], '');
        final amount = _safeNumString(payment['amount']);
        final pStatus = _safeString(
          payment['payment_status'] ?? payment['order_status'] ?? payment['status'],
          'PENDING',
        ).toUpperCase();
        final includeSaturday = payment['include_saturday'] == null ? true : payment['include_saturday'] == true;
        final isSuccess = pStatus == 'COMPLETED' || pStatus == 'SUCCESS';

        final dateStr = _safeString(payment['created_at'] ?? payment['payment_date'], '');
        DateTime date = DateTime.now();
        if (dateStr.isNotEmpty) {
          date = DateTime.tryParse(dateStr) ?? DateTime.now();
        }

        return AppleCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isSuccess ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSuccess ? CupertinoIcons.checkmark_alt : CupertinoIcons.clock,
                  color: isSuccess ? Colors.green : Colors.orange,
                  size: 20
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (entityName.isNotEmpty)
                      Text(
                        entityName,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      includeSaturday ? 'With Saturday' : 'Without Saturday',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : AppTheme.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(date),
                      style: TextStyle(
                        color: isDark ? Colors.white38 : AppTheme.textSecondaryLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$amount',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isSuccess ? Colors.green : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pStatus,
                      style: TextStyle(
                        color: isSuccess ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Safely convert any dynamic value to String, avoiding type cast errors.
  String _safeString(dynamic value, String fallback) {
    if (value == null) return fallback;
    return value.toString();
  }

  /// Safely convert numeric amount to display string.
  String _safeNumString(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return value.toString();
  }
}
