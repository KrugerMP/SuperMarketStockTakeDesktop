import 'package:flutter/material.dart';

import '../products/product_rows.dart';

/// Scrollable grid-style table (row/column lines) for dense data.
class ProductsSpreadsheet extends StatefulWidget {
  const ProductsSpreadsheet({
    super.key,
    required this.columns,
    required this.rows,
    this.storageStockByProductKey,
  });

  final List<String> columns;
  final List<Map<String, dynamic>> rows;

  /// When set (retail shelf pane), shows an **in storage** column (totals from the storage pane
  /// for the same product key) placed **after** the first recognized quantity-style column when
  /// possible; low-stock rows pulse **orange** if that total is still positive
  /// ([retailShelfUsesOrangeLowStockFlash]); otherwise **red** like other panes.
  final Map<String, int>? storageStockByProductKey;

  @override
  State<ProductsSpreadsheet> createState() => _ProductsSpreadsheetState();
}

class _ProductsSpreadsheetState extends State<ProductsSpreadsheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;

  static const _cellStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.25,
  );

  /// Distinct from [ColorScheme.error] — “still in storage, needs shelving”.
  static const _orangeFlash = Color(0xFFE65100);

  /// First match in [columns] wins; **in storage** is inserted immediately after this column.
  static const _quantityColumnPriority = [
    'storage · retailShelf',
    'totalCount',
    'total',
    'count',
    'quantity',
    'stock',
    'amount',
    'shelfCount',
    'owned',
    'inventoryCount',
    'qty',
  ];

  /// Index of the quantity column to sit **in storage** next to; `-1` if none → column leads the table.
  static int _quantityColumnIndex(List<String> columns) {
    for (final key in _quantityColumnPriority) {
      final i = columns.indexOf(key);
      if (i >= 0) return i;
    }
    return -1;
  }

  static bool _anyLowStock(List<Map<String, dynamic>> rows) =>
      rows.any(isLowStockFlashRow);

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (_anyLowStock(widget.rows)) {
      _flash.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ProductsSpreadsheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final any = _anyLowStock(widget.rows);
    if (any && !_flash.isAnimating) {
      _flash.repeat(reverse: true);
    } else if (!any && _flash.isAnimating) {
      _flash.stop();
      _flash.reset();
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;

    if (widget.columns.isEmpty) {
      return Center(
        child: Text(
          widget.rows.isEmpty ? 'No columns (empty response).' : 'No columns.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final low = _anyLowStock(widget.rows);
    if (!low) {
      return _buildScrollableTable(context, outline, flashT: null);
    }
    return AnimatedBuilder(
      animation: _flash,
      builder: (context, _) => _buildScrollableTable(context, outline, flashT: _flash.value),
    );
  }

  Widget _buildScrollableTable(
    BuildContext context,
    Color outline, {
    required double? flashT,
  }) {
    final showStorageColumn = widget.storageStockByProductKey != null;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: outline, width: 1),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
              ),
              children: _headerCells(showStorageColumn),
            ),
            ...widget.rows.map(
              (row) {
                final t = flashT != null && isLowStockFlashRow(row) ? flashT : 0.0;
                final accent = _lowStockAccentForRow(row, scheme);
                final onSurface = scheme.onSurface;
                final bg = Color.lerp(
                  Colors.transparent,
                  accent.withValues(alpha: 0.28),
                  t,
                )!;
                final fg = Color.lerp(onSurface, accent, t * 0.92)!;
                return TableRow(
                  decoration: BoxDecoration(color: bg),
                  children: _dataCells(
                    row,
                    showStorageColumn,
                    fg,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _headerCells(bool showStorageColumn) {
    final cols = widget.columns;
    if (!showStorageColumn) {
      return cols
          .map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(c, style: _cellStyle.copyWith(fontWeight: FontWeight.w600)),
            ),
          )
          .toList();
    }
    final qtyIdx = _quantityColumnIndex(cols);
    final out = <Widget>[];
    for (var i = 0; i < cols.length; i++) {
      if (qtyIdx < 0 && i == 0) {
        out.add(_headerInStorageCell());
      }
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(cols[i], style: _cellStyle.copyWith(fontWeight: FontWeight.w600)),
        ),
      );
      if (qtyIdx >= 0 && i == qtyIdx) {
        out.add(_headerInStorageCell());
      }
    }
    return out;
  }

  Widget _headerInStorageCell() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        'in storage',
        style: _cellStyle.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  List<Widget> _dataCells(
    Map<String, dynamic> row,
    bool showStorageColumn,
    Color fg,
  ) {
    final cols = widget.columns;
    final storageMap = widget.storageStockByProductKey;
    if (!showStorageColumn || storageMap == null) {
      return cols
          .map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                _formatCell(row[c]),
                style: _cellStyle.copyWith(color: fg),
              ),
            ),
          )
          .toList();
    }
    final qtyIdx = _quantityColumnIndex(cols);
    final out = <Widget>[];
    for (var i = 0; i < cols.length; i++) {
      if (qtyIdx < 0 && i == 0) {
        out.add(_dataInStorageCell(row, storageMap, fg));
      }
      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            _formatCell(row[cols[i]]),
            style: _cellStyle.copyWith(color: fg),
          ),
        ),
      );
      if (qtyIdx >= 0 && i == qtyIdx) {
        out.add(_dataInStorageCell(row, storageMap, fg));
      }
    }
    return out;
  }

  Widget _dataInStorageCell(
    Map<String, dynamic> row,
    Map<String, int> storageMap,
    Color fg,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        _inStorageCellText(row, storageMap),
        style: _cellStyle.copyWith(color: fg),
      ),
    );
  }

  Color _lowStockAccentForRow(Map<String, dynamic> row, ColorScheme scheme) {
    final map = widget.storageStockByProductKey;
    if (map != null &&
        retailShelfUsesOrangeLowStockFlash(row, map)) {
      return _orangeFlash;
    }
    return scheme.error;
  }

  static String _formatCell(Object? v) {
    if (v == null) return '';
    if (v is String || v is num || v is bool) return v.toString();
    return v.toString();
  }

  static String _inStorageCellText(Map<String, dynamic> row, Map<String, int> storageByKey) {
    final key = productStockCorrelationKey(row);
    if (key == null) return '—';
    return (storageByKey[key] ?? 0).toString();
  }
}
