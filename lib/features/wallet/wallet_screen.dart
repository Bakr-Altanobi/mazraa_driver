import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/core/utils/formatters.dart';
import 'package:mazraa_driver/features/wallet/wallet_providers.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(walletTransactionsProvider);
    await Future.wait([
      ref.read(walletSummaryProvider.future),
      ref.read(walletTransactionsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final wallet = ref.watch(walletSummaryProvider);
    final transactions = ref.watch(walletTransactionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'المحفظة' : 'Wallet'),
        actions: [
          IconButton(
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: wallet.when(
        loading: LoadingList.new,
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(walletSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
            children: [
              _WalletHero(summary: summary),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () => context.push('/cash-custody'),
                icon: const Icon(Icons.payments_outlined), label: Text(ar ? 'عهدة التحصيل وسندات التوريد' : 'Cash custody and remittance receipts')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/payouts'),
                      icon: const Icon(Icons.south_west_rounded),
                      label: Text(ar ? 'سحب' : 'Withdraw'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: summary.canTransfer
                          ? () => _unsupported(context, ar)
                          : null,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(ar ? 'تحويل' : 'Transfer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: ar ? 'ملخص الشهر' : 'Monthly summary',
                icon: Icons.bar_chart_rounded,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 126,
                child: Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: ar ? 'إيداعات' : 'Credits',
                        value: formatMoney(
                          summary.monthlyCredits,
                          summary.currency,
                          locale: ar ? 'ar' : 'en',
                        ),
                        icon: Icons.trending_up_rounded,
                        accent: MazraaColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricCard(
                        title: ar ? 'مدفوعات وسحوبات' : 'Debits',
                        value: formatMoney(
                          summary.monthlyDebits,
                          summary.currency,
                          locale: ar ? 'ar' : 'en',
                        ),
                        icon: Icons.trending_down_rounded,
                        accent: MazraaColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: ar ? 'المعاملات' : 'Transactions',
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 10),
              transactions.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(walletTransactionsProvider),
                ),
                data: (items) => items.isEmpty
                    ? EmptyState(
                        title: ar ? 'لا توجد معاملات' : 'No transactions',
                        message: ar
                            ? 'ستظهر حركات المحفظة هنا عند توفرها.'
                            : 'Wallet activity will appear here.',
                      )
                    : Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              _TransactionTile(
                                transaction: items[i],
                                currency: summary.currency,
                              ),
                              if (i != items.length - 1)
                                const Divider(indent: 64, height: 1),
                            ],
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                ar
                    ? 'هذه محفظة المستخدم، ولطلبات سحب السائق سجل مستقل يمكن مراجعته من شاشة السحب.'
                    : 'This is the user wallet. Driver payout requests can be managed in the dedicated payouts screen.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _unsupported(BuildContext context, bool ar) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ar
              ? 'تحويل الأموال بين المستخدمين غير مفعّل على السيرفر الحالي.'
              : 'User-to-user wallet transfers are not available in the current server configuration.',
        ),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.summary});
  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [MazraaColors.forest, Color(0xFF12643C)],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: MazraaColors.forest.withValues(alpha: .2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                ar ? 'الرصيد الحالي' : 'Current balance',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatMoney(
              summary.balance,
              summary.currency,
              locale: ar ? 'ar' : 'en',
            ),
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            summary.accountNumber,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white70,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.currency});
  final WalletTransaction transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final credit = transaction.type.toLowerCase() == 'deposit';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: (credit ? MazraaColors.success : MazraaColors.orange)
            .withValues(alpha: .12),
        child: Icon(
          credit ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: credit ? MazraaColors.success : MazraaColors.orange,
        ),
      ),
      title: Text(
        transaction.description.isEmpty
            ? transaction.type
            : transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        formatDateTime(transaction.createdAt, locale: ar ? 'ar' : 'en'),
      ),
      trailing: Text(
        '${credit ? '+' : '-'}${formatMoney(transaction.amount, currency, locale: ar ? 'ar' : 'en')}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: credit ? MazraaColors.success : MazraaColors.orange,
        ),
      ),
    );
  }
}
