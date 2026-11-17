import 'package:flutter/widgets.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

mixin RouteAwareMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  bool _isRouteObserverSubscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && !_isRouteObserverSubscribed) {
      routeObserver.subscribe(this, route);
      _isRouteObserverSubscribed = true;
    }
  }

  @override
  void didPop() {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      onScreenVisible();
    }
  }

  @override
  void didPush() {
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      onScreenVisible();
    }
  }

  @override
  void didPopNext() {
    onScreenVisible();
  }

  @override
  void didPushNext() {
    // Optional: called when a new route is pushed on top
  }

  @override
  void dispose() {
    if (_isRouteObserverSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  void onScreenVisible() {
    // Override in subclass to reload data
  }
}
