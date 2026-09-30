import 'dart:math';
import 'package:flutter/material.dart';

// ============================================================================
// 1. 모델 & 정산 알고리즘
// ============================================================================
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
    if (memberIds.isEmpty || expenses.isEmpty) return [];

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
          amount: (settleAmount / 10).round() * 10,
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

// ============================================================================
// 2. 메인 앱
// ============================================================================
void main() {
  runApp(const CampingApp());
}

class CampingApp extends StatelessWidget {
  const CampingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '캠핑 공유 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CampingHomeScreen(),
    );
  }
}

class CampingHomeScreen extends StatefulWidget {
  const CampingHomeScreen({super.key});

  @override
  State<CampingHomeScreen> createState() => _CampingHomeScreenState();
}

class _CampingHomeScreenState extends State<CampingHomeScreen> {
  int _selectedIndex = 0;

  // 빈 데이터로 초기화 (샘플 데이터 제거)
  final List<String> members = ['나', '동행자1', '동행자2'];
  final List<Map<String, dynamic>> checklists = [];
  final List<Map<String, String>> journals = [];
  final List<ExpenseItem> expenses = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⛺ 함께하는 캠핑 여행', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('멤버: 나, 동행자1, 동행자2', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildChecklistTab(),
          _buildTimelineTab(),
          _buildSettlementTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist_rtl), label: '준비물'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), label: '타임라인'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: '정산'),
        ],
      ),
    );
  }

  // 1. 준비물 체크리스트 탭
  Widget _buildChecklistTab() {
    return Scaffold(
      body: checklists.isEmpty
          ? const Center(
              child: Text(
                '등록된 준비물이 없습니다.\n하단 버튼을 눌러 준비물을 추가해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: checklists.length,
              itemBuilder: (context, index) {
                final item = checklists[index];
                return Card(
                  child: CheckboxListTile(
                    title: Text(item['title']),
                    subtitle: Text('담당: ${item['assignee']} | 분류: ${item['category']}'),
                    value: item['done'],
                    onChanged: (val) {
                      setState(() {
                        checklists[index]['done'] = val ?? false;
                      });
                    },
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          checklists.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChecklistDialog,
        icon: const Icon(Icons.add),
        label: const Text('준비물 추가'),
      ),
    );
  }

  // 2. 타임라인 탭
  Widget _buildTimelineTab() {
    return Scaffold(
      body: journals.isEmpty
          ? const Center(
              child: Text(
                '아직 작성된 메모가 없습니다.\n캠핑 기록이나 메모를 추가해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: journals.length,
              itemBuilder: (context, index) {
                final note = journals[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_note, color: Colors.green),
                    title: Text(note['content'] ?? ''),
                    subtitle: Text('작성자: ${note['author']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          journals.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddJournalDialog,
        icon: const Icon(Icons.border_color),
        label: const Text('기록 작성'),
      ),
    );
  }

  // 3. 정산 탭
  Widget _buildSettlementTab() {
    final transfers = SettlementCalculator.calculate(
      memberIds: members,
      expenses: expenses,
    );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('💡 최소 송금 정산 결과', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (transfers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('등록된 지출 내역이 없거나 정산할 내용이 없습니다.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...transfers.map((t) => Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    title: Text('${t.fromUserId} ➔ ${t.toUserId}'),
                    subtitle: Text('보낼 금액: ${t.amount.toInt()}원'),
                  ),
                )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🧾 등록된 지출 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${expenses.length}건', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('지출 내역이 없습니다.\n마트 장보기나 예약비를 입력해 보세요.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...expenses.map((e) => Card(
                  child: ListTile(
                    title: Text(e.title),
                    subtitle: Text('결제자: ${e.payerId} (${e.participantIds.join(', ')} 참여)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${e.amount.toInt()}원', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              expenses.removeWhere((item) => item.id == e.id);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add_card),
        label: const Text('지출 등록'),
      ),
    );
  }

  // --- 다이얼로그 팝업 창들 ---

  void _showAddChecklistDialog() {
    final titleController = TextEditingController();
    String selectedAssignee = members.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('준비물 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: '준비물 이름 (예: 텐트, 고기)')),
            DropdownButtonFormField<String>(
              value: selectedAssignee,
              items: members.map((m) => DropdownMenuItem(value: m, child: Text('담당자: $m'))).toList(),
              onChanged: (val) => selectedAssignee = val ?? members.first,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  checklists.add({
                    'title': titleController.text,
                    'assignee': selectedAssignee,
                    'category': '공통',
                    'done': false,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showAddJournalDialog() {
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('타임라인 메모 추가'),
        content: TextField(controller: contentController, decoration: const InputDecoration(labelText: '내용 (예: 텐트 설치 완료!)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (contentController.text.isNotEmpty) {
                setState(() {
                  journals.add({'content': contentController.text, 'author': '나'});
                });
                Navigator.pop(context);
              }
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedPayer = members.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지출 내역 등록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: '지출 내용 (예: 하나로마트)')),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '금액 (원)')),
            DropdownButtonFormField<String>(
              value: selectedPayer,
              items: members.map((m) => DropdownMenuItem(value: m, child: Text('결제한 사람: $m'))).toList(),
              onChanged: (val) => selectedPayer = val ?? members.first,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              final double? amount = double.tryParse(amountController.text);
              if (titleController.text.isNotEmpty && amount != null) {
                setState(() {
                  expenses.add(ExpenseItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    payerId: selectedPayer,
                    amount: amount,
                    participantIds: List.from(members), // 전체 참여
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }
}
