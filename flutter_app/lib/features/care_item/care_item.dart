/// Care items: open occurrences, the Done rule and the completion service
/// (care-next-occurrence-c1a7 §7.3, §18.8). Other features import only this
/// file (enforced in child F).
library;

export 'application/care_command_outcome.dart';
export 'application/care_completion_service.dart'
    show
        CareCommandPath,
        CareCommandSource,
        CareCompletionRequest,
        CareCompletionService;
export 'application/care_item_providers.dart';
export 'application/care_items_controller.dart';
export 'data/care_item_wire.dart' show careItemScheduleFromJson;
export 'domain/care_agenda.dart';
export 'domain/care_item_schedule.dart';
export 'domain/care_occurrence.dart';
export 'domain/completion_requirements.dart';
export 'domain/done_decision.dart';
export 'domain/leading_occurrence.dart';
export 'domain/occurrence_detail.dart';
export 'domain/occurrence_status.dart';
export 'domain/stack_rule.dart';
export 'presentation/care_completion_flow.dart';
export 'presentation/detail/care_item_detail_screen.dart';
export 'presentation/occurrence/occurrence_screen.dart';
