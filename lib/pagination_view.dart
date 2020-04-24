import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/pagination_bloc.dart';
import 'widgets/bottom_loader.dart';
import 'widgets/empty_separator.dart';
import 'widgets/initial_loader.dart';

typedef PaginationBuilder<T> = Future<List<T>> Function(int currentListSize);

class PaginationView<T> extends StatefulWidget {
  const PaginationView({
    Key key,
    @required this.itemBuilder,
    @required this.pageFetch,
    @required this.onEmpty,
    @required this.onError,
    this.separator = const EmptySeparator(),
    this.preloadedItems = const [],
    this.initialLoader = const InitialLoader(),
    this.bottomLoader = const BottomLoader(),
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsets.all(0),
    this.physics,
  }) : super(key: key);

  final Widget bottomLoader;
  final Widget initialLoader;
  final Widget onEmpty;
  final EdgeInsets padding;
  final PaginationBuilder<T> pageFetch;
  final ScrollPhysics physics;
  final List<T> preloadedItems;
  final bool reverse;
  final Axis scrollDirection;
  final Widget separator;
  final bool shrinkWrap;

  @override
  _PaginationViewState<T> createState() => _PaginationViewState<T>();

  final Widget Function(BuildContext, T) itemBuilder;

  final Widget Function(dynamic) onError;
}

class _PaginationViewState<T> extends State<PaginationView<T>> {
  PaginationBloc<T> _bloc;
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginationBloc<T>, PaginationState<T>>(
      bloc: _bloc,
      builder: (context, state) {
        if (state is PaginationInitial<T>) {
          return widget.initialLoader;
        } else if (state is PaginationError<T>) {
          return widget.onError(state.error);
        } else {
          final loadedState = state as PaginationLoaded<T>;
          if (loadedState.items.isEmpty) {
            return widget.onEmpty;
          }
          return _buildListView(loadedState);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bloc = PaginationBloc<T>(widget.preloadedItems)
      ..add(PageFetch(callback: widget.pageFetch));
  }

  Widget _buildListView(PaginationLoaded<T> loadedState) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.separated(
        controller: _scrollController,
        reverse: widget.reverse,
        shrinkWrap: widget.shrinkWrap,
        scrollDirection: widget.scrollDirection,
        physics: widget.physics,
        padding: widget.padding,
        separatorBuilder: (context, index) => widget.separator,
        itemCount: loadedState.hasReachedEnd
            ? loadedState.items.length
            : loadedState.items.length + 1,
        itemBuilder: (context, index) => index >= loadedState.items.length
            ? widget.bottomLoader
            : widget.itemBuilder(context, loadedState.items[index]),
      ),
    );
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final _scrollThreshold = 200;
    if (maxScroll - currentScroll <= _scrollThreshold) {}
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        _scrollController.position.extentAfter == 0) {
      _bloc.add(PageFetch(callback: widget.pageFetch));
    }

    return false;
  }
}
