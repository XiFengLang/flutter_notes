import 'dart:ui';

/// 仿写了FlutterBoost的ObserversHolder类，都是监听者容器
class ObserversHolder {
  final Map<String, Set<dynamic>> _observers = <String, Set<dynamic>>{};

  VoidCallback addObserver<T>(T observer) {
    final Set<T> set = _observers[T.toString()] as Set<T> ?? <T>{};

    set.add(observer);
    _observers[T.toString()] = set;

    return () => set.remove(observer);
  }

  void removeObserver<T>(T observer) =>
      _observers[T.toString()]?.remove(observer);

  void cleanObservers<T>() => _observers[T.toString()]?.clear();

  Set<T> observersOf<T>() => _observers[T.toString()] as Set<T> ?? <T>{};
}