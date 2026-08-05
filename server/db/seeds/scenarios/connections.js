import { DEMO_IDS } from '../demo-constants.js';

function canonicalOrgPair(orgA, orgB) {
  return orgA < orgB ? [orgA, orgB] : [orgB, orgA];
}

export async function seedConnections(client) {
  const [lowId, highId] = canonicalOrgPair(
    DEMO_IDS.happyPawsOrg,
    DEMO_IDS.rescueHeartsOrg,
  );

  await client.query(
    `INSERT INTO org_connections (id, org_low_id, org_high_id, status)
     VALUES ($1, $2, $3, 'active')
     ON CONFLICT (org_low_id, org_high_id) DO UPDATE SET
       status = 'active',
       revoked_at = NULL`,
    [DEMO_IDS.orgConnection, lowId, highId],
  );

  console.log('seed: connections scenario ready (Happy Paws ↔ Rescue Hearts)');
}
