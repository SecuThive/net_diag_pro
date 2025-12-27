import 'package:flutter/material.dart';
import 'package:lan_scanner/lan_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../widgets/glass_card.dart';

class LanScanScreen extends StatefulWidget {
  const LanScanScreen({super.key});

  @override
  State<LanScanScreen> createState() => _LanScanScreenState();
}

class _LanScanScreenState extends State<LanScanScreen> {
  final List<Host> _hosts = [];
  bool _isScanning = false;
  double _progress = 0.0;
  String _currentSubnet = "Ready to scan";

  // 스캔 시작 함수
  Future<void> _scanNetwork() async {
    setState(() {
      _hosts.clear();
      _isScanning = true;
      _progress = 0.0;
      _currentSubnet = "Getting Network Info...";
    });

    try {
      final String? ip = await NetworkInfo().getWifiIP();
      if (ip == null) {
        setState(() {
          _isScanning = false;
          _currentSubnet = "Not connected to WiFi";
        });
        return;
      }

      // 내 IP가 192.168.0.5 라면 -> 192.168.0 까지 자름
      final String subnet = ip.substring(0, ip.lastIndexOf('.'));
      
      setState(() {
        _currentSubnet = "Scanning $subnet.1 ~ $subnet.255 ...";
      });

      final scanner = LanScanner();
      
      // 같은 대역의 모든 IP (1~255)를 빠르게 검사
      final stream = scanner.icmpScan(
        subnet, 
        firstIP: 1,
        lastIP: 255,
        progressCallback: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );

      stream.listen((Host host) {
        if (mounted) setState(() => _hosts.add(host));
      }).onDone(() {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _currentSubnet = "Scan Complete. Found ${_hosts.length} devices.";
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _currentSubnet = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 컨트롤 카드
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("LAN SCANNER", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text(_currentSubnet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _isScanning ? null : _scanNetwork,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor.withOpacity(0.2),
                        foregroundColor: primaryColor,
                        elevation: 0,
                        side: BorderSide(color: primaryColor.withOpacity(0.5)),
                      ),
                      child: Text(_isScanning ? "Scanning" : "SCAN"),
                    ),
                  ],
                ),
                if (_isScanning) ...[
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white10,
                    color: primaryColor,
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 검색 결과 리스트
          Expanded(
            child: _hosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_find_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 10),
                        Text("Scan to find devices", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                  )
                : GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: _hosts.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                      itemBuilder: (context, index) {
                        final host = _hosts[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.desktop_windows, color: primaryColor, size: 20),
                          ),
                          title: Text(host.internetAddress.address, style: const TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
                          subtitle: Text("Ping: ${host.pingTime?.inMilliseconds ?? '?'}ms", style: const TextStyle(fontSize: 12, color: Colors.white54)),
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