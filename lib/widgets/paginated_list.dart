import 'package:flutter/material.dart';

class PaginatedList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController controller;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final EdgeInsetsGeometry? padding;
  final Widget? loadingIndicator;
  final Widget? emptyWidget;

  const PaginatedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.controller,
    required this.hasMore,
    required this.onLoadMore,
    this.padding,
    this.loadingIndicator,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0 && emptyWidget != null) {
      return emptyWidget!;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            hasMore &&
            controller.position.pixels >=
                controller.position.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        padding: padding,
        itemCount: itemCount + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= itemCount) {
            return loadingIndicator ??
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
          }
          return itemBuilder(context, index);
        },
      ),
    );
  }
}
