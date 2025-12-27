import 'dart:convert'; // JSON 파싱용
import 'dart:io'; // IPv6 확인용
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import '../widgets/glass_card.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  // 화면에 표시할 데이터 변수들
  String _localIp = "Loading...";
  String _ipv6 = "Checking..."; // [추가] IPv6
  String _publicIp = "Loading...";
  String _isp = "Loading...";   // [추가] 통신사 정보 (예: KT, SK Broadband)
  String _location = "Loading...";// [추가] 국가/도시 (예: Seoul, KR)

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
  }

  Future<void> _initNetworkInfo() async {
    final info = NetworkInfo();
    
    // 1. 내부 IP (IPv4)
    String? wifiIp = await info.getWifiIP();
    
    // 2. 내부 IP (IPv6) 찾기
    String ipv6 = "Not Detected";
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        // 루프백(내부) 주소가 아닌 것 중에서 IPv6 찾기
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv6 && !addr.isLoopback) {
            ipv6 = addr.address;
            // IPv6는 주소가 너무 길어서 뒤에 %... 붙는거 떼줌 (인터페이스 식별자)
            if (ipv6.contains('%')) {
              ipv6 = ipv6.split('%')[0];
            }
            break;
          }
        }
      }
    } catch (_) {}

    // 3. 외부 정보 가져오기 (ipwho.is API 사용 - 무료, HTTPS 지원)
    String publicIp = "Error";
    String isp = "Unknown";
    String location = "Unknown";

    try {
      final response = await http.get(Uri.parse('https://ipwho.is/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          publicIp = data['ip'];
          isp = data['connection']['isp'] ?? "Unknown ISP"; // 통신사
          
          final city = data['city'];
          final country = data['country_code'];
          location = "$city, $country"; // 예: Seoul, KR
        } else {
          publicIp = "Limit Reached";
        }
      }
    } catch (_) {
      publicIp = "Check Internet";
    }

    if (mounted) {
      setState(() {
        _localIp = wifiIp ?? "Not Connected";
        _ipv6 = ipv6;
        _publicIp = publicIp;
        _isp = isp;
        _location = location;
      });
    }
  }

  // UI 구성 (복사 기능 포함)
  Widget _buildInfoRow(String title, String value, IconData icon) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Copied '$value'"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white24,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded( // 텍스트가 길어지면 줄바꿈 등을 위해 Expanded 사용
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'RobotoMono',
                    ),
                    overflow: TextOverflow.ellipsis, // 너무 길면 ... 처리
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // 내용이 많아지면 스크롤 가능하게
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 섹션 1: 로컬 네트워크 (내 기기)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10, bottom: 10),
                child: Text("DEVICE NETWORK", style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            GlassCard(
              child: Column(
                children: [
                  _buildInfoRow("IPv4 Address", _localIp, Icons.wifi),
                  const Divider(color: Colors.white10),
                  _buildInfoRow("IPv6 Address", _ipv6, Icons.filter_6),
                ],
              ),
            ),
            
            const SizedBox(height: 25),

            // 섹션 2: 인터넷 (외부망)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10, bottom: 10),
                child: Text("INTERNET CONNECTION", style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            GlassCard(
              child: Column(
                children: [
                  _buildInfoRow("Public IP", _publicIp, Icons.public),
                  const Divider(color: Colors.white10),
                  _buildInfoRow("ISP (Provider)", _isp, Icons.dns), // 통신사 정보
                  const Divider(color: Colors.white10),
                  _buildInfoRow("Location", _location, Icons.location_on), // 지역 정보
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Long press info to copy",
              style: TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}