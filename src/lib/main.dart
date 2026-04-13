import 'dart:async';

import 'package:flutter/material.dart';

import 'api/stock_take_api_client.dart';
import 'products/product_rows.dart';
import 'widgets/products_pane_layout.dart';

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

class _LastProductsFetch {
  _LastProductsFetch({required this.at, required this.ok, this.detail});

  final DateTime at;
  final bool ok;
  final String? detail;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockTakeApiClient _api = StockTakeApiClient();
  Timer? _pollTimer;

  bool? _connected;
  bool _productsLoading = false;
  String? _productsError;
  String? _productsApiWarning;
  ProductPaneData _paneStorage = const ProductPaneData(rows: [], columns: []);
  ProductPaneData _paneRetail = const ProductPaneData(rows: [], columns: []);
  ProductPaneData _paneOther = const ProductPaneData(rows: [], columns: []);
  _LastProductsFetch? _lastFetch;
  bool _productsInFlight = false;

  static const _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollTick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _pollTick());
  }

  Future<void> _pollTick() async {
    await _checkConnection();
    await _loadProducts(silent: true);
  }

  Future<void> _checkConnection() async {
    try {
      await _api.getJsonMap('/ping');
      if (!mounted) return;
      setState(() => _connected = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _connected = false);
    }
  }

  void _setLastFetchLocked({required bool ok, String? detail}) {
    _lastFetch = _LastProductsFetch(at: DateTime.now(), ok: ok, detail: detail);
  }

  Future<void> _loadProducts({bool silent = false}) async {
    if (_productsInFlight) return;
    _productsInFlight = true;
    if (!silent && mounted) {
      setState(() {
        _productsLoading = true;
        _productsError = null;
      });
    }
    try {
      final raw = await _api.getJson('/products');
      if (!mounted) return;
      final warn = topLevelError(raw);
      final rows = extractProductRows(raw);
      final split = splitRowsByContainerClassKind(rows);
      const kindHidden = {'containerClassKind', 'ContainerClassKind'};
      final paneStorage = prepareProductPane(split.storage, hiddenKeys: kindHidden);
      final paneRetail = prepareProductPane(split.retailShelf, hiddenKeys: kindHidden);
      final paneOther = prepareProductPane(split.other, hiddenKeys: {});
      final w = warn != null && warn.isNotEmpty ? ' — API: $warn' : '';
      final detail =
          'OK, ${split.totalLength} row(s) — storage ${split.storage.length}, retailShelf ${split.retailShelf.length}, other ${split.other.length}$w';
      setState(() {
        _productsApiWarning = warn;
        _paneStorage = paneStorage;
        _paneRetail = paneRetail;
        _paneOther = paneOther;
        _productsError = null;
        _setLastFetchLocked(ok: true, detail: detail);
        if (!silent) _productsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (silent) {
        setState(() => _setLastFetchLocked(ok: false, detail: msg));
      } else {
        setState(() {
          _productsError = msg;
          _productsApiWarning = null;
          _paneStorage = const ProductPaneData(rows: [], columns: []);
          _paneRetail = const ProductPaneData(rows: [], columns: []);
          _paneOther = const ProductPaneData(rows: [], columns: []);
          _productsLoading = false;
          _setLastFetchLocked(ok: false, detail: msg);
        });
      }
    } finally {
      _productsInFlight = false;
      if (mounted && !silent && _productsLoading) {
        setState(() => _productsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperMarket Stock Take'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _ConnectionLed(connected: _connected),
            ),
          ),
          IconButton(
            onPressed: _productsLoading ? null : () => _loadProducts(silent: false),
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload products now',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_productsLoading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API base',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                SelectableText(
                  _api.baseUrl,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '/products every ${_pollInterval.inSeconds}s · split by containerClassKind · retail: in storage column after quantity · shelf <$kLowStockFlashThreshold: orange if stock in storage else red · other panes red',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                _LastFetchRow(fetch: _lastFetch),
              ],
            ),
          ),
          if (_productsError != null)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _productsError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ),
          if (_productsApiWarning != null && _productsApiWarning!.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSecondaryContainer),
                title: Text(
                  'API: ${_productsApiWarning!}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ProductsPaneLayout(
                storageColumns: _paneStorage.columns,
                storageRows: _paneStorage.rows,
                retailColumns: _paneRetail.columns,
                retailRows: _paneRetail.rows,
                otherColumns: _paneOther.columns,
                otherRows: _paneOther.rows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastFetchRow extends StatelessWidget {
  const _LastFetchRow({required this.fetch});

  final _LastProductsFetch? fetch;

  static String _hm(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = fetch;
    if (f == null) {
      return Text(
        'Last /products: —',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final ok = f.ok;
    final iconColor = ok ? theme.colorScheme.primary : theme.colorScheme.error;
    final line = '${_hm(f.at)} · ${f.detail ?? (ok ? 'OK' : 'Failed')}';
    return Tooltip(
      message: f.detail ?? line,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 14,
            color: iconColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionLed extends StatelessWidget {
  const _ConnectionLed({required this.connected});

  final bool? connected;

  @override
  Widget build(BuildContext context) {
    final color = switch (connected) {
      null => Theme.of(context).colorScheme.outline,
      true => Colors.green,
      false => Colors.red,
    };
    final message = switch (connected) {
      null => 'Checking connection…',
      true => 'Connected — mod API reachable (GET /ping)',
      false => 'Disconnected — mod not running or wrong host/port',
    };
    return Tooltip(
      message: message,
      child: Icon(Icons.circle, size: 14, color: color),
    );
  }
}
