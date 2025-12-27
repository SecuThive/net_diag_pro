import 'package:flutter/material.dart';
import '../widgets/bottom_ad_banner.dart'; // [중요] 광고 위젯 가져오기
import 'info_screen.dart';
import 'ping_screen.dart';
import 'port_screen.dart';
import 'lan_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const InfoScreen(),
    const PingScreen(),
    const PortScreen(),
    const LanScanScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Net Diag Pro"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      // [수정] Column을 사용하여 (내용 + 광고) 구조로 변경
      body: Column(
        children: [
          // 1. 실제 앱 기능 화면 (남은 공간을 모두 차지하도록 Expanded 사용)
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: _pages[_selectedIndex],
            ),
          ),
          
          // 2. 하단 광고 (딱 50px 높이만 차지하며 항상 떠 있음)
          const SafeArea(
            top: false, // 위쪽 여백은 무시
            child: BottomAdBanner(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.network_check_outlined),
            selectedIcon: Icon(Icons.network_check),
            label: 'Ping',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'Ports',
          ),
          NavigationDestination(
            icon: Icon(Icons.lan_outlined),
            selectedIcon: Icon(Icons.lan),
            label: 'LAN',
          ),
        ],
      ),
    );
  }
}