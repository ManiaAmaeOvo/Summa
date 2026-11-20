import 'dart:math' as math;

import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/transactions/expense_record.dart';

enum DebtDirection {
  debt,
  receivable;

  static DebtDirection? forAccount(AccountKind kind) => switch (kind) {
    AccountKind.creditLine || AccountKind.thirdPartyPayable => debt,
    AccountKind.receivable => receivable,
    _ => null,
  };
}

typedef DebtInstallment = ({
  DateTime dueOn,
  int principalMinor,
  int interestMinor,
});

class DebtContractDraft {
  const DebtContractDraft({
    required this.accountId,
    required this.name,
    required this.counterparty,
    required this.direction,
    required this.currency,
    required this.originalPrincipalMinor,
    required this.expectedInterestMinor,
    required this.dueOn,
    required this.installments,
  });

  final String accountId;
  final String name;
  final String counterparty;
  final DebtDirection direction;
  final String currency;
  final int originalPrincipalMinor;
  final int expectedInterestMinor;
  final DateTime dueOn;
  final List<DebtInstallment> installments;

  bool get isValid {
    if (accountId.isEmpty ||
        !validDebtName(name) ||
        !validDebtName(counterparty) ||
        !currencyMinorDigits.containsKey(currency) ||
        originalPrincipalMinor <= 0 ||
        expectedInterestMinor < 0 ||
        !isPlanningDay(dueOn) ||
        installments.isEmpty ||
        installments.length > maxDebtInstallments) {
      return false;
    }
    var principal = originalPrincipalMinor;
    var interest = expectedInterestMinor;
    DateTime? previous;
    for (final row in installments) {
      if (!isPlanningDay(row.dueOn) ||
          row.dueOn.isAfter(dueOn) ||
          previous != null && !row.dueOn.isAfter(previous) ||
          row.principalMinor < 0 ||
          row.interestMinor < 0 ||
          row.principalMinor > principal ||
          row.interestMinor > interest ||
          row.principalMinor == 0 && row.interestMinor == 0) {
        return false;
      }
      previous = row.dueOn;
      principal -= row.principalMinor;
      interest -= row.interestMinor;
    }
    return principal == 0 && interest == 0;
  }
}

const maxDebtInstallments = 120;

bool validDebtName(String value) =>
    value.trim().isNotEmpty && value.trim().length <= 60;

enum DebtLinkKind { principal, interest }

typedef DebtLink = ({
  String id,
  String entryId,
  DebtLinkKind kind,
  bool voided,
});

class DebtContract {
  const DebtContract({
    required this.draft,
    required this.accountName,
    required this.balanceMinor,
    required this.links,
  });

  final DebtContractDraft draft;
  final String accountName;
  final int balanceMinor;
  final List<DebtLink> links;
}

typedef DebtPayment = ({int principalMinor, int interestMinor, int feeMinor});

DebtPayment? debtPaymentAmounts(
  DebtDirection direction,
  DebtLinkKind kind, {
  required LedgerTransactionType type,
  required int debitMinor,
  required int amountMinor,
  required int interestMinor,
  required int feeMinor,
  required bool incomeToPersonalCash,
}) {
  if (kind == DebtLinkKind.interest) {
    return direction == DebtDirection.receivable &&
            type == LedgerTransactionType.income &&
            incomeToPersonalCash
        ? (principalMinor: 0, interestMinor: amountMinor, feeMinor: 0)
        : null;
  }
  return switch (direction) {
    DebtDirection.debt
        when type == LedgerTransactionType.repayment && debitMinor > 0 =>
      (
        principalMinor: debitMinor,
        interestMinor: interestMinor,
        feeMinor: feeMinor,
      ),
    DebtDirection.receivable when type.collectsReceivable && debitMinor < 0 => (
      principalMinor: -debitMinor,
      interestMinor: 0,
      feeMinor: 0,
    ),
    _ => null,
  };
}

DebtPayment? debtPaymentForRecord(
  DebtContractDraft contract,
  DebtLinkKind kind,
  LedgerRecord record,
) {
  if (record.isPending ||
      record.isRefund ||
      record.isReversal ||
      record.hasReversal ||
      record.needsReview ||
      record.currencyCode != contract.currency) {
    return null;
  }
  final posting = record.accountPostings
      .where(
        (row) =>
            row.accountId == contract.accountId &&
            row.currencyCode == contract.currency,
      )
      .firstOrNull;
  return debtPaymentAmounts(
    contract.direction,
    kind,
    type: record.type,
    debitMinor: posting?.debitMinor ?? 0,
    amountMinor: record.amountMinor,
    interestMinor: record.terms.interestMinor,
    feeMinor: record.terms.feeMinor,
    incomeToPersonalCash: record.accountPostings.any(
      (row) =>
          row.kind?.isPersonalCash == true &&
          row.currencyCode == contract.currency &&
          row.debitMinor > 0,
    ),
  );
}

typedef DebtInstallmentProgress = ({
  DebtInstallment installment,
  int principalRemainingMinor,
  int interestRemainingMinor,
});

typedef DebtSettlement = ({
  DebtLink link,
  LedgerRecord? record,
  DebtPayment? payment,
  List<DebtInstallment> allocations,
});

typedef DebtProgress = ({
  List<DebtInstallmentProgress> installments,
  List<DebtSettlement> settlements,
  BigInt linkedPrincipalMinor,
  BigInt unlinkedPrincipalMinor,
});

DebtProgress summarizeDebtContract(
  DebtContract contract,
  Iterable<LedgerRecord> transactions,
) {
  final draft = contract.draft;
  final byId = {for (final record in transactions) record.id: record};
  final linkedIds = {
    for (final link in contract.links)
      if (!link.voided) link.entryId,
  };
  var unlinkedPrincipal = BigInt.zero;
  for (final record in byId.values) {
    if (linkedIds.contains(record.id)) continue;
    final payment = debtPaymentForRecord(draft, DebtLinkKind.principal, record);
    if (payment != null) {
      unlinkedPrincipal += BigInt.from(payment.principalMinor);
    }
  }
  final activeFirst = [...contract.links]
    ..sort((a, b) {
      final first = byId[a.entryId]?.occurredAt;
      final second = byId[b.entryId]?.occurredAt;
      final order = first == null
          ? (second == null ? 0 : 1)
          : (second == null ? -1 : first.compareTo(second));
      return order != 0 ? order : a.entryId.compareTo(b.entryId);
    });
  final principalLeft = draft.installments
      .map((row) => row.principalMinor)
      .toList();
  final interestLeft = draft.installments
      .map((row) => row.interestMinor)
      .toList();
  final settlements = <DebtSettlement>[];
  var linkedPrincipal = BigInt.zero;
  for (final link in activeFirst) {
    final record = byId[link.entryId];
    final payment = link.voided || record == null
        ? null
        : debtPaymentForRecord(draft, link.kind, record);
    final allocations = <DebtInstallment>[];
    if (payment != null) {
      linkedPrincipal += BigInt.from(payment.principalMinor);
      var principal = payment.principalMinor;
      var interest = payment.interestMinor;
      for (
        var i = 0;
        i < draft.installments.length && (principal > 0 || interest > 0);
        i++
      ) {
        final payPrincipal = math.min(principal, principalLeft[i]);
        final payInterest = math.min(interest, interestLeft[i]);
        if (payPrincipal == 0 && payInterest == 0) continue;
        principal -= payPrincipal;
        interest -= payInterest;
        principalLeft[i] -= payPrincipal;
        interestLeft[i] -= payInterest;
        allocations.add((
          dueOn: draft.installments[i].dueOn,
          principalMinor: payPrincipal,
          interestMinor: payInterest,
        ));
      }
    }
    settlements.add((
      link: link,
      record: record,
      payment: payment,
      allocations: allocations,
    ));
  }
  return (
    installments: [
      for (final (i, row) in draft.installments.indexed)
        (
          installment: row,
          principalRemainingMinor: principalLeft[i],
          interestRemainingMinor: interestLeft[i],
        ),
    ],
    settlements: settlements.reversed.toList(),
    linkedPrincipalMinor: linkedPrincipal,
    unlinkedPrincipalMinor: unlinkedPrincipal,
  );
}

enum DebtContractError {
  invalid,
  accountInUse,
  unavailable,
  conflict,
  ineligible,
}

class DebtContractException implements Exception {
  const DebtContractException(this.error);
  final DebtContractError error;
}
