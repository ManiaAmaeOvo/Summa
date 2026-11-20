import 'package:flutter/material.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

class LedgerFilterControl extends StatelessWidget {
  const LedgerFilterControl({
    super.key,
    required this.filter,
    required this.records,
    required this.balances,
    required this.onChanged,
    this.forReport = false,
  });

  final LedgerFilter filter;
  final List<LedgerRecord> records;
  final List<AccountBalance> balances;
  final ValueChanged<LedgerFilter> onChanged;
  final bool forReport;

  @override
  Widget build(BuildContext context) {
    final options = _FilterOptions(context, records, balances);
    final labels = context.l10n;
    final selection = [
      if (filter.range case final range?) _rangeLabel(context, range),
      ?filter.currency,
      if (filter.accountId case final id?) options.accounts[id] ?? id,
      if (filter.categoryId case final id?) options.categories[id] ?? id,
      if (filter.funding case final funding?) _fundingLabel(context, funding),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: Icon(
            filter.isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
          ),
          label: Text(labels.ledgerFilters),
          onPressed: () async {
            final changed = await showDialog<LedgerFilter>(
              context: context,
              builder: (_) => _FilterDialog(
                filter: filter,
                options: options,
                forReport: forReport,
              ),
            );
            if (context.mounted && changed != null) onChanged(changed);
          },
        ),
        if (selection.isNotEmpty)
          Text(
            selection.join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _FilterOptions {
  _FilterOptions(
    BuildContext context,
    List<LedgerRecord> records,
    List<AccountBalance> balances,
  ) {
    final locale = Localizations.localeOf(context);
    String account(String id, String name) =>
        DefaultLedgerLabels.accountName(locale, id, name);
    String category(String id, String name) =>
        DefaultLedgerLabels.categoryName(locale, id, name);
    currencies = currencyOptions([
      for (final row in balances) row.currencyCode,
      for (final record in records) ...ledgerRecordCurrencies(record),
    ]);
    for (final row in balances) {
      accounts[row.id] = '${account(row.id, row.name)} · ${row.currencyCode}';
    }
    for (final record in records) {
      accounts.putIfAbsent(
        record.accountId,
        () => account(record.accountId, record.accountName),
      );
      if (record.targetAccountId case final id?) {
        accounts.putIfAbsent(
          id,
          () => account(id, record.targetAccountName ?? id),
        );
      }
      for (final leg in record.accountPostings) {
        accounts.putIfAbsent(
          leg.accountId,
          () => account(leg.accountId, leg.accountName),
        );
      }
      for (final item in ledgerRecordCategories(record)) {
        final parent = category(item.parentId, item.parentName);
        categories[item.parentId] = parent;
        categories[item.id] = '$parent / ${category(item.id, item.name)}';
      }
    }
  }

  late final List<String> currencies;
  final accounts = <String, String>{};
  final categories = <String, String>{};
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.filter,
    required this.options,
    required this.forReport,
  });

  final LedgerFilter filter;
  final _FilterOptions options;
  final bool forReport;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late LedgerDateRange? _range = widget.filter.range;
  late String? _currency = widget.filter.currency;
  late String? _account = widget.filter.accountId;
  late String? _category = widget.filter.categoryId;
  late LedgerFunding? _funding = widget.filter.funding;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    return AlertDialog(
      title: Text(labels.ledgerFilters),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(labels.timeRange),
            subtitle: Text(
              _range == null
                  ? (widget.forReport
                        ? labels.ledgerFilterUseReportPeriod
                        : labels.allTime)
                  : _rangeLabel(context, _range!),
            ),
            onTap: _pickRange,
            trailing: _range == null
                ? const Icon(Icons.calendar_today_outlined)
                : IconButton(
                    tooltip: labels.ledgerFilterUseReportPeriod,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _range = null),
                  ),
          ),
          if (!widget.forReport)
            _field(
              labels.currencyLabel,
              labels.ledgerFilterAllCurrencies,
              _currency,
              {for (final code in widget.options.currencies) code: code},
              (value) => setState(() => _currency = value),
            ),
          _field(
            labels.account,
            labels.ledgerFilterAllAccounts,
            _account,
            widget.options.accounts,
            (value) => setState(() => _account = value),
          ),
          _field(
            labels.category,
            labels.ledgerFilterAllCategories,
            _category,
            widget.options.categories,
            (value) => setState(() => _category = value),
          ),
          _field(
            labels.ledgerFilterFunding,
            labels.ledgerFilterAllFunding,
            _funding?.name,
            {
              for (final funding in LedgerFunding.values)
                funding.name: _fundingLabel(context, funding),
            },
            (value) => setState(
              () => _funding = value == null
                  ? null
                  : LedgerFunding.values.byName(value),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, const LedgerFilter()),
          child: Text(labels.ledgerFilterClear),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            LedgerFilter(
              range: _range,
              currency: widget.forReport ? null : _currency,
              accountId: _account,
              categoryId: _category,
              funding: _funding,
            ),
          ),
          child: Text(labels.ledgerFilterApply),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    String allLabel,
    String? value,
    Map<String, String> options,
    ValueChanged<String?> select,
  ) {
    final entries = {
      '': allLabel,
      ...options,
      if (value != null && !options.containsKey(value)) value: value,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value ?? '',
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in entries.entries)
            DropdownMenuItem(
              value: option.key,
              child: Text(option.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) => select(value?.isEmpty == true ? null : value),
      ),
    );
  }

  Future<void> _pickRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(firstPlanningYear),
      lastDate: DateTime(lastPlanningYear, 12, 31),
      initialDateRange: _range == null
          ? null
          : DateTimeRange(
              start: _range!.start,
              end: _range!.endExclusive.subtract(
                const Duration(milliseconds: 1),
              ),
            ),
    );
    if (mounted && selected != null) {
      final end = selected.end;
      setState(
        () => _range = (
          start: selected.start,
          endExclusive: DateTime(end.year, end.month, end.day + 1),
        ),
      );
    }
  }
}

String _rangeLabel(BuildContext context, LedgerDateRange range) {
  final labels = MaterialLocalizations.of(context);
  return '${labels.formatShortDate(range.start)} – '
      '${labels.formatShortDate(range.endExclusive.subtract(const Duration(milliseconds: 1)))}';
}

String _fundingLabel(BuildContext context, LedgerFunding funding) {
  final labels = context.l10n;
  return switch (funding) {
    LedgerFunding.personal => labels.ledgerFilterFundingPersonal,
    LedgerFunding.familyDirect => labels.familyDirectFunding,
    LedgerFunding.entrusted => labels.entrustedSpending,
    LedgerFunding.thirdParty => labels.ledgerFilterThirdParty,
    LedgerFunding.familySupport => labels.familySupportReceived,
    LedgerFunding.externalRepayment => labels.externalDebtPayment,
    LedgerFunding.unclassified => labels.ledgerFilterUnknownFunding,
  };
}
