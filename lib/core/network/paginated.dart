/// A page of [T] as the API returned it, and the key of the page after it.
///
/// [next] is what the backend pages by — a page number, an offset or a cursor
/// — and null on the last page. Only the datasource reads it; everything above
/// passes it back unopened, so switching an endpoint from pages to cursors
/// touches the datasource alone:
///
/// ```dart
/// Future<Paginated<OrderModel>> fetchOrders({Object? next}) => safeApiCall(
///   apiCall: () async {
///     final response = await _dio.get(
///       ApiConstants.orders,
///       queryParameters: {'cursor': next, 'limit': 20},
///     );
///     return Paginated.fromCursorJson(
///       response.data as Map<String, dynamic>,
///       (e) => OrderModel.fromJson(e! as Map<String, dynamic>),
///     );
///   },
/// );
/// ```
///
/// Edit the factories' default keys to match your envelope.
class Paginated<T> {
  const Paginated({required this.items, this.next, this.total});

  /// A response that was never paginated server-side, read as the only page.
  factory Paginated.single(List<T> items) =>
      Paginated(items: items, total: items.length);

  /// The empty last page.
  const Paginated.empty() : items = const [], next = null, total = 0;

  /// `{page, limit, total, data}` — [next] is the following page number.
  ///
  /// Ask for the first page with `next ?? 1`.
  factory Paginated.fromPageJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT, {
    String dataKey = 'data',
    String pageKey = 'page',
    String limitKey = 'limit',
    String totalKey = 'total',
  }) {
    final items = _itemsOf(json[dataKey], fromJsonT);
    final page = _asInt(json[pageKey]) ?? 1;
    final limit = _asInt(json[limitKey]);
    final total = _asInt(json[totalKey]);
    return Paginated(
      items: items,
      total: total,
      next: _hasMore(items, limit, total, seen: page * (limit ?? items.length))
          ? page + 1
          : null,
    );
  }

  /// `{offset, limit, total, data}` — [next] is the following offset.
  ///
  /// Ask for the first page with `next ?? 0`.
  factory Paginated.fromOffsetJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT, {
    String dataKey = 'data',
    String offsetKey = 'offset',
    String limitKey = 'limit',
    String totalKey = 'total',
  }) {
    final items = _itemsOf(json[dataKey], fromJsonT);
    final seen = (_asInt(json[offsetKey]) ?? 0) + items.length;
    final limit = _asInt(json[limitKey]);
    final total = _asInt(json[totalKey]);
    return Paginated(
      items: items,
      total: total,
      next: _hasMore(items, limit, total, seen: seen) ? seen : null,
    );
  }

  /// `{data, next_cursor}` — [next] is the cursor the server sent.
  ///
  /// A missing, null or empty cursor is the last page. Ask for the first page
  /// by leaving the cursor out.
  factory Paginated.fromCursorJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT, {
    String dataKey = 'data',
    String cursorKey = 'next_cursor',
    String totalKey = 'total',
  }) {
    final cursor = json[cursorKey];
    return Paginated(
      items: _itemsOf(json[dataKey], fromJsonT),
      total: _asInt(json[totalKey]),
      next: cursor == null || cursor == '' ? null : cursor,
    );
  }

  /// The items on this page.
  final List<T> items;

  /// The key of the page after this one, or null when this is the last.
  final Object? next;

  /// How many items exist across every page, when the backend says.
  final int? total;

  /// Whether a page exists after this one.
  bool get hasMore => next != null;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  /// The same page with every item mapped.
  Paginated<R> map<R>(R Function(T item) toItem) =>
      Paginated<R>(items: items.map(toItem).toList(), next: next, total: total);
}

/// The item list under a page's data key. A null or absent list is an empty
/// page, not a cast failure.
List<T> _itemsOf<T>(Object? raw, T Function(Object? json) fromJsonT) =>
    raw is List ? raw.map(fromJsonT).toList() : <T>[];

/// Whether a page-number or offset API has more after [seen] items: the
/// [total] when the backend sends one, otherwise a full page.
bool _hasMore<T>(List<T> items, int? limit, int? total, {required int seen}) {
  if (items.isEmpty) return false;
  if (total != null) return seen < total;
  return limit == null || items.length >= limit;
}

/// Reads a count sent as a number, a numeric string, or not at all.
int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};
