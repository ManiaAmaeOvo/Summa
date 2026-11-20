import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/app/widgets/ledger_surfaces.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';
import 'package:summa/l10n/l10n.dart';

class NetWorthValuationCard extends ConsumerWidget {
  const NetWorthValuationCard({
    super.key,
    required this.balances,
    this.highlighted = false,
    this.action,
  });

  final List<AccountBalance> balances;
  final bool highlighted;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = highlighted
        ? colors.onPrimaryContainer
        : colors.onSurface;
    final settings = ref.watch(valuationSettingsProvider);

    return Card(
      color: highlighted ? colors.primaryContainer : colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              labels.estimatedNetWorth,
              style: theme.textTheme.titleMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 4),
            settings.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => Text(labels.valuationReadFailed),
              data: (settings) {
                final result = estimateNetWorth(balances, settings);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.totalMinor case final total?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          formatMoneyTotal(total, settings.baseCurrency),
                          key: const ValueKey('estimated-net-worth-amount'),
                          style: ledgerAmountStyle(
                            highlighted
                                ? theme.textTheme.displaySmall
                                : theme.textTheme.headlineSmall,
                            color: foreground,
                          ),
                        ),
                      ),
                    if (result.totalMinor == null ||
                        settings.baseCurrency == defaultCurrency)
                      Text(
                        labels.valuationBaseDescription(settings.baseCurrency),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    if (result.missingCurrencies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels.missingValuationRates(
                            result.missingCurrencies.join(', '),
                          ),
                          style: TextStyle(
                            color: highlighted ? foreground : colors.error,
                          ),
                        ),
                      ),
                    if (result.unsupportedCurrencies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels.unsupportedValuationCurrencies(
                            result.unsupportedCurrencies.join(', '),
                          ),
                          style: TextStyle(
                            color: highlighted ? foreground : colors.error,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ?action,
                TextButton.icon(
                  style: highlighted
                      ? TextButton.styleFrom(foregroundColor: foreground)
                      : null,
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const _ValuationScreen()),
                  ),
                  icon: const Icon(Icons.currency_exchange),
                  label: Text(labels.valuationSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuationScreen extends ConsumerStatefulWidget {
  const _ValuationScreen();

  @override
  ConsumerState<_ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends ConsumerState<_ValuationScreen> {
  bool _savingBase = false;

  @override
  Widget build(BuildContext context) {
    final balances =
        ref.watch(accountBalancesProvider).asData?.value ??
        const <AccountBalance>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.valuationSettings)),
      body: ref
          .watch(valuationSettingsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                Center(child: Text(context.l10n.valuationReadFailed)),
            data: (settings) {
              final base = settings.baseCurrency;
              final rates = {
                for (final rate in settings.rates)
                  if (rate.baseCurrency == base) rate.sourceCurrency: rate,
              };
              final sourceCurrencies = <String>{
                ...rates.keys,
                for (final balance in balances)
                  if (balance.group != AccountGroup.entrustedFunds &&
                      balance.currencyCode != base &&
                      isValuationCurrency(balance.currencyCode))
                    balance.currencyCode,
              }.toList()..sort();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CurrencySelector(
                    currencies: currencyOptions(currencyMinorDigits.keys),
                    value: base,
                    label: context.l10n.valuationBaseCurrency,
                    onChanged: _savingBase ? null : _saveBase,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.valuationSettingsHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.valuationRatesTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (sourceCurrencies.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(context.l10n.noValuationCurrencies),
                    ),
                  for (final code in sourceCurrencies)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      key: ValueKey('valuation-rate-$code'),
                      title: Text(context.l10n.valuationRatePair(code, base)),
                      subtitle: _rateSummary(rates[code]),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _savingBase
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => _ValuationRateDialog(
                                sourceCurrency: code,
                                baseCurrency: base,
                                current: rates[code],
                              ),
                            ),
                    ),
                ],
              );
            },
          ),
    );
  }

  Widget _rateSummary(ValuationRate? rate) {
    if (rate == null) return Text(context.l10n.valuationRateMissing);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(rate.updatedAt.toLocal());
    return Text(
      [
        '1 ${rate.sourceCurrency} = ${rate.rate} ${rate.baseCurrency}',
        context.l10n.valuationRateAsOf(date),
      ].join('\n'),
    );
  }

  Future<void> _saveBase(String code) async {
    setState(() => _savingBase = true);
    try {
      await ref.read(expenseRepositoryProvider).setValuationBaseCurrency(code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _savingBase = false);
    }
  }
}

class _ValuationRateDialog extends ConsumerStatefulWidget {
  const _ValuationRateDialog({
    required this.sourceCurrency,
    required this.baseCurrency,
    required this.current,
  });

  final String sourceCurrency;
  final String baseCurrency;
  final ValuationRate? current;

  @override
  ConsumerState<_ValuationRateDialog> createState() =>
      _ValuationRateDialogState();
}

class _ValuationRateDialogState extends ConsumerState<_ValuationRateDialog> {
  late final _rate = TextEditingController(text: widget.current?.rate);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.editValuationRate),
    content: TextField(
      controller: _rate,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: context.l10n.valuationRateField,
        helperText: context.l10n.exchangeRateDirection(
          widget.baseCurrency,
          widget.sourceCurrency,
        ),
        errorText: _error,
      ),
    ),
    actionsOverflowButtonSpacing: 4,
    actions: [
      if (widget.current != null)
        TextButton(
          onPressed: _saving ? null : () => _apply(remove: true),
          child: Text(context.l10n.removeValuationRate),
        ),
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: _saving ? null : () => _apply(remove: false),
        child: Text(context.l10n.save),
      ),
    ],
  );

  Future<void> _apply({required bool remove}) async {
    final rate = _rate.text.trim();
    if (!remove && !isValidExchangeQuote(rate)) {
      setState(() => _error = context.l10n.invalidValuationRate);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final repository = ref.read(expenseRepositoryProvider);
    try {
      if (remove) {
        await repository.removeValuationRate(
          sourceCurrency: widget.sourceCurrency,
          baseCurrency: widget.baseCurrency,
        );
      } else {
        await repository.saveValuationRate(
          sourceCurrency: widget.sourceCurrency,
          baseCurrency: widget.baseCurrency,
          rate: rate,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.saveFailed;
        });
      }
    }
  }
}
