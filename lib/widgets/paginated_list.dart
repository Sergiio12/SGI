import 'package:flutter/material.dart';

class PaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int pageSize;
  final int initialPageSize;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final Widget? emptyWidget;
  final Widget? loadingIndicator;
  final String loadMoreLabel;

  const PaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 20,
    this.initialPageSize = 30,
    this.padding,
    this.scrollController,
    this.emptyWidget,
    this.loadingIndicator,
    this.loadMoreLabel = 'Cargar más',
  });

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  late ScrollController _scrollController;
  late int _visibleCount;
  bool _isLoadingMore = false;

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
    if (oldWidget.items != widget.items || oldWidget.items.length != widget.items.length) {
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
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || _visibleCount >= widget.items.length) return;
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _visibleCount =
            (_visibleCount + widget.pageSize).clamp(0, widget.items.length);
        _isLoadingMore = false;
      });
    });
  }

  int get _remaining => widget.items.length - _visibleCount;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    final displayItems = widget.items.take(_visibleCount).toList();
    final hasMore = _remaining > 0;

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: displayItems.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= displayItems.length) {
          return _buildLoadMoreButton();
        }
        return widget.itemBuilder(context, displayItems[index], index);
      },
    );
  }

  Widget _buildLoadMoreButton() {
    final count = _remaining > widget.pageSize ? widget.pageSize : _remaining;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _isLoadingMore
            ? widget.loadingIndicator ??
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
            : GestureDetector(
                onTap: _loadMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '${widget.loadMoreLabel} (+$count)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
