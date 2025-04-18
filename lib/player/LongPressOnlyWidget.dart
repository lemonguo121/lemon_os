import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LongPressOnlyWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const LongPressOnlyWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        LongPressGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 300)),
              (instance) {
            instance.onLongPressStart = (_) {
              onLongPressStart?.call();
            };
            instance.onLongPressEnd = (_) {
              onLongPressEnd?.call();
            };
          },
        ),
        TapGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
              (instance) => instance..onTap = onTap,
        ),
        DoubleTapGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
              () => DoubleTapGestureRecognizer(),
              (instance) => instance..onDoubleTap = onDoubleTap,
        ),
        VerticalDragGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
              (instance) {
            instance
              ..onUpdate = onVerticalDragUpdate
              ..onEnd = onVerticalDragEnd;
          },
        ),
        HorizontalDragGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(),
              (instance) {
            instance
              ..onUpdate = onHorizontalDragUpdate
              ..onEnd = onHorizontalDragEnd;
          },
        ),
      },
      child: child,
    );
  }
}