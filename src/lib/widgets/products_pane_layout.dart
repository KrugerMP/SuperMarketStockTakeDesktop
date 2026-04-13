import 'package:flutter/material.dart';

import '../products/product_rows.dart';
import 'products_spreadsheet.dart';

/// Top row: [storage] | [retail shelf]; bottom: other `containerClassKind` values.
class ProductsPaneLayout extends StatelessWidget {
  const ProductsPaneLayout({
    super.key,
    required this.storageColumns,
    required this.storageRows,
    required this.retailColumns,
    required this.retailRows,
    required this.otherColumns,
    required this.otherRows,
  });

  final List<String> storageColumns;
  final List<Map<String, dynamic>> storageRows;
  final List<String> retailColumns;
  final List<Map<String, dynamic>> retailRows;
  final List<String> otherColumns;
  final List<Map<String, dynamic>> otherRows;

  static const _topFlex = 5;
  static const _bottomFlex = 3;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    final storageTotals = storageStockTotalsByProductKey(storageRows);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: _topFlex,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Pane(
                  title: 'Storage',
                  subtitle: 'containerClassKind → storage',
                  columns: storageColumns,
                  rows: storageRows,
                  storageStockByProductKey: null,
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: dividerColor),
              Expanded(
                child: _Pane(
                  title: 'Retail shelf',
                  subtitle: 'containerClassKind → retailShelf',
                  columns: retailColumns,
                  rows: retailRows,
                  storageStockByProductKey: storageTotals,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
        Expanded(
          flex: _bottomFlex,
          child: _Pane(
            title: 'Other',
            subtitle: 'All other containerClassKind values',
            columns: otherColumns,
            rows: otherRows,
            storageStockByProductKey: null,
          ),
        ),
      ],
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.subtitle,
    required this.columns,
    required this.rows,
    required this.storageStockByProductKey,
  });

  final String title;
  final String subtitle;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final Map<String, int>? storageStockByProductKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: scheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${rows.length} row(s) · $subtitle',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ProductsSpreadsheet(
            columns: columns,
            rows: rows,
            storageStockByProductKey: storageStockByProductKey,
          ),
        ),
      ],
    );
  }
}
