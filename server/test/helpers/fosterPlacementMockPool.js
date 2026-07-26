import jwt from 'jsonwebtoken';
import {
  PLACEMENT_STATUS_ADOPTED,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_CANCELLED,
  SESSION_STATUS_CONVERTED_TO_ADOPTION,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_PENDING_ACCEPTANCE,
} from '../../lib/fosterPlacements.js';

export const adminId = 'admin-user-id';
export const fosterId = 'foster-user-id';
export const orgId = 'org-1';
export const petId = 'pet-1';
export const placementId = 'placement-1';
export const journeyId = 'journey-1';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
export const adminToken = jwt.sign({ id: adminId, email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
export const fosterToken = jwt.sign({ id: fosterId, email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });

function makePlacementRow(status, adoptionConditions = '') {
  return {
    id: placementId,
    organization_id: orgId,
    pet_id: petId,
    foster_user_id: fosterId,
    org_foster_parent_id: null,
    status,
    start_date: null,
    end_date: null,
    notes: '',
    adoption_conditions: adoptionConditions,
    created_by: adminId,
    created_at: new Date('2024-01-01'),
    updated_at: new Date('2024-01-01'),
    responded_at: null,
    pet_name: 'Buddy',
    pet_species: 'dog',
    organization_name: 'Test Org',
    foster_name: 'Jane Foster',
    foster_email: 'foster@example.com',
  };
}

export function buildFosterPlacementMockPool() {
  let placementStatus = null;
  let placementAdoptionConditions = '';
  let journeyStatus = null;
  let journeyConditions = '';
  let fosterAccessGranted = false;
  let adoptedOwnerId = null;

  const rowForStatus = (status) => makePlacementRow(status, placementAdoptionConditions);

  const handleQuery = async (sql, params) => {
    if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
      return { rows: [] };
    }
    if (sql.includes('SELECT role') && sql.includes('organization_users')) {
      const uid = params[1];
      if (uid === adminId) return { rows: [{ role: 'admin' }] };
      if (uid === fosterId) return { rows: [{ role: 'foster' }] };
      return { rows: [] };
    }
    if (sql.includes('FROM organization_permissions')) {
      return { rows: [] };
    }
    if (sql.includes('FROM adoption_journeys') && sql.includes('fostering_session_id = $1')) {
      if (!journeyStatus) return { rows: [] };
      return {
        rows: [{
          id: journeyId,
          organization_id: orgId,
          fostering_session_id: placementId,
          pet_id: petId,
          foster_user_id: fosterId,
          status: journeyStatus,
          adoption_conditions: journeyConditions,
          started_at: new Date('2024-03-01'),
          finalised_at: null,
          cancelled_at: null,
          created_by: adminId,
          created_at: new Date('2024-03-01'),
          updated_at: new Date('2024-03-01'),
        }],
      };
    }
    if (sql.includes('INSERT INTO adoption_journeys')) {
      journeyStatus = params[5];
      journeyConditions = params[6] || '';
      placementStatus = SESSION_STATUS_ADOPTION_IN_PROGRESS;
      placementAdoptionConditions = journeyConditions;
      return {
        rows: [{
          id: journeyId,
          organization_id: orgId,
          fostering_session_id: placementId,
          pet_id: petId,
          foster_user_id: fosterId,
          status: journeyStatus,
          adoption_conditions: journeyConditions,
          started_at: new Date(),
          created_by: adminId,
          created_at: new Date(),
          updated_at: new Date(),
        }],
      };
    }
    if (sql.includes('UPDATE adoption_journeys') && sql.includes('finalised')) {
      journeyStatus = 'finalised';
      return { rows: [] };
    }
    if (sql.includes('UPDATE adoption_journeys') && sql.includes('cancelled')) {
      journeyStatus = 'cancelled';
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('LEFT JOIN adoption_journeys')) {
      if (
        placementStatus === PLACEMENT_STATUS_WAITING_ADOPTION
        || (placementStatus === SESSION_STATUS_ADOPTION_IN_PROGRESS
          && journeyStatus === 'awaiting_foster_confirmation')
      ) {
        return { rows: [rowForStatus(placementStatus)] };
      }
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('fp.foster_user_id = $1') && sql.includes('fp.status = ANY($2::text[])')) {
      const statuses = params[1] || [];
      if (statuses.includes(placementStatus)) {
        return { rows: [rowForStatus(placementStatus)] };
      }
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('fp.foster_user_id = $1') && sql.includes('fp.status = $2')) {
      if (params[1] === placementStatus) {
        return { rows: [rowForStatus(placementStatus)] };
      }
      return { rows: [] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1 AND organization_id')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1 FOR UPDATE')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT * FROM foster_placements WHERE id = $1')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('JOIN pets p ON p.id = fp.pet_id')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT fp.*') && sql.includes('WHERE fp.pet_id = $1')) {
      if (!placementStatus
        || placementStatus === PLACEMENT_STATUS_NOT_IN_FOSTER
        || placementStatus === PLACEMENT_STATUS_ADOPTED
        || placementStatus === SESSION_STATUS_CANCELLED
        || placementStatus === SESSION_STATUS_CONVERTED_TO_ADOPTION) {
        return { rows: [] };
      }
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('SELECT id, name FROM pets WHERE id = $1 AND organization_id')) {
      return { rows: [{ id: petId, name: 'Buddy' }] };
    }
    if (sql.includes('SELECT id, name, species, user_id, organization_id FROM pets WHERE id = $1')) {
      return { rows: [{ id: petId, name: 'Buddy', species: 'dog', user_id: adminId, organization_id: orgId }] };
    }
    if (sql.includes('SELECT id FROM pets WHERE id = $1 AND organization_id = $2')) {
      return { rows: [{ id: petId }] };
    }
    if (sql.includes('SELECT name FROM pets WHERE id = $1')) {
      return { rows: [{ name: 'Buddy' }] };
    }
    if (sql.includes('INSERT INTO foster_placements')) {
      placementStatus = params[4] || PLACEMENT_STATUS_PENDING;
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === SESSION_STATUS_END_PENDING_CONFIRMATION) {
      placementStatus = SESSION_STATUS_END_PENDING_CONFIRMATION;
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === SESSION_STATUS_ACTIVE) {
      placementStatus = SESSION_STATUS_ACTIVE;
      fosterAccessGranted = true;
      return { rows: [rowForStatus(SESSION_STATUS_ACTIVE)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_IN_PROGRESS) {
      placementStatus = PLACEMENT_STATUS_IN_PROGRESS;
      fosterAccessGranted = true;
      return { rows: [rowForStatus(PLACEMENT_STATUS_IN_PROGRESS)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === SESSION_STATUS_ADOPTION_IN_PROGRESS) {
      if (sql.includes("adoption_conditions = ''")) {
        placementAdoptionConditions = '';
      } else {
        placementAdoptionConditions = params[1] || '';
      }
      placementStatus = SESSION_STATUS_ADOPTION_IN_PROGRESS;
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === 'cancelled') {
      placementStatus = SESSION_STATUS_CANCELLED;
      fosterAccessGranted = false;
      return { rows: [rowForStatus(SESSION_STATUS_CANCELLED)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_WAITING_ADOPTION) {
      placementStatus = PLACEMENT_STATUS_WAITING_ADOPTION;
      return { rows: [rowForStatus(PLACEMENT_STATUS_WAITING_ADOPTION)] };
    }
    if (sql.includes('UPDATE foster_placements') && params[0] === PLACEMENT_STATUS_PENDING_CONDITIONS) {
      placementStatus = PLACEMENT_STATUS_PENDING_CONDITIONS;
      placementAdoptionConditions = params[1] || '';
      return { rows: [rowForStatus(PLACEMENT_STATUS_PENDING_CONDITIONS)] };
    }
    if (sql.includes('UPDATE foster_placements') && (
      params[0] === PLACEMENT_STATUS_ADOPTED || params[0] === SESSION_STATUS_CONVERTED_TO_ADOPTION
    )) {
      placementStatus = SESSION_STATUS_CONVERTED_TO_ADOPTION;
      adoptedOwnerId = fosterId;
      return { rows: [rowForStatus(SESSION_STATUS_CONVERTED_TO_ADOPTION)] };
    }
    if (sql.includes('UPDATE foster_placements') && (
      params[0] === PLACEMENT_STATUS_NOT_IN_FOSTER || params[0] === SESSION_STATUS_CANCELLED
    )) {
      const ended = rowForStatus(SESSION_STATUS_CANCELLED);
      placementStatus = SESSION_STATUS_CANCELLED;
      fosterAccessGranted = false;
      return { rows: [ended] };
    }
    if (sql.includes('UPDATE pets') && sql.includes('organization_id = NULL')) {
      adoptedOwnerId = params[0];
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO archived_pets')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO pet_access') && sql.includes("'foster'")) {
      fosterAccessGranted = true;
      return { rows: [] };
    }
    if (sql.includes('DELETE FROM pet_access')) {
      fosterAccessGranted = false;
      return { rows: [] };
    }
    if (sql.includes('SELECT first_name, last_name, email FROM users')) {
      return { rows: [{ first_name: 'Test', last_name: 'User', email: 'test@example.com' }] };
    }
    if (sql.includes('INSERT INTO notifications')) {
      return { rows: [] };
    }
    if (sql.includes('INSERT INTO audit_events')) {
      return { rows: [{ id: 'audit-1' }] };
    }
    if (sql.includes('SELECT id FROM org_foster_parents')) {
      return { rows: [] };
    }
    if (sql.includes('FROM foster_placements fp') && sql.includes('WHERE fp.organization_id')) {
      if (!placementStatus || placementStatus === PLACEMENT_STATUS_NOT_IN_FOSTER) {
        return { rows: [] };
      }
      return { rows: [rowForStatus(placementStatus)] };
    }
    if (sql.includes('WHERE fp.id = $1')) {
      if (!placementStatus) return { rows: [] };
      return { rows: [rowForStatus(placementStatus)] };
    }
    return { rows: [] };
  };

  const query = handleQuery;
  const connect = async () => ({
    query: handleQuery,
    release: () => {},
  });

  return {
    query,
    connect,
    get fosterAccessGranted() { return fosterAccessGranted; },
    get adoptedOwnerId() { return adoptedOwnerId; },
    setPlacementPending() { placementStatus = PLACEMENT_STATUS_PENDING; },
    setPlacementPendingAcceptance() { placementStatus = SESSION_STATUS_PENDING_ACCEPTANCE; },
    setPlacementInProgress() {
      placementStatus = PLACEMENT_STATUS_IN_PROGRESS;
      journeyStatus = null;
    },
    setPlacementWaitingAdoption() {
      placementStatus = PLACEMENT_STATUS_WAITING_ADOPTION;
      journeyStatus = 'awaiting_foster_confirmation';
      journeyConditions = '';
      placementAdoptionConditions = '';
    },
  };
}

