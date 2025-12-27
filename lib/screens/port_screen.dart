import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/glass_card.dart';

class PortScreen extends StatefulWidget {
  const PortScreen({super.key});

  @override
  State<PortScreen> createState() => _PortScreenState();
}

class _PortScreenState extends State<PortScreen> {
  final TextEditingController _hostController = TextEditingController();
  bool _isScanning = false;

  // 검사 결과 리스트 (포트번호, 상태, 서비스명)
  final List<Map<String, dynamic>> _scanResults = [];

  // 우리가 검사할 '주요 포트' 리스트 정의
  final List<Map<String, dynamic>> _targetPorts = [
    {'port': 21, 'service': 'FTP (File Transfer)'},
    {'port': 22, 'service': 'SSH (Secure Shell)'},
    {'port': 23, 'service': 'Telnet'},
    {'port': 53, 'service': 'DNS'},
    {'port': 80, 'service': 'HTTP (Web)'},
    {'port': 443, 'service': 'HTTPS (Secure Web)'},
    {'port': 3306, 'service': 'MySQL Database'},
    {'port': 3389, 'service': 'RDP (Remote Desktop)'},
    {'port': 8080, 'service': 'HTTP Proxy'},
  ];

  Future<void> _scanPorts() async {
    if (_hostController.text.isEmpty) return;
    
    FocusScope.of(context).unfocus();

    setState(() {
      _isScanning = true;
      _scanResults.clear(); // 이전 결과 초기화
    });

    // 하나씩 순서대로 검사 (비동기)
    for (var target in _targetPorts) {
      final int port = target['port'];
      final String service = target['service'];
      
      bool isOpen = false;

      try {
        // 1초 안에 연결 안 되면 닫힌 걸로 간주 (빠른 스캔을 위해)
        final socket = await Socket.connect(
          _hostController.text, 
          port, 
          timeout: const Duration(milliseconds: 1000)
        );
        socket.destroy();
        isOpen = true;
      } catch (e) {
        isOpen = false;
      }

      // 결과 리스트에 추가하고 화면 갱신 (스캔되는 모습 실시간 노출)
      if (mounted) {
        setState(() {
          _scanResults.add({
            'port': port,
            'service': service,
            'isOpen': isOpen,
          });
        });
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 1. 입력창 (도메인만 입력)
          GlassCard(
            child: TextField(
              controller: _hostController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress, // 도메인 입력 편하게
              decoration: const InputDecoration(
                labelText: "Target Host",
                labelStyle: TextStyle(color: Colors.white54),
                hintText: "IP or Domain (e.g. google.com)",
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.dns, color: Colors.white54),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. 스캔 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanPorts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
              ),
              icon: _isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.radar),
              label: Text(_isScanning ? "Scanning Common Ports..." : "SCAN PORTS"),
            ),
          ),
          const SizedBox(height: 20),

          // 3. 결과 리스트
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Text(
                      "Ready to scan",
                      style: TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                  )
                : GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: _scanResults.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                      itemBuilder: (context, index) {
                        final result = _scanResults[index];
                        final bool isOpen = result['isOpen'];

                        return ListTile(
                          leading: Icon(
                            isOpen ? Icons.check_circle : Icons.cancel,
                            color: isOpen ? Colors.greenAccent : Colors.redAccent.withOpacity(0.5),
                          ),
                          title: Text(
                            "Port ${result['port']}",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                          subtitle: Text(
                            result['service'],
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isOpen ? Colors.green : Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isOpen ? "OPEN" : "CLOSED",
                              style: TextStyle(
                                color: isOpen ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}