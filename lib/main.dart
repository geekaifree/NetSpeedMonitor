import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NetSpeedMonitorApp());

class NetSpeedMonitorApp extends StatelessWidget {
  const NetSpeedMonitorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '网速监控', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true, brightness: Brightness.dark),
    home: const NetSpeedHomePage(),
  );
}

class NetSpeedHomePage extends StatefulWidget {
  const NetSpeedHomePage({super.key});
  @override
  State<NetSpeedHomePage> createState() => _NetSpeedHomePageState();
}

class _NetSpeedHomePageState extends State<NetSpeedHomePage> {
  double _downloadSpeed = 0, _uploadSpeed = 0;
  double _totalDownload = 0, _totalUpload = 0;
  List<double> _downloadHistory = [], _uploadHistory = [];
  Timer? _timer;
  final _rng = Random();
  bool _monitoring = true;
  String _unit = 'KB/s';
  double _maxSpeed = 0;

  @override
  void initState() { super.initState(); _startMonitoring(); }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_monitoring) return;
      setState(() {
        _downloadSpeed = 50 + _rng.nextDouble() * 500;
        _uploadSpeed = 10 + _rng.nextDouble() * 100;
        _totalDownload += _downloadSpeed / 1024;
        _totalUpload += _uploadSpeed / 1024;
        _downloadHistory.add(_downloadSpeed);
        _uploadHistory.add(_uploadSpeed);
        if (_downloadHistory.length > 60) _downloadHistory.removeAt(0);
        if (_uploadHistory.length > 60) _uploadHistory.removeAt(0);
        _maxSpeed = [..._downloadHistory, ..._uploadHistory].fold(0.0, (a, b) => a > b ? a : b);
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _formatSpeed(double speed) {
    if (_unit == 'MB/s') return '${(speed / 1024).toStringAsFixed(2)} MB/s';
    return '${speed.toStringAsFixed(1)} KB/s';
  }

  String _formatTotal(double mb) {
    if (mb > 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📶 网速监控'), centerTitle: true, actions: [
        IconButton(icon: Icon(_monitoring ? Icons.pause : Icons.play_arrow), onPressed: () => setState(() => _monitoring = !_monitoring), tooltip: _monitoring ? '暂停' : '继续'),
        PopupMenuButton<String>(icon: const Icon(Icons.speed), tooltip: '单位', itemBuilder: (ctx) => [const PopupMenuItem(value: 'KB/s', child: Text('KB/s')), const PopupMenuItem(value: 'MB/s', child: Text('MB/s'))], onSelected: (v) => setState(() => _unit = v)),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // 实时速度
        Row(children: [
          Expanded(child: _buildSpeedCard('⬇️ 下载', _formatSpeed(_downloadSpeed), Colors.green, _downloadSpeed / (_maxSpeed > 0 ? _maxSpeed : 1))),
          const SizedBox(width: 12),
          Expanded(child: _buildSpeedCard('⬆️ 上传', _formatSpeed(_uploadSpeed), Colors.blue, _uploadSpeed / (_maxSpeed > 0 ? _maxSpeed : 1))),
        ]),
        const SizedBox(height: 16),
        // 速度曲线
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('速度曲线 (60秒)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(height: 150, child: CustomPaint(painter: _SpeedChartPainter(downloadData: _downloadHistory, uploadData: _uploadHistory, maxSpeed: _maxSpeed), size: Size.infinite)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 12, height: 12, color: Colors.green), const SizedBox(width: 4), const Text('下载', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
            Container(width: 12, height: 12, color: Colors.blue), const SizedBox(width: 4), const Text('上传', style: TextStyle(fontSize: 12)),
          ]),
        ]))),
        const SizedBox(height: 16),
        // 流量统计
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('流量统计', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildStatRow('总下载', _formatTotal(_totalDownload), Icons.download, Colors.green),
          _buildStatRow('总上传', _formatTotal(_totalUpload), Icons.upload, Colors.blue),
          _buildStatRow('峰值下载', _formatSpeed(_downloadHistory.fold(0.0, (a, b) => a > b ? a : b)), Icons.trending_up, Colors.orange),
          _buildStatRow('峰值上传', _formatSpeed(_uploadHistory.fold(0.0, (a, b) => a > b ? a : b)), Icons.trending_up, Colors.purple),
        ]))),
        const SizedBox(height: 16),
        // 网络信息
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('网络信息', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildStatRow('连接类型', 'Wi-Fi', Icons.wifi, Colors.indigo),
          _buildStatRow('IP地址', '192.168.1.100', Icons.computer, Colors.grey),
          _buildStatRow('DNS', '8.8.8.8', Icons.dns, Colors.teal),
          _buildStatRow('延迟', '${15 + _rng.nextInt(20)} ms', Icons.timer, Colors.red),
        ]))),
      ])),
    );
  }

  Widget _buildSpeedCard(String label, String speed, Color color, double progress) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      const SizedBox(height: 8),
      Text(speed, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.1), color: color),
    ])));
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Icon(icon, size: 20, color: color), const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    ]));
  }
}

class _SpeedChartPainter extends CustomPainter {
  final List<double> downloadData, uploadData;
  final double maxSpeed;
  _SpeedChartPainter({required this.downloadData, required this.uploadData, required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    if (downloadData.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
    final max = maxSpeed > 0 ? maxSpeed : 1;

    void drawLine(List<double> data, Color color) {
      paint.color = color;
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = i * size.width / 60;
        final y = size.height - (data[i] / max * size.height);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    drawLine(downloadData, Colors.green);
    drawLine(uploadData, Colors.blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
