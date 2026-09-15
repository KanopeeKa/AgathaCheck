import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/planned_absence.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/providers/care_context_providers.dart';
import 'package:pet_profile_app/features/pet_care/context/presentation/screens/planned_absence_hub_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../../../helpers/fakes.dart';
PlannedAbsence _a({required String id,required String s,required String e})=>PlannedAbsence(id:id,userId:'u',startsOn:s,endsOn:e,provenance:'user_declared',status:'active',petIds:const['p']);
Future<void> _pump(WidgetTester t,List<PlannedAbsence> abs)async{final r=GoRouter(initialLocation:'/pc/away',routes:[GoRoute(path:'/pc/away',builder:(c,s)=>const PlannedAbsenceHubScreen())]);await t.pumpWidget(ProviderScope(overrides:[plannedAbsencesListProvider.overrideWith((ref)async=>abs),petListProvider.overrideWith(()=>TestPetListNotifier(const[Pet(id:'p',name:'Buddy',species:'dog')]))],child:MaterialApp.router(routerConfig:r,localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales)));await t.pumpAndSettle();}
void main(){testWidgets('empty',(t)async{await _pump(t,[]);final l=AppLocalizations.of(t.element(find.byType(PlannedAbsenceHubScreen)))!;expect(find.text(l.careContextAwayEntryTitle),findsOneWidget);});testWidgets('sections',(t)async{final now=DateTime.now();String w(DateTime d)=>'${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';await _pump(t,[_a(id:'up',s:w(now.add(const Duration(days:5))),e:w(now.add(const Duration(days:10)))),_a(id:'past',s:w(now.subtract(const Duration(days:20))),e:w(now.subtract(const Duration(days:15))))]);final l=AppLocalizations.of(t.element(find.byType(PlannedAbsenceHubScreen)))!;expect(find.text(l.upcomingEvents),findsOneWidget);expect(find.text(l.pastIterations),findsOneWidget);});}
