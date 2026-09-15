import 'dart:ui';import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/away_plan_readiness.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/away_planning_tile_copy.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
void main(){late AppLocalizations l;setUpAll(()async{l=await AppLocalizations.delegate.load(const Locale('en'));});test('none',(){expect(AwayPlanningTileCopy.resolve(l,const AwayPlanTileCopy(source:'c',copyKey:'awayPlanningTileCarerNone')),l.awayPlanningTileCarerNone);});}
