import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef HorizontalCarouselBuilder = Widget Function(ScrollController controller);

/// Horizontal scroll region with subtle chevrons on fine-pointer devices.
class HorizontalCarouselControls extends StatefulWidget {
  const HorizontalCarouselControls({
    super.key,
    required this.height,
    required this.builder,
    this.scrollStep,
  });

  final double height;
  final HorizontalCarouselBuilder builder;
  final double? scrollStep;

  @override
  State<HorizontalCarouselControls> createState() =>
      _HorizontalCarouselControlsState();
}

class _HorizontalCarouselControlsState extends State<HorizontalCarouselControls> {
  final ScrollController _controller = ScrollController();
  bool _canScrollBack = false;
  bool _canScrollForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncArrows());
  }

  @override
  void dispose() {
    _controller.removeListener(_syncArrows);
    _controller.dispose();
    super.dispose();
  }

  void _syncArrows() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final back = position.pixels > position.minScrollExtent + 1;
    final forward = position.pixels < position.maxScrollExtent - 1;
    if (back != _canScrollBack || forward != _canScrollForward) {
      setState(() {
        _canScrollBack = back;
        _canScrollForward = forward;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  bool get _showArrows {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.scrollStep ?? widget.height * 0.85;
    final scrollable = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: widget.builder(_controller),
    );

    if (!_showArrows) {
      return SizedBox(height: widget.height, child: scrollable);
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: scrollable),
          if (_canScrollBack)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _CarouselArrow(
                key: const Key('pet_rail_scroll_back'),
                icon: Icons.chevron_left,
                onPressed: () => _scrollBy(-step),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
          if (_canScrollForward)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _CarouselArrow(
                key: const Key('pet_rail_scroll_forward'),
                icon: Icons.chevron_right,
                onPressed: () => _scrollBy(step),
                tooltip: MaterialLocalizations.of(context).continueButtonLabel,
              ),
            ),
        ],
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        elevation: 0,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: Icon(icon, size: 22),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
