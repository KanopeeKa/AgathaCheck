import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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
        final container = web.document.createElement('div') as web.HTMLDivElement;
        container.style.width = '100%';
        container.style.height = '100%';
        container.style.display = 'flex';
        container.style.alignItems = 'center';
        container.style.justifyContent = 'center';

        final imgElement = web.document.createElement('img') as web.HTMLImageElement;
        imgElement.src = 'assets/${widget.assetPath}';
        imgElement.style.width = '100%';
        imgElement.style.height = '100%';
        imgElement.style.setProperty('object-fit', fitValue);
        imgElement.style.display = 'block';

        if (widget.clipOval) {
          imgElement.style.borderRadius = '50%';
        }

        imgElement.addEventListener('error', ((web.Event event) {
          imgElement.style.display = 'none';
        }).toJS);

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
