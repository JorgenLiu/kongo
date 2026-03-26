import 'dart:async';

class InputDebouncer {
  final Duration delay;
  Timer? _timer;

  InputDebouncer({this.delay = const Duration(milliseconds: 280)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}