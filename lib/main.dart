import 'dart:math';
import 'package:flutter/material.dart';

// ============================================================================
// 1. 정산 알고리즘 & 모델
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
// 2. 메인 앱 UI
// ============================================================================
void main() {
  runApp(const CampingApp());
}

class CampingApp extends StatelessWidget {
  const CampingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '캠핑 모임 정산',
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

  final List<String> members = ['김철수', '이영희', '박민수', '최지은'];
  final List<Map<String, dynamic>> checklists = [
    {'title': '리빙쉘 텐트 및 방수포', 'assignee': '김철수', 'done': true, 'category': '장비'},
    {'title': '삼겹살 2kg & 목살 1kg', 'assignee': '이영희', 'done': false, 'category': '식재료'},
    {'title': '참숯 및 장작 20kg', 'assignee': '박민수', 'done': true, 'category': '장비'},
    {'title': '침낭 & 이너매트', 'assignee': '개인', 'done': false, 'category': '개인'},
  ];

  final List<ExpenseItem> expenses = [
    ExpenseItem(
      id: '1',
      title: '하나로마트 장보기',
      payerId: '김철수',
      amount: 120000,
      participantIds: ['김철수', '이영희', '박민수', '최지은'],
    ),
    ExpenseItem(
      id: '2',
      title: '캠핑장 예약비',
      payerId: '이영희',
      amount: 80000,
      participantIds: ['김철수', '이영희', '박민수', '최지은'],
    ),
    ExpenseItem(
      id: '3',
      title: '주유비 및 등유',
      payerId: '박민수',
      amount: 45000,
      participantIds: ['김철수', '이영희', '박민수'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⛺ 2026 단풍 캠핑', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('초대코드: CAMP26', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('카카오톡 초대 링크가 클립보드에 복사되었습니다.')),
              );
            },
          ),
        ],
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
          NavigationDestination(icon: Icon(Icons.checklist_rtl), label: '체크리스트'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), label: '기록'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: '스마트 정산'),
        ],
      ),
    );
  }

  Widget _buildChecklistTab() {
    return ListView.builder(
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
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('설악산 캠핑장 날씨 브리핑', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text('기온: 18°C | 강수확률: 10% | 풍속: 2.1 m/s'),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.photo_camera, color: Colors.green),
            title: Text('텐트 설치 완료! 🔥'),
            subtitle: Text('작성자: 김철수 • 14:20'),
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementTab() {
    final transfers = SettlementCalculator.calculate(
      memberIds: members,
      expenses: expenses,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('🧾 지출 등록 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...expenses.map((e) => ListTile(
          dense: true,
          title: Text(e.title),
          subtitle: Text('결제자: ${e.payerId} (${e.participantIds.length}명 참여)'),
          trailing: Text('${e.amount.toInt()}원', style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
        const Divider(height: 32),
        const Text('💡 최소 이체 경로 정산서', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...transfers.map((t) => Card(
          color: Colors.green.shade50,
          child: ListTile(
            title: Text('${t.fromUserId} ➔ ${t.toUserId}'),
            subtitle: Text('보낼 금액: ${t.amount.toInt()}원'),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${t.toUserId}님에게 토스/카카오페이 송금 앱 연결')),
                );
              },
              child: const Text('송금하기'),
            ),
          ),
        )),
      ],
    );
  }
}
