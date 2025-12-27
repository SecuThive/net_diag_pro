import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:fl_chart/fl_chart.dart'; // [필수] 차트 패키지
import '../widgets/glass_card.dart';

class PingScreen extends StatefulWidget {
  const PingScreen({super.key});

  @override
  State<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _logs = [];
  
  // 차트 데이터를 담을 리스트 (X: 순서, Y: 응답속도ms)
  final List<FlSpot> _pingSpots = [];
  int _counter = 0; // X축 좌표용 카운터

  bool _isRunning = false;
  Ping? _ping;

  void _startPing() {
    if (_controller.text.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isRunning = true;
      _logs.clear();
      _pingSpots.clear(); // 차트 초기화
      _counter = 0;
      _logs.add("Pinging ${_controller.text}...");
    });

    try {
      _ping = Ping(_controller.text, count: 50); // 50회 수행
      
      _ping!.stream.listen((event) {
        if (mounted) {
          setState(() {
            // 1. 로그 추가
            _logs.insert(0, event.toString()); // 최신 로그가 위로 오게

            // 2. 차트 데이터 추가 (응답이 있을 때만)
            if (event.response != null) {
              final ms = event.response!.time!.inMilliseconds.toDouble();
              _pingSpots.add(FlSpot(_counter.toDouble(), ms));
              _counter++;

              // 차트가 너무 빽빽해지면 앞부분 삭제 (최근 20개만 유지)
              if (_pingSpots.length > 20) {
                _pingSpots.removeAt(0);
              }
            }
          });
        }
      }).onDone(() {
        if (mounted) {
          setState(() {
            _isRunning = false;
            _logs.insert(0, "Ping Finished.");
          });
        }
      });
    } catch (e) {
      setState(() {
        _logs.insert(0, "Error: $e");
        _isRunning = false;
      });
    }
  }

  void _stopPing() {
    _ping?.stop();
    setState(() {
      _isRunning = false;
      _logs.insert(0, "Ping Stopped by user.");
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 1. 입력창
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress, // 도메인 입력 가능
                    decoration: const InputDecoration(
                      hintText: "IP or Domain (e.g. google.com)",
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.white54),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isRunning ? _stopPing : _startPing,
                  icon: Icon(
                    _isRunning ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                    color: _isRunning ? Colors.redAccent : primaryColor,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. 실시간 차트 영역 (데이터가 있을 때만 표시)
          if (_pingSpots.isNotEmpty)
            SizedBox(
              height: 150,
              child: GlassCard(
                padding: const EdgeInsets.only(right: 20, left: 10, top: 10, bottom: 10),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white10,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}ms',
                              style: const TextStyle(color: Colors.white30, fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _pingSpots,
                        isCurved: true,
                        color: primaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: primaryColor.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (_pingSpots.isNotEmpty) const SizedBox(height: 20),

          // 3. 로그 리스트
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(15),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.white70, 
                        fontFamily: 'RobotoMono', 
                        fontSize: 12
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