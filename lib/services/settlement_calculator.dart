import 'dart:math';

class ExpenseItem {
  final String id;
  final String title;
  final String payerId;
  final double amount;
  final List<String> participantIds;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.payerId,
    required this.amount,
    required this.participantIds,
  });
}

class TransferResult {
  final String fromUserId;
  final String toUserId;
  final double amount;

  TransferResult({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

class SettlementCalculator {
  static List<TransferResult> calculate({
    required List<String> memberIds,
    required List<ExpenseItem> expenses,
  }) {
    final Map<String, double> netBalances = {for (var id in memberIds) id: 0.0};

    for (final exp in expenses) {
      if (exp.participantIds.isEmpty || exp.amount <= 0) continue;

      final double splitAmount = exp.amount / exp.participantIds.length;
      netBalances[exp.payerId] = (netBalances[exp.payerId] ?? 0.0) + exp.amount;

      for (final participantId in exp.participantIds) {
        netBalances[participantId] =
            (netBalances[participantId] ?? 0.0) - splitAmount;
      }
    }

    final List<MapEntry<String, double>> debtors = [];
    final List<MapEntry<String, double>> creditors = [];

    netBalances.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(userId, -balance));
      } else if (balance > 0.01) {
        creditors.add(MapEntry(userId, balance));
      }
    });

    final List<TransferResult> transfers = [];
    int i = 0;
    int j = 0;

    while (i < debtors.length && j < creditors.length) {
      final debtor = debtors[i];
      final creditor = creditors[j];
      final double settleAmount = min(debtor.value, creditor.value);

      transfers.add(
        TransferResult(
          fromUserId: debtor.key,
          toUserId: creditor.key,
          amount: (settleAmount / 10).round() * 10, // 10원 단위 반올림
        ),
      );

      debtors[i] = MapEntry(debtor.key, debtor.value - settleAmount);
      creditors[j] = MapEntry(creditor.key, creditor.value - settleAmount);

      if (debtors[i].value <= 0.01) i++;
      if (creditors[j].value <= 0.01) j++;
    }

    return transfers;
  }
}
