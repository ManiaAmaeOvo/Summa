import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/payment_notice.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

typedef ReviewedPaymentNotice = ({PaymentNoticeDraft draft, String accountId});

class PaymentNoticeDialog extends ConsumerStatefulWidget {
  const PaymentNoticeDialog({super.key});

  @override
  ConsumerState<PaymentNoticeDialog> createState() =>
      _PaymentNoticeDialogState();
}

class _PaymentNoticeDialogState extends ConsumerState<PaymentNoticeDialog> {
  PaymentNoticeDraft? _draft;
  String? _accountId;
  String _text = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = _draft;
    final accounts = draft == null ? null : ref.watch(accountsProvider);
    final expense = draft?.type == LedgerTransactionType.expense;
    final choices = (accounts?.value ?? const <LedgerAccount>[])
        .where((account) => account.currencyCode == defaultCurrency)
        .where(
          (account) => expense
              ? account.kind != AccountKind.receivable
              : account.kind.isPersonalCash ||
                    account.kind == AccountKind.entrustedFunds ||
                    account.kind == AccountKind.prepaid,
        )
        .toList();
    final selectedId = choices.any((account) => account.id == _accountId)
        ? _accountId
        : null;

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.pastePaymentNotice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.paymentNoticePrivacy),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: l10n.paymentNoticeText,
              alignLabelWithHint: true,
              errorText: _text.trim().isNotEmpty && draft == null
                  ? l10n.paymentNoticeUnsupported
                  : null,
              errorMaxLines: 4,
            ),
            onChanged: (text) => setState(() {
              _text = text;
              _draft = tryParsePaymentNotice(text);
              _accountId = null;
            }),
          ),
          if (draft != null) ...[
            Text(
              '${expense ? l10n.expense : l10n.income} · ${formatCny(draft.amountMinor)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (draft.note.isNotEmpty) Text(draft.note),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedId),
              initialValue: selectedId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: expense
                    ? l10n.paymentAccount
                    : l10n.incomeDestinationAccount,
                helperText: accounts!.isLoading
                    ? l10n.loading
                    : accounts.hasError
                    ? l10n.accountLoadFailed
                    : choices.isEmpty
                    ? l10n.paymentNoticeNoAccounts
                    : null,
              ),
              items: [
                for (final account in choices)
                  DropdownMenuItem(
                    value: account.id,
                    child: Text(
                      DefaultLedgerLabels.account(context, account),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: choices.isEmpty
                  ? null
                  : (value) => setState(() => _accountId = value),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: draft == null || selectedId == null
              ? null
              : () => Navigator.pop<ReviewedPaymentNotice>(context, (
                  draft: draft,
                  accountId: selectedId,
                )),
          child: Text(l10n.paymentNoticeReview),
        ),
      ],
    );
  }
}
