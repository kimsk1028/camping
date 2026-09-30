import 'package:flutter/material.dart';

void main() {
  runApp(const CampingApp());
}

class CampingApp extends StatelessWidget {
  const CampingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '캠핑 모임 정산',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.forestGreen),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⛺ 2026 단풍 캠핑'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
              );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          Center(child: Text('⛺ 준비물 체크리스트 (실시간 동기화)')),
          Center(child: Text('📸 캠핑 타임라인 & 기록')),
          Center(child: Text('💰 최소 송금 스마트 정산')),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: '체크리스트'),
          NavigationDestination(icon: Icon(Icons.photo_library), label: '기록'),
          NavigationDestination(icon: Icon(Icons.calculate), label: '정산'),
        ],
      ),
    );
  }
}
