import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared animation state for all OnyxSkeleton instances.
///
/// Instead of each skeleton creating its own AnimationController or using a blocking Timer,
/// all skeletons share a single Ticker-driven AnimationController.
/// This dramatically reduces resource usage when multiple skeletons
/// are visible simultaneously and keeps the animation tied to the device's vsync.
class _SkeletonAnimationManager implements TickerProvider {
  static final _SkeletonAnimationManager _instance =
      _SkeletonAnimationManager._();
  factory _SkeletonAnimationManager() => _instance;

  AnimationController? _controller;
  late Animation<double> animation;
  int _listenerCount = 0;

  _SkeletonAnimationManager._() {
    _initController();
  }

  void _initController() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Simulate the old timer curve: oscillating between alpha 0.05 and 0.12
    animation = Tween<double>(begin: 0.05, end: 0.12).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOutSine),
    );
  }

  void addListener() {
    _listenerCount++;
    if (_listenerCount == 1) {
      if (_controller == null) _initController();
      _controller!.repeat(reverse: true);
    }
  }

  void removeListener() {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _listenerCount = 0;
      _controller?.stop();
    }
  }

  // TickerProviderStateMixin requirement
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

class OnyxSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const OnyxSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  State<OnyxSkeleton> createState() => _OnyxSkeletonState();
}

class _OnyxSkeletonState extends State<OnyxSkeleton> {
  final _manager = _SkeletonAnimationManager();

  @override
  void initState() {
    super.initState();
    _manager.addListener();
  }

  @override
  void dispose() {
    _manager.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _manager.animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _manager.animation.value),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          );
        },
      ),
    );
  }
}
