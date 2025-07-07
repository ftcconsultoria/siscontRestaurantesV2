import 'package:flutter/material.dart';

class ProgressDialog extends StatefulWidget {
  final ValueListenable<String> message;
  final ValueListenable<double> progress;
  const ProgressDialog({
    super.key,
    required this.message,
    required this.progress,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  late final Stopwatch _watch;

  @override
  void initState() {
    super.initState();
    _watch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _watch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        height: 100,
        child: ValueListenableBuilder<double>(
          valueListenable: widget.progress,
          builder: (context, value, _) {
            final elapsed = _watch.elapsed.inSeconds;
            final remaining = value > 0 ? ((elapsed / value) - elapsed).round() : 0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(value: value),
                const SizedBox(height: 16),
                Text('${(value * 100).toStringAsFixed(0)}% - ~${remaining}s restantes'),
                const SizedBox(height: 8),
                ValueListenableBuilder<String>(
                  valueListenable: widget.message,
                  builder: (context, msg, __) => Text(msg),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
