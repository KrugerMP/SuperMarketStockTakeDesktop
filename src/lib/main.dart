import 'dart:convert';

import 'package:flutter/material.dart';

import 'api/stock_take_api_client.dart';

void main() {
  runApp(const StockTakeApp());
}

class StockTakeApp extends StatelessWidget {
  const StockTakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperMarket Stock Take',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockTakeApiClient _api = StockTakeApiClient();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _ping;

  Future<void> _refreshPing() async {
    setState(() {
      _loading = true;
      _error = null;
      _ping = null;
    });
    try {
      final json = await _api.getJsonMap('/ping');
      setState(() {
        _ping = json;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperMarket Stock Take'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refreshPing,
            icon: const Icon(Icons.refresh),
            tooltip: 'Ping API',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'API base',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              _api.baseUrl,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              SelectableText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_ping != null)
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(_ping),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
              )
            else
              Text(
                'Tap refresh to call GET /ping. Run the game with the mod on port 8080.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    );
  }
}
