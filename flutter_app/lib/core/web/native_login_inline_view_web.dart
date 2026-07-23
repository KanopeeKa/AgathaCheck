import 'package:flutter/material.dart';

import 'native_login_web.dart';

/// Embeds the real HTML login `<form>` from `web/index.html` in the widget
/// tree so password-manager extensions can detect fields on page load.
class NativeLoginInlineView extends StatefulWidget {
  const NativeLoginInlineView({super.key});

  @override
  State<NativeLoginInlineView> createState() => _NativeLoginInlineViewState();
}

class _NativeLoginInlineViewState extends State<NativeLoginInlineView> {
  @override
  void initState() {
    super.initState();
    ensureNativeLoginInlineViewRegistered();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 268,
      child: HtmlElementView(viewType: nativeLoginInlineViewType),
    );
  }
}
