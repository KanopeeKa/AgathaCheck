import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// A comprehensive Help & FAQ screen providing user-friendly documentation
/// of every feature in Agatha Track.
///
/// The screen is organised into collapsible sections, one per feature area.
/// Each section contains multiple question-and-answer pairs that explain
/// how the feature works and how to use it.
///
/// Sections covered:
/// - Account & Authentication
/// - Pet Profiles
/// - Health Tracking
/// - Weight Tracking
/// - Veterinarian Management
/// - Pet Sharing
/// - Organisations
/// - Family Events
/// - Notifications
/// - Reports
/// - Subscription
/// - Language & Accessibility
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.helpTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Text(
              l.helpSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _FaqSection(
            icon: Icons.person_outlined,
            title: l.faqAccountTitle,
            items: [
              _FaqItem(q: l.faqAccountQ1, a: l.faqAccountA1),
              _FaqItem(q: l.faqAccountQ2, a: l.faqAccountA2),
              _FaqItem(q: l.faqAccountQ3, a: l.faqAccountA3),
              _FaqItem(q: l.faqAccountQ4, a: l.faqAccountA4),
              _FaqItem(q: l.faqAccountQ5, a: l.faqAccountA5),
            ],
          ),
          _FaqSection(
            icon: Icons.pets,
            title: l.faqPetProfileTitle,
            items: [
              _FaqItem(q: l.faqPetProfileQ1, a: l.faqPetProfileA1),
              _FaqItem(q: l.faqPetProfileQ2, a: l.faqPetProfileA2),
              _FaqItem(q: l.faqPetProfileQ3, a: l.faqPetProfileA3),
              _FaqItem(q: l.faqPetProfileQ4, a: l.faqPetProfileA4),
              _FaqItem(q: l.faqPetProfileQ5, a: l.faqPetProfileA5),
              _FaqItem(q: l.faqPetProfileQ6, a: l.faqPetProfileA6),
            ],
          ),
          _FaqSection(
            icon: Icons.medical_services_outlined,
            title: l.faqHealthTitle,
            items: [
              _FaqItem(q: l.faqHealthQ1, a: l.faqHealthA1),
              _FaqItem(q: l.faqHealthQ2, a: l.faqHealthA2),
              _FaqItem(q: l.faqHealthQ3, a: l.faqHealthA3),
              _FaqItem(q: l.faqHealthQ4, a: l.faqHealthA4),
              _FaqItem(q: l.faqHealthQ5, a: l.faqHealthA5),
              _FaqItem(q: l.faqHealthQ6, a: l.faqHealthA6),
            ],
          ),
          _FaqSection(
            icon: Icons.monitor_weight_outlined,
            title: l.faqWeightTitle,
            items: [
              _FaqItem(q: l.faqWeightQ1, a: l.faqWeightA1),
              _FaqItem(q: l.faqWeightQ2, a: l.faqWeightA2),
              _FaqItem(q: l.faqWeightQ3, a: l.faqWeightA3),
            ],
          ),
          _FaqSection(
            icon: Icons.local_hospital_outlined,
            title: l.faqVetTitle,
            items: [
              _FaqItem(q: l.faqVetQ1, a: l.faqVetA1),
              _FaqItem(q: l.faqVetQ2, a: l.faqVetA2),
              _FaqItem(q: l.faqVetQ3, a: l.faqVetA3),
            ],
          ),
          _FaqSection(
            icon: Icons.share_outlined,
            title: l.faqSharingTitle,
            items: [
              _FaqItem(q: l.faqSharingQ1, a: l.faqSharingA1),
              _FaqItem(q: l.faqSharingQ2, a: l.faqSharingA2),
              _FaqItem(q: l.faqSharingQ3, a: l.faqSharingA3),
              _FaqItem(q: l.faqSharingQ4, a: l.faqSharingA4),
            ],
          ),
          _FaqSection(
            icon: Icons.business_outlined,
            title: l.faqOrgTitle,
            items: [
              _FaqItem(q: l.faqOrgQ1, a: l.faqOrgA1),
              _FaqItem(q: l.faqOrgQ2, a: l.faqOrgA2),
              _FaqItem(q: l.faqOrgQ3, a: l.faqOrgA3),
              _FaqItem(q: l.faqOrgQ4, a: l.faqOrgA4),
              _FaqItem(q: l.faqOrgQ5, a: l.faqOrgA5),
            ],
          ),
          _FaqSection(
            icon: Icons.family_restroom_outlined,
            title: l.faqFamilyEventsTitle,
            items: [
              _FaqItem(q: l.faqFamilyEventsQ1, a: l.faqFamilyEventsA1),
              _FaqItem(q: l.faqFamilyEventsQ2, a: l.faqFamilyEventsA2),
              _FaqItem(q: l.faqFamilyEventsQ3, a: l.faqFamilyEventsA3),
            ],
          ),
          _FaqSection(
            icon: Icons.notifications_outlined,
            title: l.faqNotificationsTitle,
            items: [
              _FaqItem(q: l.faqNotificationsQ1, a: l.faqNotificationsA1),
              _FaqItem(q: l.faqNotificationsQ2, a: l.faqNotificationsA2),
              _FaqItem(q: l.faqNotificationsQ3, a: l.faqNotificationsA3),
              _FaqItem(q: l.faqNotificationsQ4, a: l.faqNotificationsA4),
            ],
          ),
          _FaqSection(
            icon: Icons.picture_as_pdf_outlined,
            title: l.faqReportsTitle,
            items: [
              _FaqItem(q: l.faqReportsQ1, a: l.faqReportsA1),
              _FaqItem(q: l.faqReportsQ2, a: l.faqReportsA2),
            ],
          ),
          _FaqSection(
            icon: Icons.star_outlined,
            title: l.faqSubscriptionTitle,
            items: [
              _FaqItem(q: l.faqSubscriptionQ1, a: l.faqSubscriptionA1),
              _FaqItem(q: l.faqSubscriptionQ2, a: l.faqSubscriptionA2),
              _FaqItem(q: l.faqSubscriptionQ3, a: l.faqSubscriptionA3),
            ],
          ),
          _FaqSection(
            icon: Icons.language_outlined,
            title: l.faqLanguageTitle,
            items: [
              _FaqItem(q: l.faqLanguageQ1, a: l.faqLanguageA1),
              _FaqItem(q: l.faqLanguageQ2, a: l.faqLanguageA2),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

/// A collapsible section that groups related FAQ items under a feature heading.
///
/// Displays an [icon] and [title] in the header. When expanded, shows each
/// FAQ question-answer pair as a nested [ExpansionTile].
class _FaqSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_FaqItem> items;

  const _FaqSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        children: items.map((item) {
          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              item.q,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            childrenPadding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            expandedAlignment: Alignment.topLeft,
            children: [
              Text(
                item.a,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
