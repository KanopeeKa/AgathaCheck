import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

int _viewCounter = 0;

class WebAssetImage extends StatefulWidget {
  final String assetPath;
  final double height;
  final double width;
  final BoxFit fit;
  final Widget? fallback;
  final bool clipOval;

  const WebAssetImage({
    super.key,
    required this.assetPath,
    required this.height,
    required this.width,
    this.fit = BoxFit.contain,
    this.fallback,
    this.clipOval = false,
  });

  @override
  State<WebAssetImage> createState() => _WebAssetImageState();
}

class _WebAssetImageState extends State<WebAssetImage> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewCounter++;
    _viewType = 'web-asset-image-$_viewCounter';

    final fitValue = switch (widget.fit) {
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      _ => 'contain',
    };

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final container = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center';

        final imgElement = html.ImageElement()
          ..src = 'assets/${widget.assetPath}'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = fitValue
          ..style.display = 'block';

        if (widget.clipOval) {
          imgElement.style.borderRadius = '50%';
        }

        imgElement.onError.listen((_) {
          imgElement.style.display = 'none';
        });

        container.append(imgElement);
        return container;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
