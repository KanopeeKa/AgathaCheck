import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/data/models/away_plan_readiness_model.dart';
void main(){test('parses',(){final r=AwayPlanReadinessModel.fromJson({'tile_copy':{'source':'c','copy_key':'awayPlanningTileCarerNone'}});expect(r.tileCopy.copyKey,'awayPlanningTileCarerNone');});}
