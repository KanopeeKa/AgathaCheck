import 'package:flutter/material.dart';

/// Top chrome for the main content column when leading navigation is visible.
class ExperienceContentChromeBar extends StatelessWidget {
  const ExperienceContentChromeBar({
    super.key,
    required this.toolbarHeight,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.leading,
    required this.leadingWidth,
    required this.title,
    required this.centerTitle,
    required this.actions,
  });

  final double toolbarHeight;
  final Color backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;
  final double leadingWidth;
  final Widget title;
  final bool centerTitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('experience_content_chrome'),
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: IconTheme.merge(
          data: IconThemeData(color: foregroundColor),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor),
            child: SizedBox(
              height: toolbarHeight,
              child: Row(
                children: [
                  if (leading != null)
                    SizedBox(
                      width: leadingWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: leading,
                      ),
                    ),
                  Expanded(
                    child: centerTitle
                        ? Center(child: title)
                        : Align(alignment: Alignment.centerLeft, child: title),
                  ),
                  ...actions.map(
                    (action) => IconTheme.merge(
                      data: IconThemeData(
                        color: foregroundColor ?? theme.colorScheme.onSurface,
                      ),
                      child: action,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
