import 'package:flutter/material.dart';

class PaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final int initialPageSize;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final Widget? emptyWidget;
  final Widget Function(BuildContext)? loadingIndicator;

  const PaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 30,
    this.initialPageSize = 40,
    this.padding,
    this.scrollController,
    this.emptyWidget,
    this.loadingIndicator,
  });

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  late ScrollController _scrollController;
  late int _visibleCount;
  bool _isLoadingMore = false;

  static const double _scrollThreshold = 400;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _visibleCount = widget.initialPageSize.clamp(0, widget.items.length);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _visibleCount = widget.initialPageSize.clamp(0, widget.items.length);
      _isLoadingMore = false;
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    if (_visibleCount >= widget.items.length) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _scrollThreshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || _visibleCount >= widget.items.length) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _visibleCount =
            (_visibleCount + widget.pageSize).clamp(0, widget.items.length);
        _isLoadingMore = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    if (count == 0) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    final displayCount = _visibleCount.clamp(0, count);
    final hasMore = displayCount < count;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: displayCount + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= displayCount) {
          return _buildLoadingIndicator();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: widget.loadingIndicator?.call(context) ??
          Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
    );
  }
}
