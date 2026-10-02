import 'package:bloc/bloc.dart';

import '../errors/app_exception.dart';
import '../network/paginated.dart';

/// A list that loads in pages, as a notifier's or a bloc's state holds it.
///
/// The first page is loaded like any other screen data — the skeleton, the
/// error screen and the empty state are `AppAsyncView` / `AppStatusView`'s.
/// This tracks what comes after: the key of the next page, whether one
/// exists, and whether loading it is running or has failed. `AppPagedList`
/// draws those last two as the row at the end of the list.
class PagedList<T> {
  const PagedList({
    this.items = const [],
    this.next,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// The list holding [page] as its first page.
  factory PagedList.first(Paginated<T> page) =>
      PagedList(items: page.items, next: page.next, hasMore: page.hasMore);

  /// Every item loaded so far.
  final List<T> items;

  /// The key to ask for the next page with. Only the datasource opens it.
  final Object? next;

  /// Whether a page exists after the last one loaded.
  final bool hasMore;

  /// Whether the next page is loading.
  final bool isLoadingMore;

  /// Why the next page failed to load, or null. Loading again clears it.
  final String? error;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  /// This list, loading its next page.
  PagedList<T> loading() => PagedList(
    items: items,
    next: next,
    hasMore: hasMore,
    isLoadingMore: true,
  );

  /// This list with [page] appended.
  PagedList<T> append(Paginated<T> page) => PagedList(
    items: [...items, ...page.items],
    next: page.next,
    hasMore: page.hasMore,
  );

  /// This list, its next page having failed with [message].
  PagedList<T> failed(String message) =>
      PagedList(items: items, next: next, hasMore: hasMore, error: message);

  /// This list with its items replaced — after an edit or a delete, without
  /// losing the place it has paged to.
  PagedList<T> withItems(List<T> items) => PagedList(
    items: items,
    next: next,
    hasMore: hasMore,
    isLoadingMore: isLoadingMore,
    error: error,
  );
}

/// "Load more" for a [Bloc] whose state holds a [PagedList].
///
/// ```dart
/// class OrdersBloc extends Bloc<OrdersEvent, OrdersState>
///     with
///         ActionBlocMixin<OrdersEvent, OrdersState>,
///         PagedBlocMixin<OrdersEvent, OrdersState, OrderModel> {
///   OrdersBloc(this._repo) : super(const OrdersState()) {
///     on<OrdersStarted>(
///       (event, emit) => runAction(emit, (current) async {
///         final page = await _repo.fetchOrders();
///         return current.copyWith(
///           status: AppStatus.success,
///           orders: PagedList.first(page),
///         );
///       }),
///     );
///     on<OrdersMoreRequested>((event, emit) => loadMore(emit));
///   }
///
///   final OrdersRepository _repo;
///
///   @override
///   Future<Paginated<OrderModel>> fetchPage(Object? next) =>
///       _repo.fetchOrders(next: next);
///
///   @override
///   PagedList<OrderModel> pagedOf(OrdersState state) => state.orders;
///
///   @override
///   OrdersState withPaged(OrdersState state, PagedList<OrderModel> paged) =>
///       state.copyWith(orders: paged);
/// }
/// ```
///
/// The view's `AppPagedList.onLoadMore` adds `OrdersMoreRequested`, and its
/// `onRefresh` adds `OrdersStarted` and returns `bloc.stream.first`.
mixin PagedBlocMixin<E, S, T> on Bloc<E, S> {
  /// Loads the page after the one keyed [next]. Usually the repository call.
  Future<Paginated<T>> fetchPage(Object? next);

  /// The paged list inside [state].
  PagedList<T> pagedOf(S state);

  /// [state] holding [paged] instead.
  S withPaged(S state, PagedList<T> paged);

  /// Appends the next page. Also the retry after a failed one.
  ///
  /// Does nothing while a page is loading or after the last page — so the
  /// list can dispatch it on every scroll without guarding.
  Future<void> loadMore(Emitter<S> emit) async {
    final paged = pagedOf(state);
    if (!paged.hasMore || paged.isLoadingMore) return;

    final loading = paged.loading();
    emit(withPaged(state, loading));

    PagedList<T> settled;
    try {
      settled = loading.append(await fetchPage(paged.next));
    } on AppException catch (e) {
      settled = loading.failed(e.message);
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      settled = loading.failed('Erro desconhecido');
    }

    // Refreshed or closed while the page loaded: it belongs to a list that
    // is gone.
    if (emit.isDone || !identical(pagedOf(state), loading)) return;
    emit(withPaged(state, settled));
  }
}
