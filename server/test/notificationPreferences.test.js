import {
  apiDtoToPreferenceUpdates,
  defaultSettingsMatrix,
  isAgathaSuggestionsInAppEnabled,
  preferenceMapToApiDto,
  PREF_AGATHA_IN_APP,
  PREF_SETTINGS_MATRIX,
  MATRIX_CATEGORY_SUGGESTIONS,
} from '../lib/notificationPreferences.js';

describe('notificationPreferences matrix', () => {
  it('returns defaults when no rows are stored', () => {
    const dto = preferenceMapToApiDto({});
    expect(dto.agatha_suggestions_in_app).toBe(true);
    expect(dto.settings_matrix.invites_requests.inbox).toBe('always');
    expect(dto.settings_matrix.invites_requests.push).toBe(true);
    expect(dto.settings_matrix.access_membership.email).toBe(false);
    expect(dto.settings_matrix.agatha_suggestions.push_mode).toBe('weekly_digest');
    expect(dto.settings_matrix.account_security.locked).toBe(true);
    expect(dto.suggestion_types.suggestionCareFamily).toBe(true);
  });

  it('maps stored rows into API dto with bool coercion', () => {
    const dto = preferenceMapToApiDto({
      email_reminders_enabled: 'true',
      notify_overdue: 'false',
      muted_pet_ids: '["pet-a"]',
      [PREF_AGATHA_IN_APP]: 'false',
    });
    expect(dto.email_reminders_enabled).toBe(true);
    expect(dto.notify_overdue).toBe(false);
    expect(dto.muted_pet_ids).toEqual(['pet-a']);
    expect(dto.agatha_suggestions_in_app).toBe(false);
    expect(dto.settings_matrix[MATRIX_CATEGORY_SUGGESTIONS].inbox).toBe(false);
  });

  it('persists matrix and agatha flag on patch', () => {
    const { updates, agathaTurnedOff } = apiDtoToPreferenceUpdates({
      agatha_suggestions_in_app: false,
      settings_matrix: defaultSettingsMatrix(),
    });
    expect(updates[PREF_AGATHA_IN_APP]).toBe('false');
    expect(updates[PREF_SETTINGS_MATRIX]).toBeDefined();
    expect(agathaTurnedOff).toBe(true);
  });

  it('detects disabled suggestion generation', () => {
    expect(
      isAgathaSuggestionsInAppEnabled({ agatha_suggestions_in_app: false }),
    ).toBe(false);
    expect(
      isAgathaSuggestionsInAppEnabled({
        agatha_suggestions_in_app: true,
        settings_matrix: {
          [MATRIX_CATEGORY_SUGGESTIONS]: { inbox: false },
        },
      }),
    ).toBe(false);
  });
});
