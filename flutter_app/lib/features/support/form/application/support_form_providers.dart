import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../data/support_tickets_api.dart';

final supportTicketsApiProvider = Provider<SupportTicketsApi>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return SupportTicketsApi(baseUrl: baseUrl);
});
