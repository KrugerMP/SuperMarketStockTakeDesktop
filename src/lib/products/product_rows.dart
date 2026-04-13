// Parse and sort `/products` JSON without assuming a fixed mod schema.

/// Keys tried first for "how much of this product" (ascending sort = lowest first).
const _countKeyCandidates = [
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

/// Map keys often used for a human-readable label (column order).
const kContainerClassKindKey = 'containerClassKind';
const _slotIndexKey = 'slotIndex';

const _priorityColumns = [
  'productId',
  'id',
  'sku',
  'name',
  'productName',
  'displayName',
  'containerClassKind',
  'ContainerClassKind',
  'storage · retailShelf',
  'totalCount',
  'total',
  'count',
  'quantity',
  'stock',
];

/// After merging `storage` + `retailShelf`, holds numeric total for sort and low-stock flash (not shown as a column).
const _mergedStorageRetailTotalKey = '_srTotal';

/// Rows with [sortTotalForRow] strictly below this value get a low-stock flash in the table.
const kLowStockFlashThreshold = 10;

/// Whether [row] is below [kLowStockFlashThreshold] for the same total used for sorting.
bool isLowStockFlashRow(Map<String, dynamic> row) =>
    sortTotalForRow(row) < kLowStockFlashThreshold;

/// Stable key to match the same product across storage vs retail shelf rows.
String? productStockCorrelationKey(Map<String, dynamic> row) {
  for (final k in ['productId', 'id', 'sku']) {
    final v = row[k];
    if (v != null && v.toString().trim().isNotEmpty) {
      return 'i:${k.toLowerCase()}:${v.toString().trim().toLowerCase()}';
    }
  }
  for (final k in ['productName', 'name', 'displayName']) {
    final v = row[k];
    if (v != null && v.toString().trim().isNotEmpty) {
      return 'n:${v.toString().trim().toLowerCase()}';
    }
  }
  return null;
}

/// Sums [sortTotalForRow] per [productStockCorrelationKey] for prepared **storage** pane rows.
Map<String, int> storageStockTotalsByProductKey(List<Map<String, dynamic>> storageRows) {
  final out = <String, int>{};
  for (final r in storageRows) {
    final key = productStockCorrelationKey(r);
    if (key == null) continue;
    final q = sortTotalForRow(r);
    out[key] = (out[key] ?? 0) + q;
  }
  return out;
}

/// Retail row: **orange** low-stock flash when some quantity still exists in storage for this product.
bool retailShelfUsesOrangeLowStockFlash(
  Map<String, dynamic> retailRow,
  Map<String, int> storageTotalsByProductKey,
) {
  if (!isLowStockFlashRow(retailRow)) return false;
  final key = productStockCorrelationKey(retailRow);
  if (key == null) return false;
  return (storageTotalsByProductKey[key] ?? 0) > 0;
}

bool _isSummedAggregateKey(String key) =>
    key == 'storage' || key == 'retailShelf' || _countKeyCandidates.contains(key);

/// Collapse multiple rows for the same product into one entry and sum quantity-like fields.
///
/// This lets multiple shelf/storage slots for the same product show as a single line
/// (for example, quantities `5` and `24` become `29`).
List<Map<String, dynamic>> aggregateRowsByProductKey(List<Map<String, dynamic>> rows) {
  final grouped = <String, Map<String, dynamic>>{};
  final passthrough = <Map<String, dynamic>>[];

  for (final row in rows) {
    final key = productStockCorrelationKey(row);
    if (key == null) {
      final copy = Map<String, dynamic>.from(row);
      copy.remove(_slotIndexKey);
      passthrough.add(copy);
      continue;
    }

    final current = grouped.putIfAbsent(key, () => <String, dynamic>{});
    for (final entry in row.entries) {
      final field = entry.key;
      if (field == _slotIndexKey) continue;

      final value = entry.value;
      if (!current.containsKey(field)) {
        current[field] = value;
        continue;
      }

      if (_isSummedAggregateKey(field)) {
        final next = (_asInt(current[field]) ?? 0) + (_asInt(value) ?? 0);
        current[field] = next;
      }
    }
  }

  return [...grouped.values, ...passthrough];
}

String _storageRetailDisplayCell(Object? v) {
  if (v == null) return '—';
  if (v is String && v.isEmpty) return '—';
  return v.toString();
}

/// Single column `storage · retailShelf` ("left · right"); keeps [_mergedStorageRetailTotalKey] for sorting/highlighting.
List<Map<String, dynamic>> mergeStorageAndRetailShelfColumns(List<Map<String, dynamic>> rows) {
  var any = false;
  for (final r in rows) {
    if (r.containsKey('storage') || r.containsKey('retailShelf')) {
      any = true;
      break;
    }
  }
  if (!any) return rows;

  const combinedKey = 'storage · retailShelf';
  return rows.map((r) {
    final hasStorage = r.containsKey('storage');
    final hasRetail = r.containsKey('retailShelf');
    if (!hasStorage && !hasRetail) {
      return Map<String, dynamic>.from(r);
    }
    final out = Map<String, dynamic>.from(r);
    final sum = (_asInt(out['storage']) ?? 0) + (_asInt(out['retailShelf']) ?? 0);
    out[combinedKey] =
        '${_storageRetailDisplayCell(out['storage'])} · ${_storageRetailDisplayCell(out['retailShelf'])}';
    out.remove('storage');
    out.remove('retailShelf');
    out[_mergedStorageRetailTotalKey] = sum;
    return out;
  }).toList();
}

int sortTotalForRow(Map<String, dynamic> row) {
  if (row.containsKey(_mergedStorageRetailTotalKey)) {
    return _asInt(row[_mergedStorageRetailTotalKey]) ?? 0;
  }
  if (row.containsKey('storage') || row.containsKey('retailShelf')) {
    return (_asInt(row['storage']) ?? 0) + (_asInt(row['retailShelf']) ?? 0);
  }
  for (final key in _countKeyCandidates) {
    final n = _asInt(row[key]);
    if (n != null) return n;
  }
  var sum = 0;
  var any = false;
  for (final v in row.values) {
    final n = _asInt(v);
    if (n != null) {
      any = true;
      sum += n;
    }
  }
  return any ? sum : 0;
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is num) return v.round();
  if (v is String) {
    return int.tryParse(v) ?? double.tryParse(v)?.round();
  }
  return null;
}

Map<String, dynamic> _asRowMap(Object? e) {
  if (e is Map<String, dynamic>) return e;
  if (e is Map) return Map<String, dynamic>.from(e);
  return {'value': e};
}

/// Pull a list of row maps from a `/products` response (object or array root).
List<Map<String, dynamic>> extractProductRows(Object? decoded) {
  if (decoded == null) return [];

  if (decoded is List) {
    return decoded.map(_asRowMap).toList();
  }

  if (decoded is! Map) return [];

  final map = Map<String, dynamic>.from(decoded);

  const listKeys = [
    'products',
    'items',
    'data',
    'productList',
    'values',
    'list',
  ];
  for (final key in listKeys) {
    final v = map[key];
    if (v is List) {
      return v.map(_asRowMap).toList();
    }
  }

  List<Map<String, dynamic>>? best;
  var bestLen = -1;
  for (final entry in map.entries) {
    final v = entry.value;
    if (v is! List) continue;
    final rows = v.map(_asRowMap).toList();
    if (rows.length > bestLen) {
      bestLen = rows.length;
      best = rows;
    }
  }
  if (best != null) return best;

  return [_asRowMap(map)];
}

String? topLevelError(Object? decoded) {
  if (decoded is Map) {
    final err = decoded['error'];
    if (err == null) return null;
    if (err is String) return err;
    return err.toString();
  }
  return null;
}

/// Bucket derived from [kContainerClassKindKey] (or `ContainerClassKind`) for split layout.
enum ContainerClassBucket {
  storage,
  retailShelf,
  other,
}

ContainerClassBucket containerClassBucketForRow(Map<String, dynamic> row) {
  final raw = row[kContainerClassKindKey] ?? row['ContainerClassKind'];
  if (raw == null) return ContainerClassBucket.other;
  final n = raw.toString().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  if (n == 'storage') return ContainerClassBucket.storage;
  if (n == 'retailshelf' || n == 'retainshelf') return ContainerClassBucket.retailShelf;
  if (n.contains('retail') && n.contains('shelf')) return ContainerClassBucket.retailShelf;
  return ContainerClassBucket.other;
}

class ContainerClassSplit {
  const ContainerClassSplit({
    required this.storage,
    required this.retailShelf,
    required this.other,
  });

  final List<Map<String, dynamic>> storage;
  final List<Map<String, dynamic>> retailShelf;
  final List<Map<String, dynamic>> other;

  int get totalLength => storage.length + retailShelf.length + other.length;
}

ContainerClassSplit splitRowsByContainerClassKind(List<Map<String, dynamic>> rows) {
  final storage = <Map<String, dynamic>>[];
  final retail = <Map<String, dynamic>>[];
  final other = <Map<String, dynamic>>[];
  for (final r in rows) {
    switch (containerClassBucketForRow(r)) {
      case ContainerClassBucket.storage:
        storage.add(r);
      case ContainerClassBucket.retailShelf:
        retail.add(r);
      case ContainerClassBucket.other:
        other.add(r);
    }
  }
  return ContainerClassSplit(storage: storage, retailShelf: retail, other: other);
}

class ProductPaneData {
  const ProductPaneData({required this.rows, required this.columns});

  final List<Map<String, dynamic>> rows;
  final List<String> columns;
}

/// Sort, merge storage/retail counts, and build column list. [hiddenKeys] omitted from headers (e.g. redundant kind in side panes).
ProductPaneData prepareProductPane(
  List<Map<String, dynamic>> rows, {
  Set<String> hiddenKeys = const {},
}) {
  final copied = rows.map((e) => Map<String, dynamic>.from(e)).toList();
  var sorted = aggregateRowsByProductKey(copied);
  sorted = sortRowsByLowestTotalCount(sorted);
  sorted = mergeStorageAndRetailShelfColumns(sorted);
  final cols = columnOrderForRows(
    sorted,
    hiddenKeys: {...hiddenKeys, _slotIndexKey},
  );
  return ProductPaneData(rows: sorted, columns: cols);
}

/// Stable column order: priority keys first, then remaining keys sorted.
List<String> columnOrderForRows(
  List<Map<String, dynamic>> rows, {
  Set<String> hiddenKeys = const {},
}) {
  final keys = <String>{};
  for (final r in rows) {
    for (final k in r.keys) {
      if (!k.startsWith('_') && !hiddenKeys.contains(k)) keys.add(k);
    }
  }
  final list = keys.toList();
  int rank(String k) {
    final i = _priorityColumns.indexOf(k);
    return i >= 0 ? i : _priorityColumns.length;
  }

  list.sort((a, b) {
    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra.compareTo(rb);
    return a.compareTo(b);
  });
  return list;
}

/// Ascending [sortTotalForRow] — lowest quantity first (per pane, after aggregation).
List<Map<String, dynamic>> sortRowsByLowestTotalCount(List<Map<String, dynamic>> rows) {
  final indexed = rows.asMap().entries.toList();
  indexed.sort((a, b) {
    final ca = sortTotalForRow(a.value);
    final cb = sortTotalForRow(b.value);
    if (ca != cb) return ca.compareTo(cb);
    return a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}
