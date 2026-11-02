export function mapMemberRow(row) {
  return {
    user_id: row.user_id,
    access_tier: row.access_tier,
    is_organiser: row.is_organiser,
    joined_at: row.joined_at,
    user: {
      first_name: row.first_name || '',
      last_name: row.last_name || '',
      email: row.email || '',
      photo_url: row.photo_url || '',
    },
  };
}
