import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/auth/auth.dart';

/// Network image that sends the current session Bearer token (required for
/// private health file endpoints).
class AuthenticatedNetworkImage extends ConsumerWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authProvider).accessToken;
    final headers = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null;

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      headers: headers,
      errorBuilder: errorBuilder,
    );
  }
}
