import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mo_infinite_scroll/mo_infinite_scroll.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../shared/widgets/empty_view.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../domain/models/work_model.dart';
import '../blocs/work_bloc.dart';
import '../blocs/work_event.dart';
import 'work_card.dart';
import 'work_list_skeleton.dart';
import 'work_load_more_error.dart';

/// The works matching [query], a page at a time, loading the next as the
/// user nears the end, with pull-to-refresh.
///
/// Give it `key: ValueKey(query)`: a new search is then a new list — a fresh
/// controller starting from page 1 — rather than new results appended to the
/// old ones. Pages come from [WorkBloc] through [WorkPageRequested].
class WorkList extends StatefulWidget {
  const WorkList({super.key, required this.query});

  final String query;

  @override
  State<WorkList> createState() => _WorkListState();
}

class _WorkListState extends State<WorkList> {
  static const _pageSize = 20;

  /// Owned here so the error views' retry buttons can reach it.
  final _controller = MoInfiniteScrollController<WorkModel>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<WorkModel>> _fetchPage(int page, int limit) {
    final request = WorkPageRequested(
      query: widget.query,
      page: page,
      limit: limit,
    );
    context.read<WorkBloc>().add(request);
    return request.result;
  }

  @override
  Widget build(BuildContext context) {
    final searching = widget.query.isNotEmpty;
    return MoInfiniteScroll<WorkModel>(
      controller: _controller,
      fetcher: _fetchPage,
      limit: _pageSize,
      padding: AppConstants.paddingPage,
      separatorBuilder: (_, _) => const SizedBox(height: AppConstants.space8),
      itemBuilder: (context, work) => WorkCard(work: work),
      loadingPlaceholder: const Skeletonizer(child: WorkListSkeleton()),
      emptyPlaceholder: searching
          ? EmptyView(
              title: 'Nenhuma obra encontrada',
              message: 'Nenhuma obra corresponde a "${widget.query}".',
              icon: Icons.search_off,
            )
          : const EmptyView(
              title: 'Ainda não há obras',
              message: 'As obras que criar aparecem aqui.',
              icon: Icons.construction_outlined,
            ),
      errorPlaceholder: ErrorView(
        message: 'Não foi possível carregar as obras.',
        onRetry: _controller.retry,
      ),
      errorMoreIndicator: WorkLoadMoreError(onRetry: _controller.retry),
    );
  }
}
